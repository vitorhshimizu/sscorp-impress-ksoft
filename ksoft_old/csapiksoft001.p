/*
*/

USING PROGRESS.json.* .
USING PROGRESS.json.ObjectModel.* .
USING com.totvs.framework.api.* .

{utils/fnAPI.i}
{cdp/cdapi366b.i}
{include/boerrtab.i}

{cdp/cdapi300.i1}
{cdp/cdapi244.i}

PROCEDURE pi-cust-supl
    :
    DEF INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEF INPUT  PARAM p-tipo  AS INT        NO-UNDO.
    DEF OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    
    DEF BUFFER pais FOR mgcad.pais .

    DEF VAR oPayload            AS jsonObject           NO-UNDO.
    DEF VAR i-ep-codigo-empresa AS INT                  NO-UNDO.
    DEF VAR c-arquivo-saida     AS CHAR                 NO-UNDO.
    DEF VAR oRequestParser      AS JsonAPIRequestParser NO-UNDO.
    
    DEF VAR h-api               AS HANDLE               NO-UNDO.
    run cdp/cdapi366b.p persistent set h-api.
    
    ASSIGN oRequestParser = NEW JsonAPIRequestParser(oInput) .
    
    oPayload = oRequestParser:getPayload() . //NEW jsonObject() .

    FIND FIRST pais NO-LOCK
        WHERE SUBSTRING(pais.char-1, 23, 2) = fnApiGetChar(oPayload, "end_pais")
        NO-ERROR .
    IF NOT AVAIL pais THEN DO:
        oOutput = fnApiErro("Pais ISO3166-2 n∆o encontrado") .
        RETURN .
    END.
    
    CREATE tt_emitente_integr_new.
    ASSIGN tt_emitente_integr_new.Cod_versao_integracao = 1
           tt_emitente_integr_new.Cod_emitente = fnApiGetInt(oPayload, "codigo")
           tt_emitente_integr_new.Identific = p-tipo /*1 = cliente, 2 = fornecedor*/
           tt_emitente_integr_new.Nome_abrev = fnApiGetChar(oPayload, "nome_abrev")
           tt_emitente_integr_new.Nome_matriz = fnApiGetChar(oPayload, "nome_abrev")
           tt_emitente_integr_new.nome_emit = fnApiGetChar(oPayload, "razao_social")
           tt_emitente_integr_new.Natureza = 2
           tt_emitente_integr_new.e_mail = fnApiGetChar(oPayload, "email") 
           tt_emitente_integr_new.Cgc = fnApiGetChar(oPayload, "cnpj")
           tt_emitente_integr_new.Cod_portador = fnApiGetInt(oPayload, "cod_portador")
           tt_emitente_integr_new.Modalidade = fnApiGetInt(oPayload, "modalidade")
          // tt_emitente_integr_new.Conta_corren = ""
          // tt_emitente_integr_new.Agencia = ""
          // tt_emitente_integr_new.Cod_banco = ""
           tt_emitente_integr_new.Data_implant = TODAY
           tt_emitente_integr_new.Cod_gr_cli = fnApiGetInt(oPayload, "cod_gr_cli")
          // tt_emitente_integr_new.Cod_gr_forn 
           tt_emitente_integr_new.Ins_estadual = fnApiGetChar(oPayload, "ins_estadual")
           tt_emitente_integr_new.Ins_municipal = fnApiGetChar(oPayload, "ins_municipal")
           tt_emitente_integr_new.Cod_pais = pais.nome-pais
           tt_emitente_integr_new.Estado = fnApiGetChar(oPayload, "end_uf")
           tt_emitente_integr_new.cidade      = fnApiGetChar(oPayload, "end_cidade")
           tt_emitente_integr_new.nom_cidade      = fnApiGetChar(oPayload, "end_cidade")
           tt_emitente_integr_new.Bairro = fnApiGetChar(oPayload, "end_bairro")
           tt_emitente_integr_new.Cep = fnApiGetChar(oPayload, "end_cep")
           tt_emitente_integr_new.Endereco = fnApiGetChar(oPayload, "end_lograd")
           tt_emitente_integr_new.Ven_sabado  = 1 /*Prorroga*/
           tt_emitente_integr_new.Ven_Domingo = 1 /*Prorroga*/
           tt_emitente_integr_new.Ven_feriado = 1 /*Prorroga*/
           tt_emitente_integr_new.Cod_rep = fnApiGetInt(oPayload, "cod_rep")
           tt_emitente_integr_new.Ep_codigo_principal = "1" //string(i-ep-codigo-usuario
           tt_emitente_integr_new.Num_tip_operac = 1 /*1 =Inclus∆o */
           tt_emitente_integr_new.Tp_desp_padrao = fnApiGetInt(oPayload, "tp_desp_padrao")
           tt_emitente_integr_new.Tp_rec_padrao = 998
           tt_emitente_integr_new.telefone[1]             = fnApiGetChar(oPayload, "telefone")
           tt_emitente_integr_new.ep_codigo = "1"
          /**/ 
    .
    IF tt_emitente_integr_new.cod_rep = 0 THEN DO:
        ASSIGN tt_emitente_integr_new.cod_rep = 5 /* Default Impress */ .
    END.

    IF p-tipo = 2 /* Fornecedor */ THEN DO:
        ASSIGN 
            tt_emitente_integr_new.Cod_portador = fnApiGetInt(oPayload, "cod_portador_ap")
            tt_emitente_integr_new.Modalidade = fnApiGetInt(oPayload, "modalidade_ap")
            tt_emitente_integr_new.Cod_gr_forn = fnApiGetInt(oPayload, "cod_gr_forn")
            .
    END.
    IF tt_emitente_integr_new.Cod_pais <> "Brasil" THEN DO:
        ASSIGN tt_emitente_integr_new.Natureza = 3 /* Estrangeiro */ .
        ASSIGN tt_emitente_integr_new.Cep = "11111111" .
    END.
    /*
    ASSIGN
        tt_emitente_integr_new.lim-credito = fnApiGetDecimal(oPayload, "codigo")
        .
   */ 
    
    ASSIGN i-ep-codigo-empresa = 1
           c-arquivo-saida = "".
        
    /*Tratamento de Dados*/
    ASSIGN tt_emitente_integr_new.Cep = REPLACE(tt_emitente_integr_new.Cep , "-" , "") .
    CREATE tt_cont_emit_integr_new .
    ASSIGN tt_cont_emit_integr_new.cod_versao_integracao = 1 .
    CREATE tt_cta_emitente .
    EMPTY TEMP-TABLE tt_retorno_clien_fornec .
                
    /* Atualizar fornecedor pelo CNPJ, porem o codigo nao retorna ao KSOFT nao ira funcionar */ 
    /*
    IF tt_emitente_integr_new.Cgc <> "" THEN DO:
        FOR LAST emitente NO-LOCK
            WHERE emitente.cgc = tt_emitente_integr_new.Cgc
            :
            ASSIGN tt_emitente_integr_new.Cod_emitente = emitente.cod-emitente .
        END.
    END.
    */
    FIND FIRST emitente WHERE emitente.cod-emitente = tt_emitente_integr_new.Cod_emitente NO-LOCK NO-ERROR .
    IF AVAIL emitente THEN DO:
        ASSIGN tt_emitente_integr_new.Num_tip_operac = 1 . /*1 = Inclus∆o OU 2 = Eliminacao */ 
        ASSIGN tt_emitente_integr_new.Nome_abrev = emitente.nome-abrev .
        ASSIGN tt_emitente_integr_new.Nome_matriz = tt_emitente_integr_new.Nome_abrev .
    END.
    
    run execute_evoluida_8 in h-api (input        table tt_emitente_integr_new,
                                     input        table tt_cont_emit_integr_new,
                                     input-output table tt_retorno_clien_fornec,
                                     input        i-ep-codigo-empresa,             
                                     input-output c-arquivo-saida,                 
                                     input        table tt_cta_emitente).
    
    
    FIND FIRST tt_retorno_clien_fornec NO-LOCK NO-ERROR.
    IF AVAIL tt_retorno_clien_fornec THEN DO:
        ASSIGN oOutput = NEW jsonObject().
        //oOutput:ADD("_retorno_des_mensagem:",tt_retorno_clien_fornec.ttv_des_mensagem ).
        oOutput:ADD("_retorno",tt_retorno_clien_fornec.ttv_des_ajuda).
        //oOutput:ADD("_retorno_cod_param:",tt_retorno_clien_fornec.ttv_cod_parameters).
        //oOutput:ADD("_retorno_num_mensagem:",tt_retorno_clien_fornec.ttv_num_mensagem).
        
        
    END.
    ELSE DO:
        ASSIGN oOutput = NEW jsonObject().
        oOutput:ADD("_retorno:","OK") .
    END.
