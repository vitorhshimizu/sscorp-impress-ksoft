/**/

OUTPUT TO VALUE("C:\temp\transportadoras.csv") NO-CONVERT .

PUT UNFORM "ID Supplier" .
PUT UNFORM ";ID Carrier" .
PUT UNFORM ";CNPJ" .
PUT UNFORM ";Short Name" .
PUT UNFORM ";Full Name" .
PUT UNFORM ";Country" .
PUT UNFORM ";State" .
PUT UNFORM ";City" .
PUT UNFORM SKIP .

FOR EACH transporte NO-LOCK
    ,
    FIRST emitente NO-LOCK 
    WHERE emitente.nome-abrev = transporte.nome-abrev
    :
    PUT UNFORMATTED
            emitente.cod-emitente
        ';' transporte.cod-transp
        ';' emitente.cgc
        ';' emitente.nome-abrev
        ';' emitente.nome-emit
        ';' transporte.pais
        ';' transporte.estado
        ';' transporte.cidade
        SKIP .
END.

OUTPUT CLOSE .

