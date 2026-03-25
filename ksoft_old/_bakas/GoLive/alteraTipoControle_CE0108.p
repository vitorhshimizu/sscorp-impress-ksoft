/*
*/
DEF INPUT PARAM p-ge-codigo     LIKE ITEM.ge-codigo NO-UNDO .
DEF INPUT PARAM p-qtd-itens     AS INT NO-UNDO INIT 50 .

/*
DEF VAR p-ge-codigo     LIKE ITEM.ge-codigo NO-UNDO .
DEF VAR p-qtd-itens     AS INT NO-UNDO INIT 50 .

ASSIGN p-ge-codigo = 32 .
ASSIGN p-qtd-itens = 50 .
*/
DEF BUFFER moeda    FOR mgcad.moeda .

{cep/ce1234.i}

def temp-table tt-param
    field tipo          as integer 
    field medio-mat     as dec decimals 4 extent 3 format ">>>,>>>,>>9.9999"
    field medio-mob     as dec decimals 4 extent 3 format ">>>,>>>,>>9.9999"
    field medio-ggf     as dec decimals 4 extent 3 format ">>>,>>>,>>9.9999"
    field ct-conta     like item.ct-codigo 
    field sc-conta     like item.sc-codigo
    field da-inipa-x   like movto-estoq.dt-trans
    field depos-pad    like movto-estoq.cod-depos
    field serie1       like movto-estoq.serie-docto
    field docto1       like movto-estoq.nro-docto
    field it-codigo    like item.it-codigo
    field parametro    as char format "x(30)"
    .

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando") .
RUN pi-acompanhar IN h-acomp("Aguarde") .

DEF VAR i-cont  AS INT NO-UNDO .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.ge-codigo = p-ge-codigo
    AND   ITEM.tipo-contr = 2 /* Total */
    AND   ITEM.cod-obsoleto < 4 /* Totalmente Obsoleto */
    :
    ASSIGN i-cont = i-cont + 1 .
    RUN pi-acompanhar IN h-acomp
        ("GE: " + STRING(ITEM.ge-codigo) + " - ITEM: " + ITEM.it-codigo + " - " + 
         STRING(i-cont) + "/" + STRING(p-qtd-itens) ) 
        .
    /**/
    EMPTY TEMP-TABLE tt-param .
    CREATE tt-param . 
    ASSIGN
        tt-param.tipo       = 4 /* Debito Direto */ 
        tt-param.medio-mat  = 0
        tt-param.medio-mob  = 0
        tt-param.medio-ggf  = 0
        tt-param.ct-conta   = "9110305"
        tt-param.sc-conta   = ""
        tt-param.da-inipa-x = TODAY
        tt-param.depos-pad  = "DBD"
        tt-param.serie1     = "TD"
        tt-param.docto1     = "900K"
        tt-param.it-codigo  = ITEM.it-codigo
        tt-param.parametro  = "D‚bito Direto" 
        .

    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        RUN cep/ce0108a.p(INPUT TABLE tt-param) .
    END.
    IF RETURN-VALUE = "NOK" THEN DO:
        MESSAGE 
            "ERRO alteraTipoControle" SKIP
            ITEM.it-codigo SKIP 
            VIEW-AS ALERT-BOX . 
        LEAVE .
    END.

    IF i-cont >= p-qtd-itens THEN DO:
        LEAVE .
    END.
END.

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.

MESSAGE "Execu‡Æo Finalizada" SKIP i-cont VIEW-AS ALERT-BOX .


