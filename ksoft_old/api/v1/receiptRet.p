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

{inbo/boin176.i4 tt-item-devol-cli}

FUNCTION fnNowToString RETURNS CHAR
    ()
    :
    DEF VAR p-data  AS DATE NO-UNDO INIT TODAY .
    DEF VAR p-mtime AS INT NO-UNDO .

    ASSIGN p-mtime = MTIME(NOW) .

    RETURN 
        STRING(YEAR(p-data) , "9999") + 
        STRING(MONTH(p-data) , "99") + 
        STRING(DAY(p-data) , "99") +
        "_" +
        REPLACE(STRING(INT(p-mtime / 1000), "HH:MM:SS"), ":", "") + 
        "_" +
        STRING(p-mtime MOD 1000, "999")
        .
END FUNCTION .

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR l-ok                    AS LOGICAL NO-UNDO .
    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .

    DEF VAR cDocto  AS CHAR NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .

    oIn:WriteFile("C:\totvs\ksoft_log\POST_receiptRet\" + fnNowToString() + ".json", YES, "UTF-8") .

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

    DEF VAR h-boin176   AS HANDLE NO-UNDO .
    RUN inbo/boin176.p PERSISTENT SET h-boin176 .
    RUN openQueryStatic IN h-boin176(INPUT "Main") .

    EMPTY TEMP-TABLE tt-docum-est .
    EMPTY TEMP-TABLE tt-item-doc-est .
    EMPTY TEMP-TABLE tt-dupli-apagar .

    oOut = fnApiErro("Erro interno, transaá∆o n∆o finalizada") .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        ASSIGN cDocto = fnApiGetChar(oHeader, "nro_docto") .
        IF LENGTH(cDocto) < 7 THEN DO:
            ASSIGN cDocto = FILL("0", 7 - LENGTH(cDocto)) + cDocto .
        END.

        CREATE tt-docum-est . ASSIGN
            tt-docum-est.cod-chave-aces-nf-eletro = fnApiGetChar(oHeader, "cod_chave_nfe")
            tt-docum-est.serie-docto    = fnApiGetChar(oHeader, "serie")
            tt-docum-est.nro-docto      = fnApiGetChar(oHeader, "nro_docto")
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
        //FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
        FIND FIRST RowErrors NO-LOCK NO-ERROR .
        IF AVAIL RowErrors THEN DO:
            oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
            UNDO , LEAVE .
        END.

        MESSAGE "LOG receiptRet - TAKE001A" VIEW-AS ALERT-BOX .

        FIND FIRST docum-est NO-LOCK
            WHERE docum-est.serie-docto     = tt-docum-est.serie-docto
            AND   docum-est.nro-docto       = cDocto   
            AND   docum-est.cod-emitente    = tt-docum-est.cod-emitente
            AND   docum-est.nat-operacao    = tt-docum-est.nat-operacao
            .

        RUN emptyRowErrors IN h-boin090 .
        RUN goToKey IN h-boin090
            (docum-est.serie-docto, 
             docum-est.nro-docto,
             docum-est.cod-emitente,
             docum-est.nat-operacao) 
            .

        MESSAGE "LOG receiptRet - TAKE001B" VIEW-AS ALERT-BOX .

        DO iCont = 1 TO oItensArray:LENGTH
            :
            ASSIGN oItem = oItensArray:GetJsonObject(iCont) .

            FIND FIRST ITEM NO-LOCK
                WHERE ITEM.it-codigo = fnApiGetChar(oItem, "it_codigo")
                NO-ERROR .
            IF NOT AVAIL ITEM THEN DO:
                oOut = fnApiErro("Item n∆o encontrado, Pos:" + STRING(iCont) ) .
                UNDO TRA1, LEAVE TRA1.
            END.

            FIND FIRST emitente NO-LOCK
                WHERE emitente.cgc = SUBSTR(fnApiGetChar(oItem, "ref_cod_chave_nfe"), 7, 14)
                NO-ERROR .
            IF NOT AVAIL emitente THEN DO:
                oOut = fnApiErro("Chave Ref Emitente n∆o encontrado, Pos:" + STRING(iCont) ) .
                UNDO TRA1, LEAVE TRA1.
            END.

            FIND FIRST estabelec NO-LOCK
                WHERE estabelec.cod-emitente = emitente.cod-emitente
                NO-ERROR .
            IF NOT AVAIL estabelec THEN DO:
                oOut = fnApiErro("Chave Ref Estabelecimento n∆o encontrado, Pos:" + STRING(iCont) ) .
                UNDO TRA1, LEAVE TRA1.
            END.

            MESSAGE "LOG receiptRet - TAKE002" VIEW-AS ALERT-BOX .

            FIND FIRST it-nota-fisc NO-LOCK
                WHERE it-nota-fisc.cod-estabel  = estabelec.cod-estabel 
                AND   it-nota-fisc.serie        = SUBSTR(fnApiGetChar(oItem, "ref_cod_chave_nfe"), 23, 3)
                AND   it-nota-fisc.nr-nota-fis  = SUBSTR(fnApiGetChar(oItem, "ref_cod_chave_nfe"), 28, 7) 
                AND   it-nota-fisc.nr-seq-fat   = fnApiGetInt(oItem, "ref_nfe_seq")
                AND   it-nota-fisc.it-codigo    = ITEM.it-codigo
                NO-ERROR .
            IF NOT AVAIL it-nota-fisc THEN DO:
                FIND FIRST it-nota-fisc NO-LOCK
                    WHERE it-nota-fisc.cod-estabel  = estabelec.cod-estabel 
                    AND   it-nota-fisc.serie        = STRING(INT(SUBSTR(fnApiGetChar(oItem, "ref_cod_chave_nfe"), 23, 3)))
                    AND   it-nota-fisc.nr-nota-fis  = SUBSTR(fnApiGetChar(oItem, "ref_cod_chave_nfe"), 28, 7) 
                    AND   it-nota-fisc.nr-seq-fat   = fnApiGetInt(oItem, "ref_nfe_seq")
                    AND   it-nota-fisc.it-codigo    = ITEM.it-codigo
                    NO-ERROR .
            END.
            IF NOT AVAIL it-nota-fisc THEN DO:
                oOut = fnApiErro("Chave Ref Documento n∆o encontrado, Pos:" + STRING(iCont) ) .
                UNDO TRA1, LEAVE TRA1.
            END.

            MESSAGE "LOG receiptRet - TAKE003" VIEW-AS ALERT-BOX .

            EMPTY TEMP-TABLE tt-item-devol-cli .
            CREATE tt-item-devol-cli . ASSIGN
                tt-item-devol-cli.rw-it-nota-fisc = ROWID(it-nota-fisc)
                tt-item-devol-cli.quant-devol     = fnApiGetDecimal(oItem, "quantidade")
                tt-item-devol-cli.preco-devol     = it-nota-fisc.vl-merc-liq * (tt-item-devol-cli.quant-devol / it-nota-fisc.qt-faturada[1])
                tt-item-devol-cli.cod-depos       = it-nota-fisc.cod-depos
                tt-item-devol-cli.reabre-pd       = NO
                tt-item-devol-cli.vl-desconto     = 0
                tt-item-devol-cli.nat-of          = docum-est.nat-operacao
                .
            RUN emptyRowErrors IN h-boin176 .
            RUN createItemOfNotaFiscal IN h-boin176
                (INPUT h-boin090,
                 INPUT TABLE tt-item-devol-cli)
                .
            RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors) .
            FOR EACH RowErrors
                WHERE RowErrors.ErrorNumber = 3 OR RowErrors.ErrorNumber = 8
                :
                DELETE RowErrors .
            END.

            MESSAGE "LOG receiptRet - TAKE004" VIEW-AS ALERT-BOX .

            FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
            IF AVAIL RowErrors THEN DO:
                oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                UNDO , LEAVE .
            END.
        END.

        /**/
        ASSIGN l-ok = YES .
    END.

    IF VALID-HANDLE(h-boin176) THEN DO:
        RUN destroy IN h-boin176 .
        DELETE PROCEDURE h-boin176 NO-ERROR .
        ASSIGN h-boin176 = ? .
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



