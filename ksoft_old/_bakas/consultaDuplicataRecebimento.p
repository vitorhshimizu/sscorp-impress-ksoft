/*
*/

FIND FIRST dupli-apagar NO-LOCK
    WHERE dupli-apagar.cod-emitente = 1114
    AND   dupli-apagar.serie-docto = "3"
    .

MESSAGE 
    dupli-apagar.char-1 SKIP
    VIEW-AS ALERT-BOX .
