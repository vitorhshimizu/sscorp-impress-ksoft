/**/

DEF VAR l-ativo     AS LOGICAL NO-UNDO .
DEF VAR i-moeda     AS INT NO-UNDO .
DEF VAR i-po        AS INT NO-UNDO .
DEF VAR dt-po       AS DATE NO-UNDO .

OUTPUT TO VALUE("C:\temp\suppliers.csv") NO-CONVERT .

PUT UNFORM "ID Supplier" .
PUT UNFORM ";CNPJ" .
PUT UNFORM ";Short Name" .
PUT UNFORM ";Full Name" .
PUT UNFORM ";Country" .
PUT UNFORM ";State" .
PUT UNFORM ";City" .
PUT UNFORM ";Active" .
PUT UNFORM ";Currency Code" .
PUT UNFORM ";Last PO" .
PUT UNFORM ";PO Date" .
PUT UNFORM SKIP .

FOR EACH emitente NO-LOCK 
    WHERE emitente.identific = 2 /* Fornecedor */OR 
          emitente.identific = 3 /* Ambos */
    :
    FIND FIRST dist-emitente NO-LOCK OF emitente NO-ERROR .

    ASSIGN l-ativo = YES .
    IF AVAIL dist-emitente AND dist-emitente.idi-sit-fornec = 4 /* Inativo */ THEN DO:
        ASSIGN l-ativo = NO .
    END.

    ASSIGN i-moeda = IF AVAIL dist-emitente THEN dist-emitente.mo-fatur ELSE 0 .
    ASSIGN i-po = 0 .
    ASSIGN dt-po = ? .
    FOR LAST ordem-compra NO-LOCK
        WHERE ordem-compra.cod-emitente = emitente.cod-emitente
        AND   ordem-compra.num-pedido <> 0
        :
        ASSIGN i-moeda = ordem-compra.mo-codigo .
        ASSIGN i-po = ordem-compra.num-pedido .
        FOR FIRST pedido-compr NO-LOCK OF ordem-compra
            :
            ASSIGN dt-po = pedido-compr.data-pedido .
        END.
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
        ';' i-moeda
        ';' i-po
        ';' IF dt-po = ? THEN "" ELSE STRING(dt-po , "99/99/9999")
        SKIP .
END.

OUTPUT CLOSE .



