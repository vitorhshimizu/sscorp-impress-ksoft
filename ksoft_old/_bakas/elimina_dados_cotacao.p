/*
*/

DISABLE TRIGGERS FOR LOAD OF mgcad.cotacao .

DEF BUFFER cotacao  FOR mgcad.cotacao .

FOR EACH cotacao NO-LOCK
    :
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT cotacao EXCLUSIVE-LOCK .
        DELETE cotacao .
    END.
END.

