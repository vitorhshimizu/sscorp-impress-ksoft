{cdp/cdapi366b.i}
{include/boerrtab.i}

DEF VAR i-ep-codigo-empresa AS INT                  NO-UNDO.
DEF VAR c-arquivo-saida     AS CHAR                 NO-UNDO.
DEF VAR h-api               AS HANDLE               NO-UNDO.
    
run cdp/cdapi366b.p persistent set h-api.
    

CREATE tt_emitente_integr_new.
ASSIGN tt_emitente_integr_new.Cod_versao_integracao = 1 
       tt_emitente_integr_new.Cod_emitente = 6
       tt_emitente_integr_new.Identific = 1 /*1 = cliente, 2 = fornecedor*/
       tt_emitente_integr_new.Nome_abrev = "CONDOR TESTE" //fnApiGetChar(oPayload, "nome_abrev")
       tt_emitente_integr_new.Nome_matriz = "CONDOR TESTE" //fnApiGetChar(oPayload, "nome_abrev")
       tt_emitente_integr_new.Natureza = 2
       tt_emitente_integr_new.e_mail = "nfe@condor.com.br" //fnApiGetChar(oPayload, "email") 
       tt_emitente_integr_new.Cgc = "62370549000125" //fnApiGetChar(oPayload, "cnpj")
       tt_emitente_integr_new.Cod_portador = 102 //fnApiGetInt(oPayload, "cod_portador")
       tt_emitente_integr_new.Modalidade = 6 //fnApiGetInt(oPayload, "modalidade")
      // tt_emitente_integr_new.Conta_corren = ""
      // tt_emitente_integr_new.Agencia = ""
      // tt_emitente_integr_new.Cod_banco = ""
       tt_emitente_integr_new.Data_implant = TODAY
       tt_emitente_integr_new.Cod_gr_cli = 10 //fnApiGetInt(oPayload, "cod_gr_cli")
      // tt_emitente_integr_new.Cod_gr_forn 
       tt_emitente_integr_new.Ins_estadual = "1015165711" //fnApiGetChar(oPayload, "ins_estadual")
       tt_emitente_integr_new.Ins_municipal = "" //fnApiGetChar(oPayload, "ins_municipal")
       tt_emitente_integr_new.Cod_pais = "BRASIL" //fnApiGetChar(oPayload, "end_pais")
       tt_emitente_integr_new.Estado = "PR" //fnApiGetChar(oPayload, "end_uf")
       tt_emitente_integr_new.cidade = "CURITIBA" //fnApiGetChar(oPayload, "end_cidade")
       tt_emitente_integr_new.nom_cidade = "CURITIBA" //fnApiGetChar(oPayload, "end_cidade")
       tt_emitente_integr_new.Bairro = "CAPAO RASO" //fnApiGetChar(oPayload, "end_bairro")
       tt_emitente_integr_new.Cep = "81150050" //fnApiGetChar(oPayload, "end_cep")
       tt_emitente_integr_new.Endereco = "AV. WINSTON CHURCHILL 2170" //fnApiGetChar(oPayload, "end_lograd")
       tt_emitente_integr_new.Ven_sabado  = 1 /*Prorroga*/
       tt_emitente_integr_new.Ven_Domingo = 1 /*Prorroga*/
       tt_emitente_integr_new.Ven_feriado = 1 /*Prorroga*/
       tt_emitente_integr_new.Cod_rep = 1 //fnApiGetInt(oPayload, "cod_rep")
       tt_emitente_integr_new.Ep_codigo_principal = "1" //string(i-ep-codigo-usuario
       tt_emitente_integr_new.Num_tip_operac = 1 /*1 =Inclus∆o/ 2 = Modificaá∆o*/
       tt_emitente_integr_new.Tp_desp_padrao = 1
       tt_emitente_integr_new.Tp_rec_padrao = 998
       tt_emitente_integr_new.telefone[1]  = "4132122000" //fnApiGetChar(oPayload, "telefone")
       tt_emitente_integr_new.ep_codigo = "1"
      
. 

                                    
ASSIGN i-ep-codigo-empresa = 1
       c-arquivo-saida = "".
    
/*Tratamento de Dados*/
ASSIGN tt_emitente_integr_new.Cep = REPLACE(tt_emitente_integr_new.Cep , "-" , "") .
CREATE tt_cont_emit_integr_new .
CREATE tt_cta_emitente .
EMPTY TEMP-TABLE tt_retorno_clien_fornec .


run execute_evoluida_8 in h-api (input        table tt_emitente_integr_new,
                                 input        table tt_cont_emit_integr_new,
                                 input-output table tt_retorno_clien_fornec,
                                 input        i-ep-codigo-empresa,             
                                 input-output c-arquivo-saida,                 
                                 input        table tt_cta_emitente).
                                 
FIND FIRST tt_retorno_clien_fornec NO-LOCK NO-ERROR.
IF AVAIL tt_retorno_clien_fornec THEN DO:
    MESSAGE "Mensagem: " tt_retorno_clien_fornec.ttv_des_mensagem SKIP
            "Ajuda: " tt_retorno_clien_fornec.ttv_des_ajuda SKIP
            "Param: " tt_retorno_clien_fornec.ttv_cod_parameters SKIP
            "Numero: " tt_retorno_clien_fornec.ttv_num_mensagem
        VIEW-AS ALERT-BOX INFO BUTTONS OK.
    
END.
