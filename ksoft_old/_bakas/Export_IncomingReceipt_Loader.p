/*
*/

FIND dt-docum-est NO-LOCK
    WHERE dt-docum-est.chave-xml = "42250944347863000105550010000007211041892964"
    .

MESSAGE
    dt-docum-est.dt-emissao SKIP
    dt-docum-est.tipo-documento SKIP
    dt-docum-est.log-situacao SKIP
    dt-docum-est.log-cancelado SKIP
    VIEW-AS ALERT-BOX .


OUTPUT TO VALUE(SESSION:TEMP-DIR + "dt-docum-est.txt") NO-CONVERT .
EXPORT dt-docum-est .
OUTPUT CLOSE .

OUTPUT TO VALUE(SESSION:TEMP-DIR + "dt-it-docum-est.txt") NO-CONVERT .
FOR EACH dt-it-docum-est NO-LOCK
    WHERE dt-it-docum-est.serie-docto = dt-docum-est.serie-docto
    AND   dt-it-docum-est.nro-docto = dt-docum-est.nro-docto
    AND   dt-it-docum-est.cod-emitente = dt-docum-est.cod-emitente
    AND   dt-it-docum-est.nat-operacao = dt-docum-est.nat-operacao
    :
    EXPORT dt-it-docum-est .
END.
OUTPUT CLOSE .

