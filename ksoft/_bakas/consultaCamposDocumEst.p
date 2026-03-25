/*
*/

FIND docum-est NO-LOCK
    WHERE docum-est.cod-emitente = 1114
    AND   docum-est.serie-docto = "3"
    AND   docum-est.nro-docto = "0000001"
    AND   docum-est.nat-operacao = "310101"
    .

MESSAGE docum-est.char-2
    VIEW-AS ALERT-BOX .


