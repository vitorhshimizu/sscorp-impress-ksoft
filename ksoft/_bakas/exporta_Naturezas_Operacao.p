/*
*/

{utils/fnFormatDesc.i}

OUTPUT TO VALUE("C:\temp\naturezas.csv") NO-CONVERT .

PUT UNFORMATTED
    "Nat Oper;Descri‡Æo;Tipo"
    SKIP .

FOR EACH natur-oper NO-LOCK
    WHERE natur-oper.emite-duplic  = NO
    :
    PUT UNFORMATTED
            natur-oper.nat-operacao
        ';' UPPER(fnFormatDesc(natur-oper.denominacao))
        ';' {ininc/i06in245.i 4 natur-oper.tipo}
        SKIP .
END.

OUTPUT CLOSE .


