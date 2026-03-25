/**/

OUTPUT TO VALUE("C:\temp\saida.csv") NO-CONVERT .

PUT UNFORM "Dt Trans;" .
PUT UNFORM "Est;" .
PUT UNFORM "Emitente;" .
PUT UNFORM "Nat Oper;" .
PUT UNFORM "Ser;" .
PUT UNFORM "Documento;" .
PUT UNFORM "Nome Emitente;" .
PUT UNFORM "Descri‡Æo Natureza;" .
PUT UNFORM "Item;" .
PUT UNFORM "Descri‡Æo Item;" .
PUT UNFORM "Chave NF" .
PUT UNFORM SKIP .

FOR EACH docum-est NO-LOCK
    WHERE docum-est.dt-trans >= DATE("01/05/2025")
    AND   docum-est.dt-trans <= DATE("31/05/2025")
    AND   docum-est.ce-atual = TRUE
    BY docum-est.dt-trans
    :
    FIND FIRST emitente NO-LOCK OF docum-est .

    FIND FIRST natur-oper NO-LOCK OF docum-est .

    FIND FIRST item-doc-est NO-LOCK OF docum-est .

    FIND FIRST ITEM NO-LOCK OF item-doc-est .

    PUT UNFORMATTED
            STRING(docum-est.dt-trans, "99/99/9999")
        ';' docum-est.cod-estabel
        ';' docum-est.cod-emitente
        ';' docum-est.nat-operacao
        ';' docum-est.serie-docto
        ';' docum-est.nro-docto
        ';' emitente.nome-abrev
        ';' natur-oper.denominacao
        ';' item-doc-est.it-codigo
        ';' ITEM.desc-item
        ';' docum-est.cod-chave-aces-nf-eletro
        SKIP .
END.

OUTPUT CLOSE .
