/*
*/

FIND dt-docum-est
    WHERE dt-docum-est.chave-xml = "35250530910705000107550010000410341809983631"
    .

MESSAGE
    dt-docum-est.dt-emissao SKIP
    dt-docum-est.tipo-documento SKIP
    dt-docum-est.log-situacao SKIP
    dt-docum-est.log-cancelado SKIP
    VIEW-AS ALERT-BOX .

ASSIGN 
    dt-docum-est.log-situacao = NO
    .
