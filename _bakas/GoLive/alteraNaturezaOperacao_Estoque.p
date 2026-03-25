/*
*/

FOR EACH natur-oper NO-LOCK
    /*WHERE natur-oper.nat-operacao = "512501"*/
    :
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT natur-oper EXCLUSIVE-LOCK .
        ASSIGN
            natur-oper.baixa-estoq  = NO
            natur-oper.auto-ce      = NO
            .
    END. 
END.



