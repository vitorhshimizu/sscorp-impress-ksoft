/*
IP
Tabela esp_grup_estoque
fnRetornaTipoItem(tt-item.ge-codigo)
*/

{utils/impress/fnRetornaTipoItem.i}
{utils/fnFormatDesc.i}

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .
RUN pi-acompanhar IN h-acomp("Aguarde...") .

DEF BUFFER cst-prod     FOR cst_embalagem_producao .

DEF VAR lLockCQ     AS LOGICAL NO-UNDO .
DEF VAR dNetPrice   AS DECIMAL NO-UNDO .
DEF VAR cLoteOP     AS CHAR NO-UNDO .

OUTPUT TO VALUE("C:\temp\Bestand_Impregnated_Paper_Set_up_details.csv") NO-CONVERT .

PUT UNFORMATTED
    "Stock;Stock area;Storage place;TU;M2;M;Tare;Gross weight;Customer PN;Decor Number;"
    "Description 1;Width mm;Qt in PSC;Length mm;Width mm;Turned;Reservation;Locked;Grammage;Source com;"
    "Creation DT;FSC/PEFC;Bez FSC/PEFC;Target Customer;Net Price;Net Weight;Batch Number;Pallet PN;"
    "Prod. Order;Num Paller;Pallet"
    SKIP .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = 00 OR
          ITEM.ge-codigo = 21 OR
          ITEM.ge-codigo = 23 OR
          ITEM.ge-codigo = 25 OR
          ITEM.ge-codigo = 26 OR
          ITEM.ge-codigo = 28 OR
          ITEM.ge-codigo = 29
    BY ITEM.it-codigo
    :
    IF ITEM.desc-item MATCHES "*ACERTO*" THEN NEXT .
    RUN pi-acompanhar IN h-acomp(ITEM.it-codigo) .
    /**/
    FIND FIRST cst_item_uni_estab NO-LOCK
        WHERE cst_item_uni_estab.it-codigo = ITEM.it-codigo
        AND   cst_item_uni_estab.gram_nominal > 0
        NO-ERROR .

    FOR EACH saldo-estoq NO-LOCK
        WHERE saldo-estoq.it-codigo = ITEM.it-codigo
        AND   saldo-estoq.qtidade-atu > 0
        :
        ASSIGN lLockCQ = FALSE .
        IF saldo-estoq.cod-depos = "CQ" OR
           saldo-estoq.cod-depos = "CQ1" OR
           saldo-estoq.cod-depos = "DNC" OR
           saldo-estoq.cod-depos = "SEG" OR
           saldo-estoq.cod-depos = "SET"
        THEN DO:
            ASSIGN lLockCQ = TRUE .
        END.

        RELEASE cst-prod .
        RELEASE item-cli .
        RELEASE emitente .

        ASSIGN cLoteOP = saldo-estoq.lote .
        ASSIGN cLoteOP = REPLACE(cLoteOP, ".", "") .
        ASSIGN cLoteOP = REPLACE(cLoteOP, "-", "") .

        /* Busca dados de producao pela bobina DP */
        FIND FIRST cst-prod NO-LOCK
            WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 8))
            AND   cst-prod.bobina           = SUBSTRING(cLoteOP, 9, 2)
            AND   cst-prod.fracionamento    = SUBSTRING(cLoteOP, 11, 1)
            AND   cst-prod.nr-reporte <> 0
            NO-ERROR .
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 7))
                AND   cst-prod.bobina           = SUBSTRING(cLoteOP, 8, 2)
                AND   cst-prod.fracionamento    = SUBSTRING(cLoteOP, 10, 1)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        /* Busca dados de producao pela sequencia reporte IP */
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 8))
                AND   cst-prod.num-seq-rep      = INT(SUBSTRING(cLoteOP, 9))
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 7))
                AND   cst-prod.num-seq-rep      = INT(SUBSTRING(cLoteOP, 8))
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 8))
                AND   cst-prod.nr-pallet        = SUBSTRING(cLoteOP, 9)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 7))
                AND   cst-prod.nr-pallet        = SUBSTRING(cLoteOP, 8)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        /* Busca dados de producao pela quantidade M2 */
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 8))
                AND   ROUND(cst-prod.m_quadrados, 0) = ROUND(saldo-estoq.qtidade-atu, 0)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 7))
                AND   ROUND(cst-prod.m_quadrados, 0) = ROUND(saldo-estoq.qtidade-atu, 0)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        /* Busca dados do cliente */
        IF AVAIL cst-prod AND cst-prod.nr-ord-produ <> 0 THEN DO:
            FIND FIRST ord-prod NO-LOCK
                WHERE ord-prod.nr-ord-produ = cst-prod.nr-ord-produ
                .
            FIND FIRST emitente NO-LOCK WHERE emitente.nome-abrev = ord-prod.nome-abrev .
            FIND FIRST item-cli NO-LOCK
                WHERE item-cli.it-codigo = ITEM.it-codigo
                AND   item-cli.nome-abrev = emitente.nome-abrev
                AND   item-cli.item-do-cli <> ""
                NO-ERROR .
        END.
        ELSE DO:
            FIND FIRST item-cli NO-LOCK
                WHERE item-cli.it-codigo = ITEM.it-codigo
                AND   item-cli.item-do-cli <> ""
                NO-ERROR .
            IF AVAIL item-cli THEN DO:
                FIND FIRST emitente NO-LOCK WHERE emitente.nome-abrev = item-cli.nome-abrev .
            END.
        END.

        /* Busca ultimo Preco Medio */
        ASSIGN dNetPrice = 0 .
        FOR LAST pr-it-per NO-LOCK
            WHERE pr-it-per.it-codigo = saldo-estoq.it-codigo
            AND   pr-it-per.cod-estabel = saldo-estoq.cod-estabel
            :
            ASSIGN dNetPrice = pr-it-per.val-unit-mat-m[1] + pr-it-per.val-unit-mob-m[1] + pr-it-per.val-unit-ggf-m[1] .
        END.

        /* Busca diametro do tubo nas caracteriscas tecnicas do item */
        FIND FIRST it-carac-tec NO-LOCK
            WHERE it-carac-tec.it-codigo = saldo-estoq.it-codigo
            AND   it-carac-tec.cd-folha = "FolImpr"
            AND   it-carac-tec.cd-comp = "DIAMTUB"
            NO-ERROR .

        /* Busca etiqueta da Six */
        FIND LAST zz-etiqueta NO-LOCK
            WHERE zz-etiqueta.cod-estabel   = saldo-estoq.cod-estabel
            AND   zz-etiqueta.cod-depos     = saldo-estoq.cod-depos
            AND   zz-etiqueta.cod-localiz   = saldo-estoq.cod-localiz
            AND   zz-etiqueta.lote          = saldo-estoq.lote
            AND   zz-etiqueta.it-codigo     = saldo-estoq.it-codigo
            AND   zz-etiqueta.qt-atual > 0
            NO-ERROR .

        /* Busca embalagem do Pallet da Six */
        FIND LAST zz-item-embalagem NO-LOCK
            WHERE zz-item-embalagem.it-codigo = saldo-estoq.it-codigo
            NO-ERROR .

        /**/
        PUT UNFORMATTED
                "116"                       //Stock
            ';' ""                          //Store Area
            ';' IF saldo-estoq.cod-localiz = "" THEN "I10000001" ELSE saldo-estoq.cod-localiz //Storage Place
            ';' IF AVAIL zz-etiqueta THEN "'" + zz-etiqueta.cod-etiqueta ELSE "" //TU
            ';' saldo-estoq.qtidade-atu     //M2
            ';' IF AVAIL cst-prod THEN cst-prod.m_lineares ELSE 0 //M
            ';' ""                          //Tare
            ';' IF AVAIL cst-prod THEN MAX(cst-prod.kg_bruto, cst-prod.kg_liquido) ELSE 0 //Gross weight
            ';' IF AVAIL item-cli THEN item-cli.item-do-cli ELSE "" //Customer PN
            ';' saldo-estoq.it-codigo       //Decor Number

            ';' fnFormatDesc(ITEM.desc-item) //Description 1
            ';' IF AVAIL cst-prod THEN cst-prod.largura_saida ELSE 0 //Width mm
            ';' IF AVAIL cst-prod THEN ROUND((saldo-estoq.qtidade-atu / cst-prod.m_quadrados ) * cst-prod.qt-folhas, 0) ELSE 0 //Qt in PSC
            ';' IF AVAIL cst-prod THEN cst-prod.comprimento * 1000 ELSE 0 //Length mm
            ';' IF AVAIL cst-prod THEN cst-prod.largura * 1000 ELSE 0 //Width mm
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.pallet-virado, "S/N") ELSE "" //Turned
            ';' "" // Reservation
            ';' STRING(lLockCQ , "S/")      //Locked
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.gramatura * 1000) ELSE "" //Grammage
            ';' //Source com

            ';' STRING(saldo-estoq.dt-fabric, "99/99/9999") //Creation DT
            ';' "" //FSC/PEFC
            ';' IF AVAIL cst_item_uni_estab THEN UPPER(TRIM(cst_item_uni_estab.narrativa_fsc)) ELSE "" //Bez FSC/PEFC
            ';' IF AVAIL emitente THEN STRING(emitente.cod-emitente) ELSE "" //Target Customer
            ';' dNetPrice //Net Price
            ';' IF AVAIL cst-prod THEN cst-prod.kg_liquido ELSE 0 //Net Weight
            ';' saldo-estoq.lote            // Batch Number
            ';' IF AVAIL zz-item-embalagem THEN zz-item-embalagem.item-emb ELSE "" //Pallet PN

            ';' IF AVAIL cst-prod THEN STRING(cst-prod.nr-ord-produ) ELSE ""
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.nr-pallet) ELSE ""
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.embalagem) ELSE ""
            SKIP .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




