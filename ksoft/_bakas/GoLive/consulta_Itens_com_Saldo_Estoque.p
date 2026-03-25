/*
*/

OUTPUT TO VALUE("C:\temp\itens_saldo_estoque.csv") NO-CONVERT .

PUT UNFORM "Item" .
PUT UNFORM ";GE" .
PUT UNFORM ";Tipo Controle" .
PUT UNFORM ";Est" .
PUT UNFORM ";Dep" .
PUT UNFORM ";Localiza‡Æo" .
PUT UNFORM ";Lote" .
PUT UNFORM ";Refer" .
PUT UNFORM ";Qtd Saldo" .
PUT UNFORM SKIP .

FOR EACH saldo-estoq NO-LOCK
    WHERE saldo-estoq.qtidade-atu > 0
    ,
    FIRST ITEM NO-LOCK OF saldo-estoq
    BY ITEM.ge-codigo
    BY ITEM.it-codigo
    :
    PUT UNFORMATTED
            saldo-estoq.it-codigo
        ';' ITEM.ge-codigo
        ';' ITEM.tipo-contr
        ';' saldo-estoq.cod-estabel
        ';' saldo-estoq.cod-depos
        ';' saldo-estoq.cod-localiz
        ';' saldo-estoq.lote
        ';' saldo-estoq.cod-refer
        ';' saldo-estoq.qtidade-atu
        SKIP .
END.

OUTPUT CLOSE .
