/*
*/
USING PROGRESS.Lang.ERROR.
USING com.totvs.framework.api.JsonApiResponseBuilder .

{utp/ut-api.i}
{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-action.i "pi-put" "PUT" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}
{utils/fnFormatDate.i}

PROCEDURE pi-find-fornecedor-id:
    DEF INPUT PARAM p-id    AS CHAR NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    IF p-id = "" THEN DO:
        oOut = fnApiErro("id n∆o foi informado.") .
        RETURN "NOK".
    END.

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = INT(p-id)
        AND   ( emitente.identific = 2 /* Fornecedor */ OR 
                emitente.identific = 3 /* Ambos */ )
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Fornecedor n∆o foi encontrado.") .
        RETURN "NOK".
    END.

    RETURN "OK" .
END PROCEDURE .

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .
   
    RUN pi-find-fornecedor-id(INPUT fnApiReadParam(oIn, "id"), OUTPUT oOut) .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    DEF VAR deBalance       AS DECIMAL NO-UNDO .
    DEF VAR oInvoice        AS JsonObject NO-UNDO .
    DEF VAR oInvoiceList    AS JsonArray NO-UNDO .
    DEF VAR deTurnover      AS DECIMAL NO-UNDO .
    DEF VAR dtTurnoverIni   AS DATE NO-UNDO .
    DEF VAR dtTurnoverFim   AS DATE NO-UNDO .

    IF fnApiReadParam(oIn, "balance") = "TRUE" THEN DO:
        ASSIGN deBalance = 0 .
        ASSIGN oInvoiceList = NEW JsonArray() .
        FOR EACH estabelecimento NO-LOCK ,
            EACH tit_ap NO-LOCK
            WHERE tit_ap.cod_estab = estabelecimento.cod_estab
            AND   tit_ap.cdn_fornecedor = emitente.cod-emitente
            AND   tit_ap.log_sdo_tit_ap = YES
            BY tit_ap.dat_vencto_tit_ap
            :
            oInvoice = NEW JsonObject() .
            oInvoice:ADD("cod_estab"            , tit_ap.cod_estab) .
            oInvoice:ADD("num_id_tit_ap"        , tit_ap.num_id_tit_ap) .
            oInvoice:ADD("cod_espec_docto"      , tit_ap.cod_espec_docto) .
            oInvoice:ADD("cod_ser_docto"        , tit_ap.cod_ser_docto) .
            oInvoice:ADD("cod_tit_ap"           , tit_ap.cod_tit_ap) .
            oInvoice:ADD("cod_parcela"          , tit_ap.cod_parcela) .
            oInvoice:ADD("dat_emis_docto"       , tit_ap.dat_emis_docto) .
            oInvoice:ADD("dat_vencto_tit_ap"    , tit_ap.dat_vencto_tit_ap) .
            oInvoice:ADD("val_origin_tit_ap"    , tit_ap.val_origin_tit_ap) .
            oInvoice:ADD("val_sdo_tit_ap"       , tit_ap.val_sdo_tit_ap) .
            oInvoice:ADD("cod_portador"         , tit_ap.cod_portador) .
            oInvoice:ADD("cod_indic_econ"       , tit_ap.cod_indic_econ) .
            oInvoiceList:ADD(oInvoice) .
    
            IF tit_ap.dat_vencto_tit_ap < TODAY THEN DO:
                FOR EACH val_tit_ap NO-LOCK
                    WHERE val_tit_ap.cod_estab = tit_ap.cod_estab
                    AND   val_tit_ap.num_id_tit_ap = tit_ap.num_id_tit_ap
                    AND   val_tit_ap.cod_finalid_econ = "Corrente"
                    :
                    ASSIGN deBalance = deBalance + val_tit_ap.val_sdo_tit_ap .
                END.
            END.
        END.
    END.

    IF fnApiReadParam(oIn, "turnover") = "TRUE" THEN DO:
        ASSIGN deTurnover = 0 .
        ASSIGN dtTurnoverIni = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "turnoverStartDate")) .
        ASSIGN dtTurnoverFim = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "turnoverEndDate")) .

        /* Nao tem indice apropriado na docum-est */
        FOR EACH docum-est NO-LOCK
            WHERE docum-est.cod-emitente = emitente.cod-emitente
            AND   docum-est.dt-trans >= dtTurnoverIni
            AND   docum-est.dt-trans <= dtTurnoverFim
            AND   docum-est.ce-atual = YES
            :
            ASSIGN deTurnover = deTurnover + docum-est.tot-valor .
        END.
    END.

    oOut = fnApiOK() .
    oOut:ADD("codigo"           , emitente.cod-emitente) .
    oOut:ADD("cnpj"             , emitente.cgc) .
    oOut:ADD("razao_social"     , emitente.nome-emit) .
    oOut:ADD("nome_abrev"       , emitente.nome-abrev) .
    oOut:ADD("cod_gr_forn"      , emitente.cod-gr-forn) .
    oOut:ADD("tp_desp_padrao"   , emitente.tp-desp-padrao) .
    oOut:ADD("cod_cond_pag"     , emitente.cod-cond-pag) .
    oOut:ADD("telefone"         , emitente.telefone[1]) .
    oOut:ADD("email"            , emitente.e-mail) .
    oOut:ADD("end_pais"         , emitente.pais) .
    oOut:ADD("end_uf"           , emitente.estado) .
    oOut:ADD("end_cidade"       , emitente.cidade) .
    oOut:ADD("end_bairro"       , emitente.bairro) .
    oOut:ADD("end_lograd"       , emitente.endereco) .
    oOut:ADD("end_cep"          , emitente.cep) .
    oOut:ADD("ins_estadual"     , emitente.ins-estadual) .
    oOut:ADD("ins_municipal"    , emitente.ins-municipal) .
    oOut:ADD("opta_simples"     , IF SUBSTRING(emitente.char-1,133,1) = "S" THEN TRUE ELSE FALSE ) .
    oOut:ADD("cod_portador_ap"  , emitente.portador-ap) .
    oOut:ADD("modalidade_ap"    , emitente.modalidade-ap) .
    oOut:ADD("debt_balance"     , deBalance) .
    oOut:ADD("invoiceList"      , oInvoiceList) .
    oOut:ADD("turnover"         , deTurnover) .
END.

PROCEDURE pi-post :
    DEF INPUT  PARAM oIn  AS JsonObject NO-UNDO.
    DEF OUTPUT PARAM oOut AS JsonObject NO-UNDO.
    
    DEF VAR h-api AS HANDLE NO-UNDO.
    RUN ksoft/csapiksoft001.p PERSISTENT SET h-api .
    
    RUN pi-cust-supl IN h-api(oIn, 2 /*fornecedor*/, OUTPUT oOut) . 
    
    CATCH oE AS ERROR:
        oOut = fnApiErro(oE:GetMessage(1)) . 
    END CATCH.
    FINALLY:
        DELETE PROCEDURE h-api .
    END.
END.
