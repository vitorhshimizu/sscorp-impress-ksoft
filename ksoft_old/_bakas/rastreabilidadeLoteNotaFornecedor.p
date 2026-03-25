/*
*/

FIND saldo-estoq NO-LOCK
    WHERE saldo-estoq.it-codigo = "10.865"
    AND   saldo-estoq.cod-refer = ""
    AND   saldo-estoq.lote = "020254381A1"
    AND   saldo-estoq.qtidade-atu > 0
    .

FIND FIRST movto-estoq USE-INDEX cstidx_it_lote NO-LOCK
    WHERE movto-estoq.it-codigo = saldo-estoq.it-codigo
    AND   movto-estoq.lote = saldo-estoq.lote
    AND   movto-estoq.esp-docto = 21 /* NFE */
    NO-ERROR .
IF AVAIL movto-estoq THEN DO:
    MESSAGE
        movto-estoq.serie-docto SKIP
        movto-estoq.nro-docto SKIP
        movto-estoq.cod-emitente SKIP
        movto-estoq.nat-operacao SKIP
        movto-estoq.sequen-nf SKIP
        VIEW-AS ALERT-BOX .
END.

/*
FOR FIRST movto-estoq USE-INDEX cstidx_it_lote NO-LOCK
    WHERE movto-estoq.it-codigo = saldo-estoq.it-codigo
    AND   movto-estoq.lote = saldo-estoq.lote
    AND   movto-estoq.esp-docto = 21 /* NFE */
    :
    MESSAGE
        movto-estoq.serie-docto SKIP
        movto-estoq.nro-docto SKIP
        movto-estoq.cod-emitente SKIP
        movto-estoq.nat-operacao SKIP
        movto-estoq.sequen-nf SKIP
        VIEW-AS ALERT-BOX .
END.
*/
