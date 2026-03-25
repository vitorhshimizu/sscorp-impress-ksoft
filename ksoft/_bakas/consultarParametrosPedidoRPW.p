/*
*/

{utp/ut-glob.i}

{ftp/ft0527tt.i "-ft0527"} /* tt-param-ft0527 tt-digita-ft0527 */

DEF VAR i-cont  AS INT NO-UNDO .

FIND ped_exec_param NO-LOCK
    WHERE ped_exec_param.num_ped_exec = 463727
    .

CREATE tt-param-ft0527 .
RAW-TRANSFER ped_exec_param.raw_param_ped_exec TO tt-param-ft0527 .

OUTPUT TO VALUE("C:\temp\dados.txt") NO-CONVERT .

DO i-cont = 1 TO BUFFER tt-param-ft0527:NUM-FIELDS
    :
    PUT UNFORM
        BUFFER tt-param-ft0527:BUFFER-FIELD(i-cont):NAME ": " 
        BUFFER tt-param-ft0527:BUFFER-FIELD(i-cont):BUFFER-VALUE
        SKIP .
END.

OUTPUT CLOSE .


