/*
*/

DEF VAR i-cont  AS INT NO-UNDO .
    
FOR EACH ITEM NO-LOCK
    WHERE ITEM.tipo-contr = 2 /* Total */
    AND   ITEM.cod-obsoleto < 4 /* Totalmente Obsoleto */
    BY ITEM.ge-codigo
    BY ITEM.it-codigo
    :
    ASSIGN i-cont = i-cont + 1 .
    
    MESSAGE
        ITEM.ge-codigo SKIP
        ITEM.it-codigo SKIP
        VIEW-AS ALERT-BOX . 
    
    /* Apenas para casos nao efetivados pela rotina padrao */
    /*
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN ITEM.tipo-contr = 4 . 
    END.
    */
END.

MESSAGE i-cont VIEW-AS ALERT-BOX .

