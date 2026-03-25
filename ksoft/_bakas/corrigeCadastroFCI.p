/*
*/

FOR EACH inf-compl
    WHERE inf-compl.cdn-identif = 6 /* FCI */
    :
    IF NUM-ENTRIES(inf-compl.cod-indice, CHR(2)) < 3 THEN DO:
        DELETE inf-compl .
    END.
END.
