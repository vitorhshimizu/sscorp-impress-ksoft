/*
*/

DEF VAR h-cspdapi002            AS HANDLE NO-UNDO .
DEF VAR de-aliquota-pis         AS DECIMAL NO-UNDO .
DEF VAR de-aliquota-cofins      AS DECIMAL NO-UNDO .
DEF VAR de-aliquota-icms        AS DECIMAL NO-UNDO .
DEF VAR de-aliq-dif-icms        AS DECIMAL NO-UNDO .
DEF VAR de-preco-final          AS DECIMAL NO-UNDO .
DEF VAR de-preco-fatur          AS DECIMAL NO-UNDO .
DEF VAR de-tot-duplic           AS DECIMAL NO-UNDO .
DEF VAR de-surcharge            AS DECIMAL NO-UNDO .

RUN cstp/cspdapi002.p PERSISTENT SET h-cspdapi002 .

FIND FIRST ITEM NO-LOCK
    WHERE ITEM.it-codigo = "48222004"
    .

FIND FIRST emitente NO-LOCK
    WHERE emitente.cod-emitente = 614
    .

FIND FIRST natur-oper NO-LOCK
    WHERE natur-oper.nat-operacao = "510101"
    .

ASSIGN de-preco-final = 31.43 .
ASSIGN de-preco-fatur = de-preco-final .

ASSIGN de-surcharge = 1.0294 .

RUN pi-aliquota-pis-cofins-icms IN h-cspdapi002 
    (INPUT natur-oper.nat-operacao ,
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
     INPUT 1 , /* Ptax */
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
    de-preco-final SKIP
    de-preco-fatur SKIP
    de-preco-fatur * de-surcharge SKIP
    VIEW-AS ALERT-BOX .


IF VALID-HANDLE(h-cspdapi002) THEN DO:
    DELETE PROCEDURE h-cspdapi002 NO-ERROR .
    ASSIGN h-cspdapi002 = ? .
END.
