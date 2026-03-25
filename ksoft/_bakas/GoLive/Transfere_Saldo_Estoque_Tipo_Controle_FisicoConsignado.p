/*
*/

{cdp/cdcfgman.i} /* pre-processador */

{utp/ut-glob.i}

{cdp/cd0666.i &1=" " &excludeFrameDefinition="YES"} /* tt-erro */
{cep/ceapi001.i} /* tt-movto */

def new shared var l-erro    as logical init NO             NO-UNDO.

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando") .
RUN pi-acompanhar IN h-acomp("Aguarde") .

DEF BUFFER bf-item FOR ITEM .

DEF VAR i-cont          AS INT NO-UNDO .
DEF VAR p-qtd-itens     AS INT NO-UNDO .

ASSIGN p-qtd-itens = 200 .

OUTPUT TO VALUE("C:\temp\JRA\DIV_Total.csv") NO-CONVERT APPEND .

FOR EACH saldo-estoq NO-LOCK
    WHERE saldo-estoq.qtidade-atu > 0
    ,
    FIRST ITEM NO-LOCK OF saldo-estoq
    /*WHERE ITEM.tipo-contr = 1 /* Fisico */ OR 
          ITEM.tipo-contr = 3 /* Consignado */ */
    WHERE ITEM.tipo-contr = 4 
    BY ITEM.ge-codigo
    BY ITEM.it-codigo
    :
    ASSIGN i-cont = i-cont + 1 .

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

    RUN pi-acompanhar IN h-acomp
        ("GE: " + STRING(ITEM.ge-codigo) + " - ITEM: " + ITEM.it-codigo + " - " + 
         STRING(i-cont) + "/" + STRING(p-qtd-itens) ) 
        .
    /**/
    EMPTY TEMP-TABLE tt-movto .
    EMPTY TEMP-TABLE tt-erro .

    CREATE tt-movto . ASSIGN
        tt-movto.i-sequen               = 10
        tt-movto.cod-versao-integracao  = 1
        tt-movto.cod-prog-orig          = "KSOFT_1"
        tt-movto.usuario                = c-seg-usuario
        tt-movto.dt-trans               = DATE("01/03/2026")
        tt-movto.tipo-trans             = 2 /* Sai */
        tt-movto.esp-docto              = 06 /* DIV */
        tt-movto.cod-estabel            = saldo-estoq.cod-estabel
        tt-movto.cod-depos              = saldo-estoq.cod-depos
        tt-movto.cod-localiz            = saldo-estoq.cod-localiz
        tt-movto.it-codigo              = saldo-estoq.it-codigo
        tt-movto.cod-refer              = saldo-estoq.cod-refer
        tt-movto.lote                   = saldo-estoq.lote
        tt-movto.dt-vali-lote           = saldo-estoq.dt-vali-lote
        tt-movto.quantidade             = saldo-estoq.qtidade-atu
        tt-movto.un                     = ITEM.un
        tt-movto.ct-codigo              = "9110305" /* Transitoria de Estoque */
        tt-movto.sc-codigo              = ""
        tt-movto.serie-docto            = "TD"
        tt-movto.nro-docto              = "900K"
        .

    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        FIND bf-item EXCLUSIVE-LOCK WHERE ROWID(bf-item) = ROWID(ITEM) .
        IF bf-item.tipo-contr = 4 /* DD */ THEN DO:
            ASSIGN bf-item.tipo-contr = 2 /* TOTAL */ .
        END.

        IF bf-item.cod-obsoleto = 4 /* Totalmente Obsoleto */ THEN DO:
            ASSIGN bf-item.cod-obsoleto = 1 /* Ativo */ .
        END.

        FIND FIRST item-uni-estab EXCLUSIVE-LOCK
            WHERE item-uni-estab.it-codigo = saldo-estoq.it-codigo
            AND   item-uni-estab.cod-estabel = saldo-estoq.cod-estabel
            .
        IF item-uni-estab.cod-obsoleto = 4 /* Totalmente Obsoleto */ THEN DO:
            ASSIGN item-uni-estab.cod-obsoleto = 1 /* Ativo */ .
        END.

        RUN cep/ceapi001.p
            (INPUT-OUTPUT TABLE tt-movto ,
             INPUT-OUTPUT TABLE tt-erro ,
             INPUT YES) 
            .

        FOR EACH tt-erro
            WHERE tt-erro.cd-erro = 56847 /* Deposito Terceiros */
            :
            DELETE tt-erro .
        END.

        FIND FIRST tt-erro NO-LOCK NO-ERROR .
        IF AVAIL tt-erro THEN DO:
            UNDO , LEAVE .
        END.
    END.

    IF i-cont >= p-qtd-itens THEN DO:
        LEAVE .
    END.
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.

FIND FIRST tt-erro NO-LOCK NO-ERROR .
IF AVAIL tt-erro THEN DO:
    RUN cdp/cd0666.w (INPUT TABLE tt-erro).
END.


