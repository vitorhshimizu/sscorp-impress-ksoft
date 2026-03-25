/**/

DEF VAR l-ativo     AS LOGICAL NO-UNDO .

OUTPUT TO VALUE("C:\temp\customers.csv") NO-CONVERT .

PUT UNFORM "ID Customer" .
PUT UNFORM ";CNPJ" .
PUT UNFORM ";Short Name" .
PUT UNFORM ";Full Name" .
PUT UNFORM ";Country" .
PUT UNFORM ";State" .
PUT UNFORM ";City" .
PUT UNFORM ";Active" .
PUT UNFORM SKIP .

FOR EACH emitente NO-LOCK 
    WHERE emitente.identific = 1 /* Cliente */OR 
          emitente.identific = 3 /* Ambos */
    :
    ASSIGN l-ativo = YES .
    IF emitente.ind-cre-cli = 4 /* Suspenso */ THEN DO:
        ASSIGN l-ativo = NO .
    END.
    PUT UNFORMATTED
            emitente.cod-emitente
        ';' emitente.cgc
        ';' emitente.nome-abrev
        ';' emitente.nome-emit
        ';' emitente.pais
        ';' emitente.estado
        ';' emitente.cidade
        ';' STRING(l-ativo)
        SKIP .
END.

OUTPUT CLOSE .



