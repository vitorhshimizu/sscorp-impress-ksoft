/*
*/

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ind-imp-desc <> 7
    :
    IF ITEM.it-codigo MATCHES "*-DD" THEN NEXT . /* Embalagens Pallets */
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN
            ITEM.ind-imp-desc = 7 /* Narrativa Informada */
            .

        FOR FIRST item-dist EXCLUSIVE-LOCK 
            WHERE item-dist.it-codigo = ITEM.it-codigo
            :
            ASSIGN item-dist.log-cop-narrat = YES .
        END.
    END. 
END.




