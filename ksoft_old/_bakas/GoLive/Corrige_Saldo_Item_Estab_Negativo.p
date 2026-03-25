/*
*/

FOR EACH ITEM NO-LOCK
    WHERE item.ge-codigo >= 50 
    //AND   ITEM.it-codigo = "73.257"
    ,
    EACH item-estab
    WHERE item-estab.it-codigo = ITEM.it-codigo
    :
    if item-estab.sald-ini-mat-m[1] < 0 or
       item-estab.sald-ini-mat-m[2] < 0 or
       item-estab.sald-ini-mat-m[3] < 0 or
       item-estab.sald-ini-mob-m[1] < 0 or
       item-estab.sald-ini-mob-m[2] < 0 or
       item-estab.sald-ini-mob-m[3] < 0 OR
       item-estab.sald-ini-ggf-m[1] < 0 or
       item-estab.sald-ini-ggf-m[2] < 0 or
       item-estab.sald-ini-ggf-m[3] < 0 
    then do:
        /*
        MESSAGE
            ITEM.it-codigo SKIP
            ITEM.cod-estabel SKIP
            item-estab.sald-ini-mat-m[1] SKIP 
            item-estab.sald-ini-mat-m[2] SKIP
            item-estab.sald-ini-mat-m[3] SKIP
            item-estab.sald-ini-mob-m[1] SKIP
            item-estab.sald-ini-mob-m[2] SKIP
            item-estab.sald-ini-mob-m[3] SKIP
            item-estab.sald-ini-ggf-m[1] SKIP
            item-estab.sald-ini-ggf-m[2] SKIP
            item-estab.sald-ini-ggf-m[3] SKIP
            VIEW-AS ALERT-BOX .
            */
        /* Corrige saldos negativos */
        IF item-estab.sald-ini-mat-m[1] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mat-m[1] = 0 .
        END.
        IF item-estab.sald-ini-mat-m[2] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mat-m[2] = 0 .
        END.
        IF item-estab.sald-ini-mat-m[3] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mat-m[3] = 0 .
        END.
        /**/
        IF item-estab.sald-ini-mob-m[1] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mob-m[1] = 0 .
        END.
        IF item-estab.sald-ini-mob-m[2] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mob-m[2] = 0 .
        END.
        IF item-estab.sald-ini-mob-m[3] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-mob-m[3] = 0 .
        END.
        /**/
        IF item-estab.sald-ini-ggf-m[1] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-ggf-m[1] = 0 .
        END.
        IF item-estab.sald-ini-ggf-m[2] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-ggf-m[2] = 0 .
        END.
        IF item-estab.sald-ini-ggf-m[3] < 0 THEN DO:
            ASSIGN item-estab.sald-ini-ggf-m[3] = 0 .
        END.

    END.
END.


