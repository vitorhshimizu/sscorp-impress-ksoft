/*
*/

USING PROGRESS.Lang.ERROR.
USING com.totvs.framework.api.JsonApiResponseBuilder .

{utp/ut-api.i}
{utp/ut-api-action.i "pi-get-balancelist" "GET" "/balancelist~*" }

{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}
{utils/fnFormatDate.i}

{cstp/csftapi001tt.i} /* tt-sale-item */ 

DEF TEMP-TABLE tt-balance NO-UNDO
    FIELD cod-emitente  LIKE emitente.cod-emitente
    FIELD tit-balance   AS DECIMAL
    INDEX idx_key AS UNIQUE PRIMARY cod-emitente
    .

PROCEDURE pi-find-cliente-id:
    DEF INPUT PARAM p-id    AS CHAR NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    IF p-id = "" THEN DO:
        oOut = fnApiErro("id n∆o foi informado.") .
        RETURN "NOK".
    END.

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = INT(p-id)
        AND   ( emitente.identific = 1 /* Cliente */ OR 
                emitente.identific = 3 /* Ambos */ )
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Cliente n∆o foi encontrado.") .
        RETURN "NOK".
    END.

    RETURN "OK" .
END PROCEDURE .

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .
   
    RUN pi-find-cliente-id(INPUT fnApiReadParam(oIn, "id"), OUTPUT oOut) .
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
            EACH tit_acr NO-LOCK
            WHERE tit_acr.cod_estab = estabelecimento.cod_estab
            AND   tit_acr.cdn_cliente = emitente.cod-emitente
            AND   tit_acr.log_sdo_tit_acr = YES
            BY tit_acr.dat_vencto_tit_acr
            :
            oInvoice = NEW JsonObject() .
            oInvoice:ADD("cod_estab"            , tit_acr.cod_estab) .
            oInvoice:ADD("num_id_tit_acr"       , tit_acr.num_id_tit_acr) .
            oInvoice:ADD("cod_espec_docto"      , tit_acr.cod_espec_docto) .
            oInvoice:ADD("cod_ser_docto"        , tit_acr.cod_ser_docto) .
            oInvoice:ADD("cod_tit_acr"          , tit_acr.cod_tit_acr) .
            oInvoice:ADD("cod_parcela"          , tit_acr.cod_parcela) .
            oInvoice:ADD("dat_emis_docto"       , tit_acr.dat_emis_docto) .
            oInvoice:ADD("dat_vencto_tit_acr"   , tit_acr.dat_vencto_tit_acr) .
            oInvoice:ADD("val_origin_tit_acr"   , tit_acr.val_origin_tit_acr) .
            oInvoice:ADD("val_liq_tit_acr"      , tit_acr.val_liq_tit_acr) .
            oInvoice:ADD("val_sdo_tit_acr"      , tit_acr.val_sdo_tit_acr) .
            oInvoice:ADD("cod_portador"         , tit_acr.cod_portador) .
            oInvoice:ADD("cod_cart_bcia"        , tit_acr.cod_cart_bcia) .
            oInvoice:ADD("cod_indic_econ"       , tit_acr.cod_indic_econ) .
            oInvoiceList:ADD(oInvoice) .
    
            IF tit_acr.dat_vencto_tit_acr < TODAY THEN DO:
                FOR EACH val_tit_acr NO-LOCK
                    WHERE val_tit_acr.cod_estab = tit_acr.cod_estab
                    AND   val_tit_acr.num_id_tit_acr = tit_acr.num_id_tit_acr
                    AND   val_tit_acr.cod_finalid_econ = "Corrente"
                    :
                    ASSIGN deBalance = deBalance + val_tit_acr.val_sdo_tit_acr .
                END.
            END.
        END.
    END.

    IF fnApiReadParam(oIn, "turnover") = "TRUE" THEN DO:
        ASSIGN deTurnover = 0 .
        ASSIGN dtTurnoverIni = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "turnoverStartDate")) .
        ASSIGN dtTurnoverFim = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "turnoverEndDate")) .

        DEF VAR h-csftapi001    AS HANDLE NO-UNDO .
        RUN cstp/csftapi001.p PERSISTENT SET h-csftapi001 .
    
        RUN pi-get-sales IN h-csftapi001
            (INPUT ? ,                          //h-acomp 
             INPUT dtTurnoverIni ,              //p-dt-ini              
             INPUT dtTurnoverFim ,              //p-dt-fim
             INPUT "" ,                         //p-cod-estabel-ini
             INPUT "ZZZZZ" ,                    //p-cod-estabel-fim
             INPUT "" ,                         //p-serie-ini
             INPUT "ZZZZZ" ,                    //p-serie-fim
             INPUT "" ,                         //p-nr-nota-fis-ini
             INPUT "ZZZZZZZZZZZZZZZZ",          //p-nr-nota-fis-fim
             INPUT emitente.nome-abrev ,        //p-nome-abrev-ini
             INPUT emitente.nome-abrev ,        //p-nome-abrev-fim
             INPUT "",                          //p-nr-pedcli-ini
             INPUT "ZZZZZZZZZZZZ",              //p-nr-pedcli-fim
             INPUT 0 ,                          //p-nr-seq-ped-ini
             INPUT 99999 ,                      //p-nr-seq-ped-fim
             INPUT "" ,                         //p-it-codigo-ini
             INPUT "ZZZZZZZZZZZZZZZZ",          //p-it-codigo-fim
             INPUT "" ,                         //p-cod-refer-ini
             INPUT "ZZZZZZZZ" ,                 //p-cod-refer-fim
             INPUT 0 ,                          //p-nr-entrega-ini
             INPUT 99999 ,                      //p-nr-entrega-fim
             INPUT 0 ,                          //p-ge-codigo-ini
             INPUT 99 ,                         //p-ge-codigo-fim
             INPUT "" ,                         //p-fm-codigo-ini
             INPUT "ZZZZZZZZ" ,                 //p-fm-codigo-fim
             INPUT "*" ,                        //p-list-un
             INPUT 60 ,                         //p-rateio-dp 
             INPUT 40 ,                         //p-rateio-ip
             INPUT "*" ,                        //p-list-esp-nota
             OUTPUT TABLE tt-sale-item )
            .
    
        IF VALID-HANDLE(h-csftapi001) THEN DO:
            DELETE PROCEDURE h-csftapi001 .
            ASSIGN h-csftapi001 = ? .
        END.

        FOR EACH tt-sale-item NO-LOCK
            :
            ASSIGN deTurnover = deTurnover + tt-sale-item.vl-tot-item .
        END.
    END.

    oOut = fnApiOK() .
    oOut:ADD("codigo"           , emitente.cod-emitente) .
    oOut:ADD("cnpj"             , emitente.cgc) .
    oOut:ADD("razao_social"     , emitente.nome-emit) .
    oOut:ADD("nome_abrev"       , emitente.nome-abrev) .
    oOut:ADD("cod_gr_cli"       , emitente.cod-gr-cli) .
    oOut:ADD("cod_rep"          , emitente.cod-rep) .
    oOut:ADD("cod_transp"       , emitente.cod-transp) .
    oOut:ADD("nr_tabpre"        , emitente.nr-tabpre) .
    oOut:ADD("cod_cond_pag"     , emitente.cod-cond-pag) .
    oOut:ADD("cod_canal_venda"  , emitente.cod-canal-venda) .
    oOut:ADD("nat_operacao_int" , emitente.nat-operacao) .
    oOut:ADD("nat_operacao_ext" , emitente.nat-ope-ext) .
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
    oOut:ADD("cod_portador"     , emitente.portador) .
    oOut:ADD("modalidade"       , emitente.modalidade) .
    oOut:ADD("debt_balance"     , deBalance) .
    oOut:ADD("invoiceList"      , oInvoiceList) .
    oOut:ADD("turnover"         , deTurnover) .
    oOut:ADD("lim_credito"      , emitente.lim-credito) .
