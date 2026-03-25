FIND FIRST it-nota-fisc NO-LOCK
    WHERE it-nota-fisc.cod-estabel = "101"
    AND   it-nota-fisc.serie = "3"
    AND   it-nota-fisc.nr-nota-fis = "0074313"
    .

FIND FIRST nar-it-nota
    WHERE nar-it-nota.cod-estabel = it-nota-fisc.cod-estabel 
    AND   nar-it-nota.serie = it-nota-fisc.serie 
    AND   nar-it-nota.nr-nota-fis = it-nota-fisc.nr-nota-fis
    AND   nar-it-nota.nr-sequencia = it-nota-fisc.nr-seq-fat
    .

ASSIGN nar-it-nota.narrativa = "AABB" .


/*
DEF VAR iCont   AS INT NO-UNDO .

DO iCont = 1 TO LENGTH(nar-it-nota.narrativa)
    :
    MESSAGE
        iCont SKIP
        SUBSTRING(nar-it-nota.narrativa, iCont, 1) SKIP
        ASC(SUBSTRING(nar-it-nota.narrativa, iCont, 1)) SKIP
        VIEW-AS ALERT-BOX .
END.
*/

