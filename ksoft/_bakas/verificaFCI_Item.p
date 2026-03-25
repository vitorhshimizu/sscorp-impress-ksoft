/*
*/

FIND FIRST inf-compl EXCLUSIVE-LOCK 
    WHERE inf-compl.cdn-identif = 6 /* FCI */
    AND   inf-compl.cod-indice BEGINS "101" + CHR(2) + "8000123" 
    NO-ERROR .


