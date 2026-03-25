/*
*/

FOR EACH dia_calend_glob
    WHERE dia_calend_glob.cod_calend = "FISCAL"
    AND   dia_calend_glob.dat_calend >= DATE("01/01/2026")
    :
    IF WEEKDAY(dia_calend_glob.dat_calend) = 1 /* Domingo */ THEN DO:
        ASSIGN dia_calend_glob.cod_clas_dia_calend = "Rep-rem" .
        ASSIGN dia_calend_glob.qtd_hora_util = 0 .
        ASSIGN dia_calend_glob.log_dia_util = NO .
    END.
END.


