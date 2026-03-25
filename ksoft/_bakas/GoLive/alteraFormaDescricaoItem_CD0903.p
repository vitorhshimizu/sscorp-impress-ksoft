/*
*/

DISABLE TRIGGERS FOR LOAD OF ITEM .
DISABLE TRIGGERS FOR LOAD OF item-dist .

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ind-imp-desc <> 7
    BY ITEM.it-codigo
    :
    IF ITEM.it-codigo MATCHES "*-DD" THEN NEXT . /* Embalagens Pallets */
    
    RUN pi-acompanhar IN h-acomp(ITEM.it-codigo) .

    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN
            ITEM.ind-imp-desc = 7 /* Narrativa Informada */
            .

        FOR FIRST item-dist EXCLUSIVE-LOCK 
            WHERE item-dist.it-codigo = ITEM.it-codigo
            :
            ASSIGN item-dist.log-cop-narrat = YES .
        END.
    END. 
END.

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.




