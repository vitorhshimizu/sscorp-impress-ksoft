/*
*/

DEF VAR deTotDesp   AS DECIMAL NO-UNDO .

FIND FIRST docum-est NO-LOCK
    WHERE docum-est.cod-emitente = 685
    AND   docum-est.serie-docto = "3"
    AND   docum-est.nro-docto = "0000121"
    .

FOR EACH item-doc-est-cex NO-LOCK OF docum-est
    BREAK
    BY item-doc-est-cex.cod-emitente-desp
    :
    IF FIRST-OF(item-doc-est-cex.cod-emitente-desp) THEN DO:
        ASSIGN deTotDesp = 0 .
    END.

    ASSIGN deTotDesp = deTotDesp + item-doc-est-cex.val-desp .

    IF LAST-OF(item-doc-est-cex.cod-emitente-desp) THEN DO:
        MESSAGE deTotDesp VIEW-AS ALERT-BOX .
    END.
END.


            
