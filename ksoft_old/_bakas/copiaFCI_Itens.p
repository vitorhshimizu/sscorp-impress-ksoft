/*
*/

{utils/fnFormatDate.i}

DEF BUFFER bf-inf-compl FOR inf-compl .

DEF VAR c-chave AS CHAR NO-UNDO .

ASSIGN c-chave = "101" + CHR(2) + "696993-093" .
FIND LAST inf-compl NO-LOCK
    WHERE inf-compl.cdn-identif = 6 /* FCI */
    AND   inf-compl.cod-indice BEGINS c-chave
    AND   inf-compl.cod-livre-1 <> ""
    .

MESSAGE
    inf-compl.dat-campo SKIP
    inf-compl.cod-livre-1 SKIP
    VIEW-AS ALERT-BOX .

ASSIGN c-chave = "101" + CHR(2) + "6993093" + CHR(2) + fnFormatDateYYYYMMDD(TODAY) .

CREATE bf-inf-compl . 
BUFFER-COPY inf-compl EXCEPT cod-indice TO bf-inf-compl .
ASSIGN bf-inf-compl.cod-indice = c-chave .
ASSIGN bf-inf-compl.dat-campo = TODAY .


