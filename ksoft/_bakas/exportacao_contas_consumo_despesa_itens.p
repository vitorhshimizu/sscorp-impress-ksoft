/*
*/

{utils/fnFormatDesc.i}

DEF TEMP-TABLE tt-conta NO-UNDO
    FIELD ct-codigo AS CHAR
    INDEX idx_key AS UNIQUE PRIMARY ct-codigo
    .

DEF VAR lDif        AS LOGICAL NO-UNDO .
DEF VAR cUtilizacao AS CHAR NO-UNDO .
DEF VAR cConta      AS CHAR NO-UNDO .
DEF VAR lInd        AS LOGICAL NO-UNDO .

FIND FIRST plano_cta_ctbl NO-LOCK .

OUTPUT TO VALUE("C:\temp\articles_accounts.csv") NO-CONVERT .

PUT UNFORM "Article Code" .
PUT UNFORM ";Article Desc" .
PUT UNFORM ";Stock Group" .
PUT UNFORM ";Expense Code" .
PUT UNFORM ";Expense Desc" .
PUT UNFORM ";Use Type" .
PUT UNFORM ";Account Number" .
PUT UNFORM ";Account Name" .
PUT UNFORM SKIP .

PROCEDURE pi-print
    :
    FIND FIRST cta_ctbl NO-LOCK
        WHERE cta_ctbl.cod_plano_cta_ctbl = plano_cta_ctbl.cod_plano_cta_ctbl
        AND   cta_ctbl.cod_cta_ctbl = cConta
        .

    PUT UNFORMATTED
            ITEM.it-codigo
        ';' fnFormatDesc(ITEM.desc-item)
        ';' ITEM.ge-codigo
        ';' ITEM.nat-despesa
        ';' fnFormatDesc(natureza-despesa.descricao)
        ';' cUtilizacao
        ';' cConta
        ';' cta_ctbl.des_tit_ctbl
        SKIP .
END PROCEDURE .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.tipo-contr = 4 /* DD */
    AND   ITEM.cod-obsoleto < 4 /* Nao esta Totalmente Obsoleto */
    AND   ITEM.nat-despesa <> 0
    :
    FIND FIRST natureza-despesa NO-LOCK OF ITEM . /* CD0138 */

    /* Verifica se todas as contas sao iguais - CD0253 */
    ASSIGN lDif = NO .
    ASSIGN cUtilizacao = "*" .
    ASSIGN cConta = "" .
    FOR EACH utiliz-natu-despes NO-LOCK
        WHERE utiliz-natu-despes.cod-nat-despesa = ITEM.nat-despesa
        AND   NOT utiliz-natu-despes.ct-codigo BEGINS "9"
        :
        IF cConta = "" THEN DO:
            ASSIGN cConta = utiliz-natu-despes.ct-codigo .
        END.
        ELSE IF cConta <> utiliz-natu-despes.ct-codigo THEN DO:
            ASSIGN lDif = YES .
            LEAVE .
        END.
    END.

    IF NOT lDif THEN DO:
        RUN pi-print .
    END.
    ELSE DO:
        ASSIGN lInd = NO .
        FOR EACH utiliz-natu-despes NO-LOCK
            WHERE utiliz-natu-despes.cod-nat-despesa = ITEM.nat-despesa
            AND   NOT utiliz-natu-despes.ct-codigo BEGINS "9"
            :
            ASSIGN cConta = utiliz-natu-despes.ct-codigo .
            ASSIGN cUtilizacao = utiliz-natu-despes.cod-utiliz .

            IF (cUtilizacao = "Ind" OR cUtilizacao = "Man" OR cUtilizacao = "Pro")
            THEN DO:
                IF lInd = NO THEN DO:
                    ASSIGN cUtilizacao = "Ind" .
                    ASSIGN lInd = YES .
                    RUN pi-print .
                END.
            END.
            ELSE DO:
                RUN pi-print .
            END.
        END.
    END.
END.

OUTPUT CLOSE .

/**/
/*
FIND FIRST plano_cta_ctbl NO-LOCK .

OUTPUT TO VALUE("C:\temp\accounts.csv") NO-CONVERT .

PUT UNFORM "Account Number" .
PUT UNFORM ";Account Name" .
PUT UNFORM SKIP .

FOR EACH tt-conta NO-LOCK
    :
    FIND FIRST cta_ctbl NO-LOCK
        WHERE cta_ctbl.cod_plano_cta_ctbl = plano_cta_ctbl.cod_plano_cta_ctbl
        AND   cta_ctbl.cod_cta_ctbl = tt-conta.ct-codigo
        .

    PUT UNFORMATTED
            tt-conta.ct-codigo
        ';' cta_ctbl.des_tit_ctbl
        SKIP .
END.

OUTPUT CLOSE .
*/

