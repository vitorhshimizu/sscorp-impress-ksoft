/*
*/

FIND docum-est NO-LOCK
    WHERE docum-est.cod-emitente = 8044
    AND   docum-est.serie = "1"
    AND   docum-est.nro-docto = "0456134"
    .

MESSAGE
    docum-est.valor-mercad
    VIEW-AS ALERT-BOX .
