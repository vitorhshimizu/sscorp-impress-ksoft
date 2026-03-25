/**/

DEF VAR cLinha  AS CHAR NO-UNDO .

INPUT FROM VALUE("C:\temp\JRA\fornecedores_inativar.csv") NO-CONVERT .
IMPORT UNFORMATTED cLinha .
REPEAT ON ERROR UNDO , LEAVE
    :
    IMPORT UNFORMATTED cLinha .
    IF cLinha = "" THEN NEXT .
    /**/
    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = INT(ENTRY(1,cLinha,';'))
        AND   (emitente.identific = 2 /* Fornecedor */OR 
               emitente.identific = 3 /* Ambos */ )
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        MESSAGE
            "Fornecedor n∆o encontrado" SKIP
            cLinha SKIP
            VIEW-AS ALERT-BOX .
    END.

    FIND FIRST dist-emitente NO-LOCK OF emitente NO-ERROR .
    IF NOT AVAIL dist-emitente THEN DO:
        MESSAGE
            "Dist Fornecedor n∆o encontrado" SKIP
            cLinha SKIP
            VIEW-AS ALERT-BOX .
    END.
    IF dist-emitente.idi-sit-fornec <> 4 /* Inativo */ THEN DO:
        TRA1:
        DO TRANSACTION ON ERROR UNDO , LEAVE
            :
            FIND CURRENT dist-emitente EXCLUSIVE-LOCK .

            ASSIGN dist-emitente.idi-sit-fornec = 4 /* Inativo */ .

            FIND CURRENT dist-emitente NO-LOCK .
        END.
    END.                                                       
END.

INPUT CLOSE .