END.

PROCEDURE pi-get-balancelist:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR oCliente        AS JsonObject NO-UNDO .
    DEF VAR oClienteArray   AS JsonArray NO-UNDO .

    EMPTY TEMP-TABLE tt-balance .

    FOR EACH estabelecimento NO-LOCK ,
        EACH tit_acr NO-LOCK
        WHERE tit_acr.cod_estab = estabelecimento.cod_estab
        AND   tit_acr.log_sdo_tit_acr = YES
        AND   tit_acr.dat_vencto_tit_acr < TODAY 
        :
        FIND FIRST tt-balance WHERE tt-balance.cod-emitente = tit_acr.cdn_cliente NO-ERROR .
        IF NOT AVAIL tt-balance THEN DO:
            CREATE tt-balance . ASSIGN tt-balance.cod-emitente = tit_acr.cdn_cliente .
        END.
        FOR EACH val_tit_acr NO-LOCK
            WHERE val_tit_acr.cod_estab = tit_acr.cod_estab
            AND   val_tit_acr.num_id_tit_acr = tit_acr.num_id_tit_acr
            AND   val_tit_acr.cod_finalid_econ = "Corrente"
            :
            ASSIGN tt-balance.tit-balance = tt-balance.tit-balance + val_tit_acr.val_sdo_tit_acr .
        END.
    END.

    oClienteArray = NEW JsonArray() .
    FOR EACH tt-balance NO-LOCK
        :
        oCliente = NEW JsonObject() .
        oCliente:ADD("codigo"           , tt-balance.cod-emitente) .
        oCliente:ADD("debt_balance"     , tt-balance.tit-balance) .
        oClienteArray:ADD(oCliente) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("list", oClienteArray) .
END.

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn  AS JsonObject NO-UNDO.
    DEF OUTPUT PARAM oOut AS JsonObject NO-UNDO.
    
    DEF VAR h-api AS HANDLE NO-UNDO.
    RUN ksoft/csapiksoft001.p PERSISTENT SET h-api .
    
    RUN pi-cust-supl IN h-api(oIn, 1 /*Cliente*/, OUTPUT oOut) .
    
    CATCH oE AS ERROR:
        oOut = fnApiErro(oE:GetMessage(1)) . 
    END CATCH.
    FINALLY:
        DELETE PROCEDURE h-api .
    END.
END.


