/*
*/

{utp/ut-glob.i}

{ftp/ft0527tt.i "-ft0527"} /* tt-param-ft0527 tt-digita-ft0527 */

DEF VAR raw-param        AS RAW NO-UNDO.

DEF TEMP-TABLE tt-raw-digita NO-UNDO
    FIELD raw-digita      AS RAW
    .

FIND nota-fiscal NO-LOCK
    WHERE nota-fiscal.cod-estabel = "101"
    AND   nota-fiscal.serie = "3"
    AND   nota-fiscal.nr-nota-fis = "0070957"
    .

EMPTY TEMP-TABLE tt-param-ft0527 .
EMPTY TEMP-TABLE tt-digita-ft0527 .
EMPTY TEMP-TABLE tt-raw-digita .

CREATE tt-param-ft0527 . ASSIGN
    tt-param-ft0527.destino                 = 2 /* Arquivo */  
    tt-param-ft0527.arquivo                 = SESSION:TEMP-DIR + nota-fiscal.cod-chave-aces-nf-eletro + ".pdf"          
    tt-param-ft0527.usuario                 = c-seg-usuario         
    tt-param-ft0527.data-exec               = TODAY
    tt-param-ft0527.hora-exec               = TIME
    tt-param-ft0527.parametro               = NO
    tt-param-ft0527.formato                 = 1
    tt-param-ft0527.cod-layout              = "DANFE-Mod.1"
    tt-param-ft0527.des-layout              = ""
    tt-param-ft0527.log-impr-dados          = NO
    tt-param-ft0527.v_num_tip_aces_usuar    = v_num_tip_aces_usuar
    tt-param-ft0527.ep-codigo               = i-ep-codigo-usuario
    tt-param-ft0527.c-cod-estabel           = nota-fiscal.cod-estabel
    tt-param-ft0527.c-serie                 = nota-fiscal.serie
    tt-param-ft0527.c-nr-nota-fis-ini       = nota-fiscal.nr-nota-fis
    tt-param-ft0527.c-nr-nota-fis-fim       = nota-fiscal.nr-nota-fis
    tt-param-ft0527.de-cdd-embarque-ini     = 0
    tt-param-ft0527.de-cdd-embarque-fim     = 999999999
    tt-param-ft0527.da-dt-saida             = nota-fiscal.dt-saida
    tt-param-ft0527.c-hr-saida              = ""
    tt-param-ft0527.rs-imprime              = nota-fiscal.ind-sit-nota
    tt-param-ft0527.nr-copias               = 1
    tt-param-ft0527.l-gera-danfe-xml        = NO
    .

CREATE tt-digita-ft0527. ASSIGN
    tt-digita-ft0527.ordem   = 1
    tt-digita-ft0527.exemplo = c-seg-usuario
    .

FOR EACH tt-digita-ft0527 NO-LOCK
    :
    CREATE tt-raw-digita .
    RAW-TRANSFER tt-digita-ft0527 TO tt-raw-digita.raw-digita .
END.

RAW-TRANSFER tt-param-ft0527 TO raw-param .
RUN ftp/ft0527rp.p(INPUT raw-param , INPUT TABLE tt-raw-digita) .

