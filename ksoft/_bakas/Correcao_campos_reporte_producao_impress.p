/**/

/* FF */
/*
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
    RUN pi-item .
END.
*/
/*
/* IP */
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
    IF ITEM.it-codigo <> "958300-536I" THEN NEXT .
    RUN pi-item .
END.
*/

/* DP */
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
    RUN pi-item .
END.

PROCEDURE pi-item
    :
    DEF BUFFER cst-prod     FOR cst_embalagem_producao .

    DEF VAR cLoteOP     AS CHAR NO-UNDO .

    FOR EACH saldo-estoq NO-LOCK
        WHERE saldo-estoq.it-codigo = ITEM.it-codigo
        AND   saldo-estoq.qtidade-atu > 0
        :
        RELEASE cst-prod NO-ERROR .

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
        IF NOT AVAIL cst-prod THEN DO:
            FIND FIRST cst-prod NO-LOCK
                WHERE cst-prod.nr-ord-produ     = INT(SUBSTRING(cLoteOP, 1, 8))
                AND   cst-prod.bobina           = SUBSTRING(cLoteOP, 9, 3)
                AND   cst-prod.fracionamento    = SUBSTRING(cLoteOP, 12, 1)
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

        IF NOT AVAIL cst-prod THEN DO:
            MESSAGE
                "Sem Registro na cst-prod" SKIP
                saldo-estoq.it-codigo SKIP
                saldo-estoq.lote SKIP
                ROUND(saldo-estoq.qtidade-atu, 0) SKIP
                VIEW-AS ALERT-BOX .
            NEXT .
        END.
        ELSE DO:
            IF cst-prod.largura_saida > 0 AND cst-prod.largura_saida < 10 THEN DO:
                MESSAGE
                    "cst-prod.largura_saida < 10" SKIP
                    saldo-estoq.it-codigo SKIP
                    saldo-estoq.lote SKIP
                    cst-prod.nr-ord-produ SKIP
                    cst-prod.largura_saida SKIP
                    VIEW-AS ALERT-BOX .
                TRA:
                DO TRANSACTION
                    :
                    FIND CURRENT cst-prod EXCLUSIVE-LOCK .
                    ASSIGN cst-prod.largura_saida = cst-prod.largura_saida * 1000 .
                    FIND CURRENT cst-prod NO-LOCK .
                END.
                
            END.
        END.
    END.
END PROCEDURE .
