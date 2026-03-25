/*
Base Paper by GE:
01
02
12
13
14
15
16
*/

{utils/fnFormatDesc.i}

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .
RUN pi-acompanhar IN h-acomp("Aguarde...") .

DEF VAR dQtKG       AS DECIMAL NO-UNDO .
DEF VAR dQtM2       AS DECIMAL NO-UNDO .
DEF VAR lLockCQ     AS LOGICAL NO-UNDO .
DEF VAR dNetPrice   AS DECIMAL NO-UNDO .

OUTPUT TO VALUE("C:\temp\Bestand_Basepaper_Set_up_DATASUL.csv") NO-CONVERT .

PUT UNFORMATTED
    "Costs;Storage Area;Stock Number;LA-Typ;Storage Place;LE-Typ;Storage Section;MA Number;MA Description;MA Width;"
    "HU-Number;Supplier HU;HU-nr tambour;Square Meter;Length HU;Gross Weight;Special Stock;Blockage Mark;Lock Quality;Joins;"
    "FSC/PEFC;Bez FSC/PEFC;Purchase document;Purchase Pos;Grammage;Core Diameter;Comment + ZQM;Remark quality;Supplier;Due Date;"
    "Store in Date;Matchcode Supplier;Net Price;Storage Period;Estab"
    SKIP .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = 1  OR
          ITEM.ge-codigo = 2  OR
          ITEM.ge-codigo = 12 OR
          ITEM.ge-codigo = 13 OR
          ITEM.ge-codigo = 14 OR
          ITEM.ge-codigo = 15 OR
          ITEM.ge-codigo = 16
    BY ITEM.it-codigo
    :
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
        ASSIGN dQtKG = 0 .
        ASSIGN dQtM2 = 0 .
        IF ITEM.un = "KG" THEN DO:
            ASSIGN dQtKG = saldo-estoq.qtidade-atu . 
            IF AVAIL cst_item_uni_estab THEN DO:
                ASSIGN dQtM2 = (dQtKG * 1000) / cst_item_uni_estab.gram_nominal .
            END.
        END.

        ASSIGN lLockCQ = FALSE .
        IF saldo-estoq.cod-depos = "CQ" OR
           saldo-estoq.cod-depos = "CQ1" OR
           saldo-estoq.cod-depos = "DNC" OR
           saldo-estoq.cod-depos = "SEG" OR
           saldo-estoq.cod-depos = "SET"
        THEN DO:
            ASSIGN lLockCQ = TRUE .
        END.

        /* Busca da nota de entrada da origem do lote */
        RELEASE movto-estoq .
        RELEASE emitente .
        RELEASE item-fornec .

        FIND FIRST movto-estoq USE-INDEX cstidx_it_lote NO-LOCK
            WHERE movto-estoq.it-codigo = saldo-estoq.it-codigo
            AND   movto-estoq.lote = saldo-estoq.lote
            AND   movto-estoq.esp-docto = 21 /* NFE */
            AND   movto-estoq.cod-emitente <> 717 /* IMPRESS 101 */
            AND   movto-estoq.cod-emitente <> 3910 /* IMPRESS 102 */
            NO-ERROR .
        IF AVAIL movto-estoq THEN DO:
            FIND FIRST emitente NO-LOCK WHERE emitente.cod-emitente = movto-estoq.cod-emitente .
            FIND FIRST item-fornec NO-LOCK
                WHERE item-fornec.it-codigo = ITEM.it-codigo
                AND   item-fornec.cod-emitente = emitente.cod-emitente
                NO-ERROR .
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
                "0"                             /* Costs */
            ';' UPPER(saldo-estoq.cod-depos)    /* Storage Area */
            ';' "111"                           /* Stock number */
            ';' ""                              /* LA-Typ */
            ';' ""                              /* Storage Place */
            ';' "RO"                            /* LE-Typ */
            ';' "001"                           /* Storage Section */
            ';' ITEM.it-codigo                  /* MA Number */
            ';' fnFormatDesc(ITEM.desc-item)    /* MA Description */
            ';' IF ITEM.largura > 10 THEN ITEM.largura ELSE ITEM.largura * 1000 /* MA Width */

            ';' saldo-estoq.lote                /* HU-Number */
            ';' ""                              /* Supplier HU */
            ';' ""                              /* HU-nr tambour */
            ';' dQtM2                           /* Square Meter */
            ';' "0"                             /* Length HU */
            ';' dQtKG                           /* Gross Weight */
            ';' ""                              /* Special Stock */
            ';' ""                              /* Blockage Mark */
            ';' STRING(lLockCQ , "S/")          /* Lock Quality */
            ';' ""                              /* Joins */

            ';' ""                              /* FSC/PEFC */
            ';' IF AVAIL cst_item_uni_estab THEN UPPER(TRIM(cst_item_uni_estab.narrativa_fsc)) ELSE "" /* Bez FSC/PEFC */
            ';' IF AVAIL movto-estoq THEN movto-estoq.nro-docto ELSE "" /* Purchase document */
            ';' IF AVAIL movto-estoq THEN STRING(movto-estoq.sequen-nf) ELSE "" /* Purchase pos */
            ';' IF AVAIL cst_item_uni_estab THEN STRING(cst_item_uni_estab.gram_nominal) ELSE "" /* Grammage */
            ';' ""                              /* Core Diameter */
            ';' ""                              /* Comment + ZQM */
            ';' ""                              /* Remark quality */
            ';' IF AVAIL emitente THEN STRING(emitente.cod-emitente) + "-" + emitente.nome-abrev ELSE "" /* Supplier */
            ';' STRING(saldo-estoq.dt-vali-lote, "99/99/9999") /* Due Date */

            ';' STRING(saldo-estoq.dt-fabric, "99/99/9999") /* Store in Date */
            ';' IF AVAIL item-fornec THEN item-fornec.item-do-forn ELSE "" /* Matchcode Supplier */
            ';' dNetPrice                       /* Net Price */
            ';' TODAY - saldo-estoq.dt-fabric   /* Storage Period */
            ';' saldo-estoq.cod-estabel         /* Estab */
            SKIP .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




