/*
*/

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando") .
RUN pi-acompanhar IN h-acomp("Aguarde") .

DEF VAR c-linha         AS CHAR NO-UNDO .
DEF VAR i-ge-codigo     AS INT NO-UNDO .
DEF VAR c-conta         AS CHAR NO-UNDO .

INPUT FROM VALUE("C:\temp\JRA\altera_contas_DD_por_GE.csv") NO-CONVERT .
IMPORT UNFORMATTED c-linha .

REPEAT ON ERROR UNDO , LEAVE
    :
    IMPORT UNFORMATTED c-linha .
    IF c-linha = "" THEN NEXT .
    /**/
    ASSIGN i-ge-codigo  = INT(ENTRY(1, c-linha, ';')) .
    ASSIGN c-conta      = ENTRY(3, c-linha, ';') . 

    ASSIGN c-conta = REPLACE(c-conta, ".", "") .
    ASSIGN c-conta = REPLACE(c-conta, "-", "") .

    FOR EACH ITEM NO-LOCK
        WHERE ITEM.ge-codigo = i-ge-codigo
        AND   ITEM.tipo-con-est = 1 /* Serial */
        BY ITEM.ge-codigo
        BY ITEM.it-codigo
        :
        RUN pi-acompanhar IN h-acomp
            ("GE: " + STRING(ITEM.ge-codigo) + " - ITEM: " + ITEM.it-codigo)
            .

        TRA1:
        DO TRANSACTION ON ERROR UNDO , LEAVE
            :
            FIND CURRENT ITEM EXCLUSIVE-LOCK .
            ASSIGN
                ITEM.ct-codigo = c-conta
                ITEM.sc-codigo = ""
                ITEM.deposito-pad = "DBD"
                ITEM.cod-estabel = "101"
                .
            FIND CURRENT ITEM NO-LOCK .
        END.
    END.
END.

INPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.


