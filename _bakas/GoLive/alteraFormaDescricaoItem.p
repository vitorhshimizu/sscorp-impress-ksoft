/*
*/

FOR EACH ITEM NO-LOCK
    :
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN
            ITEM.ind-imp-desc = 4 /* Descricao + Narrativa Informada */
            .

        FOR FIRST item-dist EXCLUSIVE-LOCK 
            WHERE item-dist.it-codigo = ITEM.it-codigo
            :
            ASSIGN item-dist.log-cop-narrat = YES .
        END.
    END. 
END.




