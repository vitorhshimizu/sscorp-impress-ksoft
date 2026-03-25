/*
*/

{method/dbotterr.i} /* RowErrors */
{inbo/boin176.i4 tt-item-devol-cli}

DEF VAR h-boin090   AS HANDLE NO-UNDO .
DEF VAR h-boin176   AS HANDLE NO-UNDO .

RUN inbo/boin090.p PERSISTENT SET h-boin090 .
RUN openQueryStatic IN h-boin090(INPUT "Main") .
RUN goToKey IN h-boin090("1", "7000001", 5545, "220101") .

FIND FIRST it-nota-fisc NO-LOCK
    WHERE it-nota-fisc.cod-estabel  = "101" 
    AND   it-nota-fisc.serie        = "3"
    AND   it-nota-fisc.nr-nota-fis  = "0074165"    
    AND   it-nota-fisc.it-codigo    = "6948115-029"
    .

EMPTY TEMP-TABLE tt-item-devol-cli .
CREATE tt-item-devol-cli . ASSIGN
    tt-item-devol-cli.rw-it-nota-fisc = ROWID(it-nota-fisc)
    tt-item-devol-cli.quant-devol     = 2500
    tt-item-devol-cli.preco-devol     = it-nota-fisc.vl-merc-liq * (tt-item-devol-cli.quant-devol / it-nota-fisc.qt-faturada[1])
    tt-item-devol-cli.cod-depos       = it-nota-fisc.cod-depos
    tt-item-devol-cli.reabre-pd       = NO
    tt-item-devol-cli.vl-desconto     = 0
    tt-item-devol-cli.nat-of          = "220101"
    .

RUN inbo/boin176.p PERSISTENT SET h-boin176 .
RUN openQueryStatic IN h-boin176(INPUT "Main") .

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
IF CAN-FIND(FIRST RowErrors) THEN DO:
    DEF VAR hShowMsg    AS HANDLE NO-UNDO .
    RUN utp/showMessage.w PERSISTENT SET hShowMsg .
    RUN setModal IN hShowMsg(INPUT YES) .
    RUN showMessages IN hShowMsg(INPUT TABLE RowErrors) .
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
