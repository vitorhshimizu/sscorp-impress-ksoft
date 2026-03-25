/*
Essa alteracao nao altera os movimentos j  realizados conforme ocorre
ao alterar pela tela padrao.
*/

FOR EACH contabiliza NO-LOCK
    WHERE contabiliza.ct-codigo <> "9110401"
    :
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT contabiliza EXCLUSIVE-LOCK . 
        ASSIGN contabiliza.ct-codigo = "9110401" .
        ASSIGN contabiliza.sc-codigo = "" .
    END.
END.








