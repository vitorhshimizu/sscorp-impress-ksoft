/*
*/

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = 31
    :
    FOR EACH item-uni-estab
        WHERE item-uni-estab.it-codigo = ITEM.it-codigo
        :
        IF item-uni-estab.deposito-pad = "" THEN DO:
            ASSIGN item-uni-estab.deposito-pad = ITEM.deposito-pad .
        END.
        ASSIGN item-uni-estab.cod-localiz = "" .
    END.
END.


