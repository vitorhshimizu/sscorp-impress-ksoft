/**/

DEF VAR h-cspdapi002        AS HANDLE NO-UNDO .
RUN cstp/cspdapi002.p PERSISTENT SET h-cspdapi002 .

DEF VAR de-aliquota-pis     AS DECIMAL NO-UNDO .
DEF VAR de-aliquota-cofins  AS DECIMAL NO-UNDO .
DEF VAR de-aliquota-icms    AS DECIMAL NO-UNDO .
DEF VAR de-aliq-dif-icms    AS DECIMAL NO-UNDO .
DEF VAR de-preco-final      AS DECIMAL NO-UNDO .
DEF VAR de-preco-fatur      AS DECIMAL NO-UNDO .

FIND FIRST emitente NO-LOCK
    WHERE emitente.nome-abrev = "ARAUCO PG"
    .

FIND FIRST ITEM NO-LOCK
    WHERE ITEM.it-codigo = "30067044"
    .

ASSIGN de-preco-final = 3.20 .

RUN pi-aliquota-pis-cofins-icms IN h-cspdapi002 
    (INPUT "510101" ,
     INPUT "101" ,
     INPUT emitente.estado ,
     INPUT emitente.pais,
     INPUT ITEM.it-codigo ,
     INPUT emitente.nome-abrev ,
     OUTPUT de-aliquota-pis,
     OUTPUT de-aliquota-cofins,
     OUTPUT de-aliquota-icms,
     OUTPUT de-aliq-dif-icms )
    .

RUN pi-preco-final-fatur-ped-item IN h-cspdapi002 
    (INPUT de-preco-final , 
     INPUT 0 , /* Preco Moeda */
     INPUT 0 , /* Ptax */
     INPUT emitente.nome-abrev ,
     INPUT ITEM.it-codigo ,
     INPUT NO /* Preco Informado */ ,
     INPUT de-preco-final ,
     INPUT de-aliquota-pis ,
     INPUT de-aliquota-cofins ,
     INPUT de-aliquota-icms ,
     INPUT de-aliq-dif-icms , 
     INPUT 1 /* Aberto */ ,
     INPUT 1 /* Qt Pedida */,
     INPUT 0 /* Qt Atendida */ ,
     INPUT de-preco-final ,
     OUTPUT de-preco-final,
     OUTPUT de-preco-fatur)
    .

MESSAGE
    de-aliquota-pis SKIP
    de-aliquota-cofins SKIP
    de-aliquota-icms SKIP
    de-aliq-dif-icms SKIP
    de-preco-final SKIP
    de-preco-fatur SKIP
    VIEW-AS ALERT-BOX .

IF VALID-HANDLE(h-cspdapi002) THEN DO:
    DELETE PROCEDURE h-cspdapi002 NO-ERROR .
    ASSIGN h-cspdapi002 = ? .
END.
