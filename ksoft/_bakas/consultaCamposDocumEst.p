/*
*/

FIND docum-est NO-LOCK
    WHERE docum-est.cod-emitente = 8044
    AND   docum-est.serie-docto = "1"
    AND   docum-est.nro-docto = "1456134"
    AND   docum-est.nat-operacao = "235203"
    .

MESSAGE
    docum-est.char-2 SKIP
    VIEW-AS ALERT-BOX .

/**/
FIND dt-docum-est NO-LOCK
    WHERE dt-docum-est.cod-emitente = 8044
    AND   dt-docum-est.serie-docto = "1"
    AND   dt-docum-est.nro-docto = "0456134"
    AND   dt-docum-est.nat-operacao = "1"
    .

MESSAGE
    dt-docum-est.char-2 SKIP
    VIEW-AS ALERT-BOX . 

