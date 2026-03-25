/*
Base Paper by List File: Ksoft_BasePaperList.csv
*/

{utils/fnFormatDesc.i}

/**/
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

/**/
DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .
RUN pi-acompanhar IN h-acomp("Aguarde...") .

DEF VAR cItem       AS CHAR NO-UNDO .
DEF VAR dQtKG       AS DECIMAL NO-UNDO .
DEF VAR dQtM2       AS DECIMAL NO-UNDO .
DEF VAR lLockCQ     AS LOGICAL NO-UNDO .
DEF VAR dNetPrice   AS DECIMAL NO-UNDO .

OUTPUT TO VALUE("C:\temp\Bestand_Basepaper_Set_up_details.csv") NO-CONVERT .

PUT UNFORMATTED
    "Costs;Storage Area;Stock Number;LA-Typ;Storage Place;LE-Typ;Storage Section;MA Number;MA Description;MA Width;"
    "HU-Number;Supplier HU;HU-nr tambour;Square Meter;Length HU;Gross Weight;Special Stock;Blockage Mark;Lock Quality;Joins;"
    "FSC/PEFC;Bez FSC/PEFC;Purchase document;Purchase Pos;Grammage;Core Diameter;Comment + ZQM;Remark quality;Supplier;Due Date;"
    "Store in Date;Matchcode Supplier;Net Price;Storage Period;Estab;Net Weight;Batch Number"
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
/*
FOR EACH tt-item NO-LOCK
    BY tt-item.it-codigo
    :
    ASSIGN cItem = SUBSTRING(tt-item.it-codigo, 1, 2) + "." + SUBSTRING(tt-item.it-codigo, 3) .
    FIND FIRST ITEM NO-LOCK WHERE ITEM.it-codigo = cItem NO-ERROR .
    IF NOT AVAIL ITEM THEN DO:
        MESSAGE "Item nÆo encontrado: " tt-item.it-codigo VIEW-AS ALERT-BOX .
        LEAVE .
    END.
    */
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
        IF AVAIL movto-estoq AND movto-estoq.cod-emitente <> 0 THEN DO:
            FIND FIRST emitente NO-LOCK WHERE emitente.cod-emitente = movto-estoq.cod-emitente NO-ERROR .
            IF AVAIL emitente THEN DO:
                FIND FIRST item-fornec NO-LOCK
                    WHERE item-fornec.it-codigo = ITEM.it-codigo
                    AND   item-fornec.cod-emitente = emitente.cod-emitente
                    NO-ERROR .
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

        /* Busca peso da embalagem do fornecedor campo dec-1 */
        IF AVAIL emitente THEN DO:
            FIND FIRST item-fornec NO-LOCK
                WHERE item-fornec.it-codigo = saldo-estoq.it-codigo
                AND   item-fornec.cod-emitente = emitente.cod-emitente
                NO-ERROR .
            IF NOT AVAIL item-fornec THEN DO:
                FIND FIRST item-fornec NO-LOCK
                    WHERE item-fornec.it-codigo = saldo-estoq.it-codigo
                    NO-ERROR .
                FIND FIRST emitente NO-LOCK WHERE emitente.cod-emitente = item-fornec.cod-emitente .
            END.
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
        IF NOT AVAIL zz-etiqueta THEN DO:
            FIND LAST zz-etiqueta NO-LOCK
                WHERE zz-etiqueta.cod-estabel   = saldo-estoq.cod-estabel
                AND   zz-etiqueta.lote          = saldo-estoq.lote
                AND   zz-etiqueta.it-codigo     = saldo-estoq.it-codigo
                NO-ERROR .
        END.

        /**/
        PUT UNFORMATTED
                "0"                             /* Costs */
            ';' UPPER(saldo-estoq.cod-depos)    /* Storage Area */
            ';' "111"                           /* Stock number */
            ';' ""                              /* LA-Typ */
            ';' UPPER(saldo-estoq.cod-localiz)  /* Storage Place */
            ';' "RO"                            /* LE-Typ */
            ';' "001"                           /* Storage Section */
            ';' ITEM.it-codigo                  /* MA Number */
            ';' fnFormatDesc(ITEM.desc-item)    /* MA Description */
            ';' IF ITEM.largura > 10 THEN ITEM.largura ELSE ITEM.largura * 1000 /* MA Width */

            ';' IF AVAIL zz-etiqueta THEN "'" + zz-etiqueta.cod-etiqueta ELSE "" /* HU-Number */
            ';' saldo-estoq.lote                /* Supplier HU */
            ';' ""                              /* HU-nr tambour */
            ';' dQtM2                           /* Square Meter */
            ';' "0"                             /* Length HU */
            ';' dQtKG                           /* Gross Weight */
            ';' ""                              /* Special Stock */
            ';' ""                              /* Blockage Mark */
            ';' STRING(lLockCQ , "S/")          /* Lock Quality */
            ';' ""                              /* Joins / Emendas */

            ';' ""                              /* FSC/PEFC */
            ';' IF AVAIL cst_item_uni_estab THEN UPPER(TRIM(cst_item_uni_estab.narrativa_fsc)) ELSE "" /* Bez FSC/PEFC */
            ';' IF AVAIL movto-estoq THEN movto-estoq.nro-docto ELSE "" /* Purchase document */
            ';' IF AVAIL movto-estoq THEN STRING(movto-estoq.sequen-nf) ELSE "" /* Purchase pos */
            ';' IF AVAIL cst_item_uni_estab THEN STRING(cst_item_uni_estab.gram_nominal) ELSE "" /* Grammage */
            ';' IF AVAIL it-carac-tec THEN it-carac-tec.observacao ELSE "" /* Core Diameter */
            ';' ""                              /* Comment + ZQM */
            ';' ""                              /* Remark quality */
            ';' IF AVAIL emitente THEN STRING(emitente.cod-emitente) + "-" + emitente.nome-abrev ELSE "" /* Supplier */
            ';' STRING(saldo-estoq.dt-vali-lote, "99/99/9999") /* Due Date */

            ';' STRING(saldo-estoq.dt-fabric, "99/99/9999") /* Store in Date */
            ';' IF AVAIL item-fornec THEN item-fornec.item-do-forn ELSE "" /* Matchcode Supplier */
            ';' dNetPrice                       /* Net Price */
            ';' TODAY - saldo-estoq.dt-fabric   /* Storage Period */
            ';' saldo-estoq.cod-estabel         /* Estab */
            ';' IF AVAIL item-fornec THEN dQtKG - item-fornec.dec-1 ELSE dQtKG /* Net Weight */
            ';' saldo-estoq.lote                /* Batch Number */
            SKIP .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




