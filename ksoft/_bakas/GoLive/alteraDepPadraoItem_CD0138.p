/*
*/

DISABLE TRIGGERS FOR LOAD OF ITEM .
DISABLE TRIGGERS FOR LOAD OF item-uni-estab .

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.deposito-pad <> "DBD"
    BY ITEM.it-codigo
    :
    RUN pi-acompanhar IN h-acomp(ITEM.it-codigo) .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN
            ITEM.deposito-pad = "DBD"
            .
    END. 
END.

FOR EACH item-uni-estab NO-LOCK
    WHERE item-uni-estab.deposito-pad <> "DBD"
    BY item-uni-estab.it-codigo
    :
    RUN pi-acompanhar IN h-acomp(item-uni-estab.cod-estabel + " - " + 
                                 item-uni-estab.it-codigo) .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT item-uni-estab EXCLUSIVE-LOCK .
        ASSIGN
            item-uni-estab.deposito-pad = "DBD"
            .
    END. 
END.

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.









