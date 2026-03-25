/*
*/

DEF VAR cLinha      AS CHAR NO-UNDO .

DEF TEMP-TABLE tt-item NO-UNDO
    FIELD it-codigo AS CHAR
    FIELD desc-item AS CHAR
    INDEX idx_key AS UNIQUE PRIMARY it-codigo
    .

INPUT FROM VALUE("D:\totvs\datasul\erp\_custom_8280\ksoft\_bakas\Ksoft_BasePaperList.csv") NO-CONVERT .
IMPORT UNFORMATTED cLinha .
REPEAT ON ERROR UNDO , LEAVE
    :
    IMPORT UNFORMATTED cLinha .
    IF cLinha = "" THEN NEXT .
    CREATE tt-item . ASSIGN
        tt-item.it-codigo = ENTRY(1 , cLinha, ';')
        tt-item.desc-item = ENTRY(2 , cLinha, ';')
        .
END.
INPUT CLOSE .

DEF VAR cItem       AS CHAR NO-UNDO .

DEF TEMP-TABLE tt-ge NO-UNDO
    FIELD ge-codigo LIKE ITEM.ge-codigo
    INDEX idx_key AS UNIQUE PRIMARY ge-codigo
    .

FOR EACH tt-item NO-LOCK
    :
    ASSIGN cItem = SUBSTRING(tt-item.it-codigo, 1, 2) + "." + SUBSTRING(tt-item.it-codigo, 3) .
    FIND FIRST ITEM NO-LOCK WHERE ITEM.it-codigo = cItem NO-ERROR .
    IF NOT AVAIL ITEM THEN DO:
        MESSAGE "Item n∆o encontrado: " tt-item.it-codigo VIEW-AS ALERT-BOX .
        LEAVE .
    END.

    FIND FIRST tt-ge NO-LOCK OF ITEM NO-ERROR .
    IF NOT AVAIL tt-ge THEN DO:
        CREATE tt-ge .
        BUFFER-COPY ITEM TO tt-ge .
    END.
END.

OUTPUT TO VALUE("C:\temp\Base_Paper_GE.csv") NO-CONVERT .

FOR EACH tt-ge NO-LOCK
    :
    PUT UNFORMATTED
        tt-ge.ge-codigo
        SKIP .
END.

OUTPUT CLOSE .
