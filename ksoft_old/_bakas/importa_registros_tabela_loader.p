/*
*/

DEF BUFFER prod-dt-docum-est    FOR prodemscustom.dt-docum-est .
DEF BUFFER prod-dt-it-docum-est FOR prodemscustom.dt-it-docum-est .

DEF BUFFER dest-dt-docum-est    FOR emscustom.dt-docum-est .
DEF BUFFER dest-dt-it-docum-est FOR emscustom.dt-it-docum-est .

FOR EACH prod-dt-docum-est NO-LOCK
    :
    CREATE dest-dt-docum-est .
    BUFFER-COPY prod-dt-docum-est TO dest-dt-docum-est .
END.

/*
FOR EACH prod-dt-it-docum-est NO-LOCK
    :
    CREATE dest-dt-it-docum-est .
    BUFFER-COPY prod-dt-it-docum-est TO dest-dt-it-docum-est .
END.
*/
