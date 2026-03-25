/*
*/

DEF BUFFER bf_dwb   FOR dwb_set_list .

FOR EACH dwb_set_list
    WHERE dwb_set_list.cod_dwb_program = "tar_importa_cotacao"
    AND   dwb_set_list.cod_dwb_user = "jalmeida"
    :
    DELETE dwb_set_list .
END.

FOR EACH dwb_set_list NO-LOCK
    WHERE dwb_set_list.cod_dwb_program = "tar_importa_cotacao"
    AND   dwb_set_list.cod_dwb_user = "dmaceno"
    :
    CREATE bf_dwb .
    BUFFER-COPY dwb_set_list EXCEPT cod_dwb_user TO bf_dwb .
    ASSIGN bf_dwb.cod_dwb_user = "jalmeida" .
END.


