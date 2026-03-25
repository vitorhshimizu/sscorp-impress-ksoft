/*
Adicionar colunas: TU Etiqueta, 
Data de entrada no Estoque, Peso Bruto da Etiqueta, Fornecedor
*/

{utils/fnFormatDesc.i}

DEF VAR dNetPrice   AS DECIMAL NO-UNDO .
DEF VAR cCodForn    AS CHAR NO-UNDO .
DEF VAR cNomeForn   AS CHAR NO-UNDO .

OUTPUT TO VALUE("C:\temp\Bestand_Stock_Others.csv") NO-CONVERT .

PUT UNFORM "MA Number" .
PUT UNFORM ";MA Name" .
PUT UNFORM ";Stock Group" .
PUT UNFORM ";UM" .
PUT UNFORM ";TU" .
PUT UNFORM ";Batch" .
PUT UNFORM ";Stock In Date" .
PUT UNFORM ";Due Date" .
PUT UNFORM ";Company" .
PUT UNFORM ";Stock Area" .
PUT UNFORM ";Stock Location" .
PUT UNFORM ";Balance" .
PUT UNFORM ";Gross Weigth" .
PUT UNFORM ";Supplier Code" .
PUT UNFORM ";Supplier Name" .
PUT UNFORM ";Last Stock Price Per UM" .
PUT UNFORM SKIP .

FOR EACH ITEM NO-LOCK
    WHERE
    //Base Paper
    ITEM.ge-codigo <> 1  AND
    ITEM.ge-codigo <> 2  AND
    ITEM.ge-codigo <> 12 AND
    ITEM.ge-codigo <> 13 AND
    ITEM.ge-codigo <> 14 AND
    ITEM.ge-codigo <> 15 AND
    ITEM.ge-codigo <> 16 AND
    //DP
    ITEM.ge-codigo <> 66 AND
    ITEM.ge-codigo <> 69 AND
    ITEM.ge-codigo <> 81 AND
    ITEM.ge-codigo <> 82 AND
    ITEM.ge-codigo <> 83 AND
    ITEM.ge-codigo <> 84 AND
    ITEM.ge-codigo <> 91 AND
    ITEM.ge-codigo <> 92 AND
    ITEM.ge-codigo <> 93 AND
    ITEM.ge-codigo <> 94 AND
    ITEM.ge-codigo <> 95 AND
    ITEM.ge-codigo <> 96 AND
    ITEM.ge-codigo <> 97 AND
    //FF
    ITEM.ge-codigo <> 63 AND
    ITEM.ge-codigo <> 64 AND
    ITEM.ge-codigo <> 67 AND
    ITEM.ge-codigo <> 68 AND
    ITEM.ge-codigo <> 80 AND
    ITEM.ge-codigo <> 88 AND
    ITEM.ge-codigo <> 89 AND
    ITEM.ge-codigo <> 90 AND
    //IP
    ITEM.ge-codigo <> 00 AND
    ITEM.ge-codigo <> 21 AND
    ITEM.ge-codigo <> 23 AND
    ITEM.ge-codigo <> 25 AND
    ITEM.ge-codigo <> 26 AND
    ITEM.ge-codigo <> 28 AND
    ITEM.ge-codigo <> 29
    :
    FOR EACH saldo-estoq NO-LOCK
        WHERE saldo-estoq.it-codigo = ITEM.it-codigo
        AND   saldo-estoq.qtidade-atu > 0
        :
        /* Busca ultimo Preco Medio */
        ASSIGN dNetPrice = 0 .
        FOR LAST pr-it-per NO-LOCK
            WHERE pr-it-per.it-codigo = saldo-estoq.it-codigo
            AND   pr-it-per.cod-estabel = saldo-estoq.cod-estabel
            :
            ASSIGN dNetPrice = pr-it-per.val-unit-mat-m[1] + pr-it-per.val-unit-mob-m[1] + pr-it-per.val-unit-ggf-m[1] .
        END.

        /* Busca etiqueta da Six */
        FIND LAST zz-etiqueta NO-LOCK
            WHERE zz-etiqueta.cod-estabel   = saldo-estoq.cod-estabel
            AND   zz-etiqueta.cod-depos     = saldo-estoq.cod-depos
            AND   zz-etiqueta.cod-localiz   = saldo-estoq.cod-localiz
            AND   zz-etiqueta.lote          = saldo-estoq.lote
            AND   zz-etiqueta.it-codigo     = saldo-estoq.it-codigo
            AND   zz-etiqueta.qt-atual > 0
            NO-ERROR .
        IF NOT AVAIL zz-etiqueta AND saldo-estoq.lote <> "" THEN DO:
            FIND LAST zz-etiqueta NO-LOCK
                WHERE zz-etiqueta.cod-estabel   = saldo-estoq.cod-estabel
                AND   zz-etiqueta.lote          = saldo-estoq.lote
                AND   zz-etiqueta.it-codigo     = saldo-estoq.it-codigo
                AND   zz-etiqueta.qt-atual > 0
                NO-ERROR .
        END.

        /* Busca Fornecedor */
        ASSIGN cCodForn = "" .
        ASSIGN cNomeForn = "" .
        FOR LAST movto-estoq NO-LOCK
            WHERE movto-estoq.it-codigo = saldo-estoq.it-codigo
            AND   movto-estoq.lote = saldo-estoq.lote
            AND   movto-estoq.esp-docto = 21 /* NFE */
            :
            ASSIGN cCodForn = STRING(movto-estoq.cod-emitente) .
        END.
        IF cCodForn = "" THEN DO:
            FOR FIRST item-fornec NO-LOCK
                WHERE item-fornec.it-codigo = saldo-estoq.it-codigo
                :
                ASSIGN cCodForn = STRING(item-fornec.cod-emitente) .
            END.
        END.
        IF cCodForn <> "" THEN DO:
            FIND FIRST emitente NO-LOCK WHERE emitente.cod-emitente = INT(cCodForn) .
            ASSIGN cNomeForn = emitente.nome-abrev .
        END.

        /**/
        PUT UNFORM
                ITEM.it-codigo
            ';' fnFormatDesc(ITEM.desc-item)
            ';' ITEM.ge-codigo
            ';' ITEM.un
            ';' IF AVAIL zz-etiqueta THEN zz-etiqueta.cod-etiqueta ELSE ""
            ';' fnFormatDesc(saldo-estoq.lote)
            ';' STRING(saldo-estoq.dt-fabric , "99/99/9999")
            ';' IF saldo-estoq.dt-vali-lote = ? THEN "" ELSE STRING(saldo-estoq.dt-vali-lote, "99/99/9999")
            ';' saldo-estoq.cod-estabel
            ';' saldo-estoq.cod-depos
            ';' saldo-estoq.cod-localiz
            ';' saldo-estoq.qtidade-atu
            ';' IF ITEM.un = "KG" THEN STRING(saldo-estoq.qtidade-atu) ELSE IF AVAIL zz-etiqueta THEN STRING(zz-etiqueta.peso-bruto) ELSE ""
            ';' cCodForn
            ';' cNomeForn
            ';' dNetPrice
            SKIP .
    END.
END.

OUTPUT CLOSE .
