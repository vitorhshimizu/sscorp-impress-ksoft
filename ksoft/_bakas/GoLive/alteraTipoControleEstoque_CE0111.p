/*
*/

{utp/ut-glob.i}

{cdp/cdcfgdis.i}
{cdp/cdcfgmat.i}
{cdp/cdcfgman.i}

{method/dbotterr.i}

DISABLE TRIGGERS FOR LOAD OF ord-prod .
DISABLE TRIGGERS FOR LOAD OF movto-estoq .

DEF VAR h-acomp AS HANDLE NO-UNDO .
RUN utp/ut-acomp.p PERSISTENT SET h-acomp .
RUN pi-inicializar IN h-acomp("Executando...") .
RUN pi-acompanhar IN h-acomp("Aguarde...") .

DEF VAR i-cont              AS INT NO-UNDO .
DEF VAR c-lote              AS CHAR NO-UNDO .
DEF VAR c-cod-refer         AS CHAR NO-UNDO .
DEF VAR da-dt-vali-lote     AS DATE NO-UNDO .
DEF VAR i-tipo-con-est-old  LIKE ITEM.tipo-con-est NO-UNDO .

/**/
DEF BUFFER b-reservas       FOR reservas.
DEF BUFFER breq-ord         FOR req-ord.
def buffer b-saldo-est      for saldo-estoq.
def buffer b2-saldo-est     for saldo-estoq.
def buffer b-invent         for inventario.
def buffer b2-invent        for inventario.
def buffer b-item-doc-est   for item-doc-est.
def buffer b-rat-lote       for rat-lote.
def buffer b-it-dep-fat     for it-dep-fat.
def buffer b2-it-dep-fat    for it-dep-fat.
def buffer b-fat-ser-lote   for fat-ser-lote.
def buffer b2-fat-ser-lote  for fat-ser-lote.
def buffer b-componente     for componente.
def buffer b-preco-item     for preco-item.

DEF BUFFER b-rat-lote-internac          FOR rat-lote-internac.
DEF BUFFER b2-rat-lote-internac         FOR rat-lote-internac.
DEF BUFFER b-sdo-estoq-internac         FOR sdo-estoq-internac.
DEF BUFFER b2-sdo-estoq-internac        FOR sdo-estoq-internac.
DEF BUFFER b-fatur-ser-lote-internac    FOR fatur-ser-lote-internac.
DEF BUFFER b2-fatur-ser-lote-internac   FOR fatur-ser-lote-internac.
DEF BUFFER b-item-depos-fatur-internac  FOR item-depos-fatur-internac.
DEF BUFFER b2-item-depos-fatur-internac FOR item-depos-fatur-internac.
DEF BUFFER b-saldo-estoq-log            FOR saldo-estoq-log.

DEF VAR lDevSimbConsig     AS LOGICAL NO-UNDO.

DEF VAR hShowMsg       AS HANDLE NO-UNDO.
DEF VAR iErrorSequence AS INT    NO-UNDO.
DEF VAR cErrorDesc     AS CHAR   NO-UNDO.
DEF VAR cErrorHelp     AS CHAR   NO-UNDO.
/**/

/* Campos livres - RMA */
&IF DEFINED(bf_mat_versao_ems) &THEN 
  &IF {&bf_mat_versao_ems} >= 2.05 &THEN
    /* rma-it-dep */
    &GLOBAL-DEFINE dat-valid-lote dat-valid-lote
  &ELSE
    /* rma-it-dep */
    &GLOBAL-DEFINE dat-valid-lote dat-livre-1
  &ENDIF
&ENDIF

FIND FIRST param-global NO-LOCK .

OUTPUT TO VALUE("C:\temp\alteraTipoControleEstoque.csv") NO-CONVERT .

PUT UNFORMATTED
    "ITEM;N Erro;Tipo;SubTipo;Descri‡Æo;Ajuda"
    SKIP .

FOR EACH ITEM NO-LOCK
    WHERE ITEM.tipo-con-est > 1
    :
    RUN pi-acompanhar IN h-acomp("ITEM: " + ITEM.it-codigo) .

    ASSIGN i-tipo-con-est-old = ITEM.tipo-con-est .

    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        FIND CURRENT ITEM EXCLUSIVE-LOCK .
        ASSIGN ITEM.tipo-con-est = 1 /* Serial */ .

        {cep/ce0111.i c-lote c-cod-refer da-dt-vali-lote}
        {cep/ce0111.i3}
        {cep/ce0111.i4 c-cod-refer}

        IF CAN-FIND(FIRST RowErrors) THEN DO:
            FOR EACH RowErrors NO-LOCK
                :
                PUT UNFORMATTED
                        ITEM.it-codigo
                    ';' RowErrors.ErrorNumber 
                    ';' RowErrors.ErrorType
                    ';' RowErrors.ErrorSubType
                    ';' RowErrors.ErrorDescription
                    ';' RowErrors.ErrorHelp
                    SKIP .
            END.
        END.
    END. 
END.

OUTPUT CLOSE .

IF VALID-HANDLE(h-acomp) THEN DO:
    RUN pi-finalizar IN h-acomp .
END.





