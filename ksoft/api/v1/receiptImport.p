/*
*/

{utp/ut-api.i}

{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

{method/dbotterr.i} /* RowErrors */

DEF TEMP-TABLE RowErrors-aux NO-UNDO LIKE RowErrors .

DEF TEMP-TABLE tt-docum-est NO-UNDO LIKE docum-est
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-item-doc-est NO-UNDO LIKE item-doc-est
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-dupli-apagar NO-UNDO LIKE dupli-apagar
    FIELD r-rowid   AS ROWID
    .

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR l-ok                    AS LOGICAL NO-UNDO .
    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = fnApiGetInt(oHeader, "cod_cli_for")
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Cliente/Fornecedor n∆o encontrado") .
        RETURN .
    END.

    DEF VAR h-boin090   AS HANDLE NO-UNDO .
    RUN inbo/boin090.p PERSISTENT SET h-boin090 .
    RUN openQueryStatic IN h-boin090(INPUT "Main") .

    EMPTY TEMP-TABLE tt-docum-est .
    EMPTY TEMP-TABLE tt-item-doc-est .
    EMPTY TEMP-TABLE tt-dupli-apagar .

    oOut = fnApiErro("Erro interno, transaá∆o n∆o finalizada") .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        CREATE tt-docum-est . ASSIGN
            tt-docum-est.cod-chave-aces-nf-eletro = fnApiGetChar(oHeader, "cod_chave_nfe")
            tt-docum-est.serie-docto    = fnApiGetChar(oHeader, "serie")
            tt-docum-est.nro-docto      = "0000001"
            tt-docum-est.cod-emitente   = emitente.cod-emitente
            tt-docum-est.nat-operacao   = fnApiGetChar(oHeader, "nat_operacao")
            tt-docum-est.cod-estabel    = fnApiGetChar(oHeader, "cod_estabel")
            tt-docum-est.esp-docto      = 21 /* NFE */
            tt-docum-est.tipo-docto     = 1 /* Entrada */
            tt-docum-est.cod-observa    = fnApiGetInt(oHeader, "cod_observa")
            tt-docum-est.dt-emissao     = fnApiGetDate(oHeader, "dt_emissao")
            tt-docum-est.dt-trans       = fnApiGetDate(oHeader, "dt_trans")
            tt-docum-est.observacao     = fnApiGetChar(oHeader, "observacao")
            .
    
        RUN emptyRowErrors IN h-boin090 .
        RUN setRecord IN h-boin090(INPUT TABLE tt-docum-est) .
        RUN createRecord IN h-boin090 .
        RUN getRowErrors IN h-boin090(OUTPUT TABLE RowErrors) .
        FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
        IF AVAIL RowErrors THEN DO:
            oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
            UNDO , LEAVE .
        END.

        /**/
        ASSIGN l-ok = YES .
    END.

    IF VALID-HANDLE(h-boin090) THEN DO:
        RUN destroy IN h-boin090 .
        DELETE PROCEDURE h-boin090 NO-ERROR .
        ASSIGN h-boin090 = ? .
    END.

    IF l-ok = TRUE THEN DO:
        oOut = fnApiOK() .
        oOut:ADD("cod_estabel"      , fnApiGetChar(oHeader, "cod_estabel") ).
        oOut:ADD("cod_cli_for"      , emitente.cod-emitente).
        oOut:ADD("serie"            , fnApiGetChar(oHeader, "serie") ).
        oOut:ADD("nro_docto"        , fnApiGetChar(oHeader, "nro_docto") ).
        oOut:ADD("nat_operacao"     , fnApiGetChar(oHeader, "nat_operacao") ).
   END.
   RETURN .
END PROCEDURE .




