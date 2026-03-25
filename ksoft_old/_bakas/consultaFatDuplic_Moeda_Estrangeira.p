/**/

DEF VAR cNrNota AS CHAR NO-UNDO .

ASSIGN cNrNota = "0073951" .

FOR EACH fat-duplic NO-LOCK
    WHERE fat-duplic.cod-estabel = "101"
    AND   fat-duplic.serie = "3"
    AND   fat-duplic.nr-fatura = cNrNota
    :
    MESSAGE
        fat-duplic.vl-parcela       SKIP
        fat-duplic.vl-comis         SKIP
        fat-duplic.dec-1            SKIP
        fat-duplic.mo-negoc         SKIP
        fat-duplic.vl-parcela-me    SKIP
        fat-duplic.vl-comis-me      SKIP
        VIEW-AS ALERT-BOX .
END.

FOR EACH it-nota-fisc NO-LOCK
    WHERE it-nota-fisc.cod-estabel = "101"
    AND   it-nota-fisc.serie = "3"
    AND   it-nota-fisc.nr-nota-fis = cNrNota
    :
    MESSAGE
        it-nota-fisc.it-codigo SKIP
        it-nota-fisc.vl-merc-liq-me SKIP
        VIEW-AS ALERT-BOX .
END.


