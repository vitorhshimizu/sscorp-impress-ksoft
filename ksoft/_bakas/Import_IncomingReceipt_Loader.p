/*
*/


INPUT FROM VALUE(SESSION:TEMP-DIR + "dt-docum-est.txt") NO-CONVERT .
REPEAT ON ERROR UNDO , LEAVE
    :
    CREATE dt-docum-est .
    IMPORT dt-docum-est .
END.
INPUT CLOSE .

INPUT FROM VALUE(SESSION:TEMP-DIR + "dt-it-docum-est.txt") NO-CONVERT .
REPEAT ON ERROR UNDO , LEAVE
    :
    CREATE dt-it-docum-est .
    IMPORT dt-it-docum-est .
END.
INPUT CLOSE .




