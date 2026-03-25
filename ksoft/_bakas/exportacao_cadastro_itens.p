/*
*/

{utils/fnFormatDesc.i}

OUTPUT TO VALUE("C:\temp\JRA\articles.csv") NO-CONVERT .

PUT UNFORM "Item" .
PUT UNFORM ";Descri‡Æo" .
PUT UNFORM ";GE" .
PUT UNFORM ";Fam Material" .
PUT UNFORM ";Fam Comercial" .
PUT UNFORM ";UN" .
PUT UNFORM ";Situa‡Æo" .
PUT UNFORM ";NCM" .
PUT UNFORM ";Narrativa" .
PUT UNFORM SKIP .

FOR EACH ITEM NO-LOCK
    :
    PUT UNFORMATTED
            ITEM.it-codigo
        ';' fnFormatDesc(ITEM.desc-item)
        ';' ITEM.ge-codigo
        ';' ITEM.fm-codigo
        ';' ITEM.fm-cod-com
        ';' ITEM.un
        ';' {ininc/i17in172.i 04 ITEM.cod-obsoleto}
        ';' ITEM.class-fiscal
        ';' fnFormatDesc(ITEM.narrativa)
        SKIP .
END.

OUTPUT CLOSE .
