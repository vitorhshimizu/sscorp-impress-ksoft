/*
FF
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
DEF VAR dPesoEmb    AS DECIMAL NO-UNDO .
DEF VAR cLoteOP     AS CHAR NO-UNDO .

OUTPUT TO VALUE("C:\temp\Bestand_Finish_Folie_Set_up_details.csv") NO-CONVERT .

PUT UNFORMATTED
    "Stock;Stock area;Storage place;Pallet type;Target Customer;Customer PN;Description;Width;Parent TU;Gross Parent TU;"
    "TU;Quantity KG;Lenght;M2;Rollbreaks;Stroke;Core Diameter;FSC/PEFC;Bez FSC/PEFC;Comment + ZQM;"
    "Lock Quality;Storage period;End of storage;Prod. Order;Creation date;Target Customer Name;Decor Number;Net Price;Net Weight;Batch Number;"
    "Roll Number;Grammage"
    SKIP .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = 63 OR
          ITEM.ge-codigo = 64 OR
          ITEM.ge-codigo = 67 OR
          ITEM.ge-codigo = 68 OR
          ITEM.ge-codigo = 80 OR
          ITEM.ge-codigo = 88 OR
          ITEM.ge-codigo = 89 OR
          ITEM.ge-codigo = 90
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

        ASSIGN dPesoEmb = 0 .
        IF AVAIL cst-prod THEN DO:
            ASSIGN dPesoEmb = cst-prod.kg_bruto - cst-prod.kg_liquido .
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
                "111"                           //Stock
            ';' UPPER(saldo-estoq.cod-depos)    //Store Area
            ';' IF saldo-estoq.cod-localiz = "" THEN "I10000001" ELSE saldo-estoq.cod-localiz //Storage Place
            ';' IF AVAIL zz-item-embalagem THEN zz-item-embalagem.item-emb ELSE "" //Pallet type
            ';' IF AVAIL emitente THEN STRING(emitente.cod-emitente) ELSE "" //Target Customer
            ';' IF AVAIL item-cli THEN item-cli.item-do-cli ELSE "" //Customer PN
            ';' fnFormatDesc(ITEM.desc-item)//Description 1
            ';' IF AVAIL cst-prod THEN cst-prod.largura_saida ELSE 0 //Width mm
            ';' ""                          //Parent TU
            ';' ""                          //Gross Parent TU

            ';' IF AVAIL zz-etiqueta THEN "'" + zz-etiqueta.cod-etiqueta ELSE "" //TU
            ';' IF AVAIL cst-prod THEN MAX(cst-prod.kg_bruto, cst-prod.kg_liquido) ELSE 0 //Quantity KG
            ';' IF AVAIL cst-prod THEN cst-prod.m_lineares ELSE 0 //Length mm
            ';' saldo-estoq.qtidade-atu     //m2
            ';' IF AVAIL cst-prod THEN cst-prod.emendas ELSE 0 //Rollbreaks
            ';' ""                          //Stroke
            ';' IF AVAIL it-carac-tec THEN it-carac-tec.observacao ELSE "" /* Core Diameter */
            ';' ""                          //FSC/PEFC
            ';' IF AVAIL cst_item_uni_estab THEN UPPER(TRIM(cst_item_uni_estab.narrativa_fsc)) ELSE "" //Bez FSC/PEFC
            ';' ""                          //Comment + ZQM

            ';' STRING(lLockCQ , "S/")      //Locked
            ';' TODAY - saldo-estoq.dt-fabric   /* Storage Period */
            ';' STRING(saldo-estoq.dt-vali-lote, "99/99/9999") /* Due Date */
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.nr-ord-produ) ELSE "" //Prod. Order
            ';' STRING(saldo-estoq.dt-fabric, "99/99/9999") //Creation DT
            ';' IF AVAIL emitente THEN STRING(emitente.nome-abrev) ELSE "" //Target Customer Name
            ';' saldo-estoq.it-codigo       // Decor Number
            ';' dNetPrice //Net Price
            ';' IF AVAIL cst-prod THEN MIN(cst-prod.kg_bruto, cst-prod.kg_liquido) ELSE 0 //Net Weight
            ';' saldo-estoq.lote            // Batch Number

            ';' IF AVAIL cst-prod THEN cst-prod.bobina + cst-prod.fracionamento ELSE "" //Roll Number
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.gramatura) ELSE "" //Grammage
            SKIP .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




