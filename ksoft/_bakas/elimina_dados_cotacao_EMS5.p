/*
*/

DISABLE TRIGGERS FOR LOAD OF cotac_parid .

DEF BUFFER cotac_parid  FOR cotac_parid .

FOR EACH cotac_parid NO-LOCK
    :
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT cotac_parid EXCLUSIVE-LOCK .
        DELETE cotac_parid .
    END.
END.


