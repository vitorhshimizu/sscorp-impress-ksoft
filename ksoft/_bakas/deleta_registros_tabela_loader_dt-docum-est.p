/*
*/

DISABLE TRIGGERS FOR LOAD OF dt-docum-est .
DISABLE TRIGGERS FOR LOAD OF dt-it-docum-est .

FOR EACH dt-docum-est NO-LOCK
    :
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT dt-docum-est EXCLUSIVE-LOCK .
        DELETE dt-docum-est .
    END.
END.

FOR EACH dt-it-docum-est NO-LOCK
    :
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT dt-it-docum-est EXCLUSIVE-LOCK .
        DELETE dt-it-docum-est .
    END.
END.


