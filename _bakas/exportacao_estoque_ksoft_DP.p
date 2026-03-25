/*
DP
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

OUTPUT TO VALUE("C:\temp\Bestand_Decorative_Paper_Set_up_details.csv") NO-CONVERT .

PUT UNFORMATTED
    "Stock;Stock area;Storage place;Packaging type;Target Customer;Customer PN;Description;Width;TU;Gross;"
    "Tare;Quantity;LM;Lenght;M2;Rollbreaks;Stroke;Core Diameter;FSC/PEFC;Bez FSC/PEFC;"
    "Lock Quality;Storage period;End of storage;Prod. Order;Creation date;Target Customer Name;Decor Number"
    SKIP .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = 66 OR
          ITEM.ge-codigo = 69 OR
          ITEM.ge-codigo = 81 OR
          ITEM.ge-codigo = 82 OR
          ITEM.ge-codigo = 83 OR
          ITEM.ge-codigo = 84 OR
          ITEM.ge-codigo = 91 OR
          ITEM.ge-codigo = 92 OR
          ITEM.ge-codigo = 93 OR
          ITEM.ge-codigo = 94 OR
          ITEM.ge-codigo = 95 OR
          ITEM.ge-codigo = 96 OR
          ITEM.ge-codigo = 97
    BY ITEM.it-codigo
    :
    IF ITEM.desc-item MATCHES "*ACERTO*" THEN NEXT .
    IF ITEM.un <> "KG" THEN NEXT .
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

        /* Busca dados de producao pela bobina */
        FIND FIRST cst-prod NO-LOCK
            WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 8))
            AND   cst-prod.bobina           = SUBSTRING(saldo-estoq.lote, 9, 2)
            AND   cst-prod.fracionamento    = SUBSTRING(saldo-estoq.lote, 11, 1)
            AND   cst-prod.nr-reporte <> 0
            NO-ERROR .
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 7))
                AND   cst-prod.bobina           = SUBSTRING(saldo-estoq.lote, 8, 2)
                AND   cst-prod.fracionamento    = SUBSTRING(saldo-estoq.lote, 10, 1)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        /* Busca dados de producao pela sequencia reporte */
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 8))
                AND   cst-prod.num-seq-rep      = INT(SUBSTRING(saldo-estoq.lote, 9))
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 7))
                AND   cst-prod.num-seq-rep      = INT(SUBSTRING(saldo-estoq.lote, 8))
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        /* Busca dados de producao pela quantidade KG */
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 8))
                AND   ROUND(cst-prod.kg_liquido, 0) = ROUND(saldo-estoq.qtidade-atu, 0)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(saldo-estoq.lote, 1, 7))
                AND   ROUND(cst-prod.kg_liquido, 0) = ROUND(saldo-estoq.qtidade-atu, 0)
                AND   cst-prod.nr-reporte <> 0
                NO-ERROR .
        END.

        ASSIGN dPesoEmb = 0 .
        IF AVAIL cst-prod THEN DO:
            ASSIGN dPesoEmb = cst-prod.kg_bruto - cst-prod.kg_liquido .
        END.

        /* Busca dados do cliente */
        FIND FIRST item-cli NO-LOCK
            WHERE item-cli.it-codigo = ITEM.it-codigo
            AND   item-cli.item-do-cli <> ""
            NO-ERROR .
        IF AVAIL item-cli THEN DO:
            FIND FIRST emitente NO-LOCK WHERE emitente.nome-abrev = item-cli.nome-abrev .
        END.

        /* Busca ultimo Preco Medio */
        ASSIGN dNetPrice = 0 .
        FOR LAST pr-it-per NO-LOCK
            WHERE pr-it-per.it-codigo = saldo-estoq.it-codigo
            AND   pr-it-per.cod-estabel = saldo-estoq.cod-estabel
            :
            ASSIGN dNetPrice = pr-it-per.val-unit-mat-m[1] + pr-it-per.val-unit-mob-m[1] + pr-it-per.val-unit-ggf-m[1] .
        END.

        /**/
        PUT UNFORMATTED
                "116"                           //Stock
            ';' UPPER(saldo-estoq.cod-depos)    //Store Area
            ';' UPPER(saldo-estoq.cod-localiz)  //Storage Place
            ';' "RO"                            //Packaging type
            ';' IF AVAIL item-cli THEN STRING(item-cli.cod-emitente) ELSE "" //Target Customer
            ';' IF AVAIL item-cli THEN item-cli.item-do-cli ELSE "" //Customer PN
            ';' fnFormatDesc(ITEM.desc-item)//Description 1
            ';' IF AVAIL cst-prod THEN cst-prod.largura_saida ELSE 0 //Width mm
            ';' saldo-estoq.lote            //TU
            ';' IF AVAIL cst-prod THEN saldo-estoq.qtidade-atu + dPesoEmb ELSE 0 //Gross Weith

            ';' ""                          //Tare
            ';' saldo-estoq.qtidade-atu     //Quantity KG
            ';' IF AVAIL cst-prod THEN cst-prod.m_lineares ELSE 0 //LM
            ';' 0 //Length mm
            ';' IF AVAIL cst-prod THEN cst-prod.m_quadrados ELSE 0 //m2
            ';' ""                          //Rollbreaks
            ';' ""                          //Stroke
            ';' ""                          //Core Diameter
            ';' ""                          //FSC/PEFC
            ';' IF AVAIL cst_item_uni_estab THEN UPPER(TRIM(cst_item_uni_estab.narrativa_fsc)) ELSE "" //Bez FSC/PEFC

            ';' STRING(lLockCQ , "S/")      //Locked
            ';' TODAY - saldo-estoq.dt-fabric   /* Storage Period */
            ';' STRING(saldo-estoq.dt-vali-lote, "99/99/9999") /* Due Date */
            ';' IF AVAIL cst-prod THEN STRING(cst-prod.nr-ord-produ) ELSE "" //Prod. Order
            ';' STRING(saldo-estoq.dt-fabric, "99/99/9999") //Creation DT
            ';' IF AVAIL item-cli THEN STRING(item-cli.nome-abrev) ELSE "" //Target Customer Name
            ';' saldo-estoq.it-codigo       // Decor Number
            SKIP .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