END.

PROCEDURE pi-cria-item :
    DEF INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEF OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    
    DEF VAR oPayload            AS jsonObject           NO-UNDO.
    DEF VAR oRequestParser      AS JsonAPIRequestParser NO-UNDO.
    
    DEF VAR h-api               AS HANDLE               NO-UNDO.
    
    ASSIGN oRequestParser = NEW JsonAPIRequestParser(oInput) .
    
    oPayload = oRequestParser:getPayload() .

    CREATE tt-versao-integr. ASSIGN 
        tt-versao-integr.cod-versao-integr = 1
        .

    CREATE tt-item . ASSIGN
        tt-item.ind-tipo-movto          = 1 /* Criacao */
        tt-item.it-codigo               = fnApiGetChar(oPayload, "codigo")
        tt-item.desc-item               = UPPER(fnApiGetChar(oPayload, "desc_item"))        
        tt-item.ge-codigo               = INTEGER(fnApiGetChar(oPayload, "ge_codigo"))              
        tt-item.fm-codigo               = fnApiGetChar(oPayload, "fm_cod_com")
        tt-item.un                      = fnApiGetChar(oPayload, "un")
        tt-item.cod-estabel             = "101"
        tt-item.narrativa               = fnApiGetChar(oPayload, "narrativa") 
        tt-item.cod-obsoleto            = 1 /* Ativo */
        tt-item.class-fiscal            = fnApiGetChar(oPayload, "ncm")
        tt-item.cod-unid-negoc          = fnApiGetChar(oPayload, "cod_unid_negoc")
        tt-item.peso-bruto              = DEC(fnApiGetChar(oPayload, "peso_bruto"))
        tt-item.peso-liquido            = DEC(fnApiGetChar(oPayload, "peso_liquido"))
        tt-item.altura                  = DEC(fnApiGetChar(oPayload, "altura"))
        tt-item.largura                 = DEC(fnApiGetChar(oPayload, "largura"))
        tt-item.comprim                 = DEC(fnApiGetChar(oPayload, "comprim"))
        tt-item.ind-item-fat            = fnApiGetLogical(oPayload, "ind_item_fat")
        tt-item.ind-imp-desc            = 7 /* Narrativa Informada */
        .

    RUN cdp/cdapi344.p (INPUT        TABLE tt-versao-integr ,
                        OUTPUT       TABLE tt-erros-geral , 
                        INPUT-OUTPUT TABLE tt-item).

    IF AVAIL tt-erros-geral THEN DO:
        ASSIGN oOutput = NEW jsonObject().
        oOutput:ADD("_retorno:","tt-erros-geral.desc-erro") .
    END.
    ELSE DO:
        ASSIGN oOutput = NEW jsonObject().
        oOutput:ADD("_retorno:","ITEM criado com sucesso!") .
    END.
END.

