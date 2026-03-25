/*****************************************************************************
**       Programa: csft125nf.p
**       Data....: 25/03/2024
**       Autor...: Marcos Patricio Sanfelice
**       Objetivo: Gera Nota Fiscal e itens da nota via BOs
**       Vers’o..: 1.00.000 - super
**       OBS.....: 
*******************************************************************************/

&SCOPED-DEFINE program_name         CSIM125
&SCOPED-DEFINE program_description  ""
&SCOPED-DEFINE program_module       CST
&SCOPED-DEFINE program_version      1.00.00.000

{cstp/{&program_name}tt.i}
//{include/i-freeac.i}
{utp/ut-glob.i}

// Parametros
DEFINE INPUT PARAMETER p-nf_numnf LIKE tt-nota-fis.nf_numnf.
DEFINE INPUT PARAMETER TABLE FOR tt-nota-fis.
DEFINE INPUT PARAMETER TABLE FOR tt-it-nota-fis.
DEFINE INPUT PARAMETER TABLE FOR tt-despesa-nf.

DEF VAR h-acomp             AS HANDLE   NO-UNDO.
DEF VAR i-nro-docto         AS CHAR     NO-UNDO FORMAT "X(7)".
DEF VAR i-nro-docto2        AS INT      NO-UNDO. 
DEF VAR i-via_tranporte     AS INT      NO-UNDO.
DEF VAR i-parcela           AS INT      NO-UNDO.

DEF VAR i-QtdItem           AS INT      NO-UNDO.

DEF VAR i-parcela-cex       AS INT      NO-UNDO.
DEF VAR i-parcela-dupli     AS INT      NO-UNDO.
DEF VAR d-vl-dolar          AS DEC      NO-UNDO.
DEF VAR l-new-record        AS LOGICAL  NO-UNDO.
DEF VAR d-tot-vlr-despesa   AS DECIMAL  NO-UNDO.
DEF VAR d-tot-vlr-dupli     AS DECIMAL  NO-UNDO.
DEF VAR cCritica            AS CHAR     NO-UNDO INIT "\\10.3.0.5\OSGT\osgt\temp\criticas_Nota-fiscal.txt".

DEF VAR c-cod-uf            AS CHAR     NO-UNDO. 

DEF VAR d-tot-icms          AS DECIMAL  NO-UNDO.
DEF VAR d-aliquota-icm      AS DECIMAL  NO-UNDO.
DEF VAR c-serie             AS CHAR     NO-UNDO.

DEF VAR h-cdapi995          AS HANDLE  NO-UNDO .
DEF VAR h-boin090           AS HANDLE  NO-UNDO .
DEF VAR h-boin176           AS HANDLE  NO-UNDO .
DEF VAR h-boin092           AS HANDLE  NO-UNDO .
DEF VAR h-bocx090           AS HANDLE  NO-UNDO . 
DEF VAR h-bocx255           AS HANDLE  NO-UNDO.
DEF VAR h-boin813           AS HANDLE  NO-UNDO.
DEF VAR h-boin814           AS HANDLE  NO-UNDO.
DEF VAR h-boin815           AS HANDLE  NO-UNDO.
DEF VAR h-bocx310           AS HANDLE  NO-UNDO.
DEF VAR h-bocx220           AS HANDLE  NO-UNDO.

DEF STREAM s-critica.
DEF VAR c-cod-estabel      LIKE estabelec.cgc NO-UNDO.
define new global shared variable gc-peso-bruto-tot as CHAR no-undo.


/* TEMP-TABLES */
DEF TEMP-TABLE RowErrors NO-UNDO
    FIELD ErrorSequence     AS INT
    FIELD ErrorNumber       AS INT
    FIELD ErrorDescription  AS CHAR FORMAT 'x(100)'
    FIELD ErrorParameters   AS CHAR FORMAT 'x(100)'
    FIELD ErrorType         AS CHAR FORMAT 'x(100)'
    FIELD ErrorHelp         AS CHAR FORMAT 'x(100)'
    FIELD ErrorSubtype      AS CHAR FORMAT 'x(100)'.

DEF TEMP-TABLE RowErrors-aux NO-UNDO LIKE RowErrors .

DEF TEMP-TABLE tt-docum-est NO-UNDO LIKE docum-est
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-docto-estoq-nfe-imp NO-UNDO LIKE docto-estoq-nfe-imp
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-item-docto-estoq-nfe-imp NO-UNDO LIKE item-docto-estoq-nfe-imp
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-rat-docum NO-UNDO LIKE rat-docum
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-item-doc-est NO-UNDO LIKE item-doc-est
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-dupli-apagar NO-UNDO LIKE dupli-apagar
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-dupli-apagar-cex NO-UNDO LIKE dupli-apagar-cex
    FIELD r-rowid AS ROWID.
    
DEF TEMP-TABLE tt-dupli-imp NO-UNDO LIKE dupli-imp
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-despesa-aces NO-UNDO LIKE despesa-aces
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-docum-est-cex NO-UNDO LIKE docum-est-cex
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-versao-Integr NO-UNDO
    FIELD registro              AS INT
    FIELD cod-versao-Integracao AS INT FORMAT "999".

DEF TEMP-TABLE tt-docto-estoq-embal NO-UNDO LIKE docto-estoq-embal 
    FIELD r-rowid AS ROWID.

DEF TEMP-TABLE tt-desp-embarque NO-UNDO LIKE desp-embarque
    FIELD r-rowid AS ROWID.  
  
DEF TEMP-TABLE tt-embarque-imp NO-UNDO LIKE embarque-imp
    FIELD r-rowid AS ROWID.  
  
  
DEF TEMP-TABLE tt-total-item NO-UNDO
    FIELD tot-peso              LIKE docum-est.tot-peso
    FIELD peso-bruto-tot        LIKE docum-est.peso-bruto-tot
    FIELD tot-desconto          LIKE docum-est.tot-desconto
    FIELD despesa-nota          LIKE docum-est.despesa-nota
    FIELD valor-mercad          LIKE docum-est.valor-mercad
    FIELD base-ipi              LIKE docum-est.base-ipi
    FIELD valor-ipi             AS DECIMAL //LIKE item-doc-est.valor-ipi
    FIELD base-icm              LIKE docum-est.base-icm
    FIELD valor-icm             AS DECIMAL //LIKE item-doc-est.valor-icm
    FIELD base-iss              LIKE docum-est.base-iss
    FIELD valor-iss             AS DECIMAL //LIKE item-doc-est.valor-iss
    FIELD base-subs             LIKE docum-est.base-subs
    FIELD valor-subs            AS DECIMAL
    FIELD base-icm-complem      AS DECIMAL
    FIELD icm-complem           LIKE docum-est.icm-complem
    FIELD fundo-pobreza         AS DECIMAL
    FIELD ipi-outras            LIKE docum-est.ipi-outras
    FIELD valor-pis             AS DECIMAL //LIKE item-doc-est.valor-pis
    FIELD valor-cofins          AS DECIMAL
    FIELD total-pis-subst       AS DECIMAL
    FIELD total-cofins-subs     AS DECIMAL
    FIELD total-icms-diferim    AS DECIMAL
    FIELD valor-frete           LIKE docum-est.valor-frete
    FIELD valor-pedagio         AS DECIMAL
    FIELD valor-icm-trib        AS DECIMAL
    FIELD de-tot-valor-calc     LIKE docum-est.tot-valor.
 
OUTPUT STREAM s-critica TO VALUE (cCritica) NO-CONVERT.
PUT STREAM s-critica 
    FILL("-",200) FORMAT "x(200)" SKIP
    "NF"            AT 01
    "Proc.Imp"      AT 10
    "Rotina"        AT 30
    "Num.Erro"      AT 50
    "Descri»’o"     AT 60
    "Parametros"    AT 120
    "Help"          AT 140
    SKIP
    FILL("-",200) FORMAT "x(200)" SKIP
    SKIP.
 
 /* FUNCTIONS */

 
 FUNCTION fnData RETURN CHAR //DATE
    (pData AS CHAR):

    DEF VAR cData AS CHAR NO-UNDO.

    IF  pData = "" THEN RETURN ?.

    ASSIGN cData = SUBSTRING(pData, 7 ,2) + "/"
                 + SUBSTRING(pData, 5 ,2) + "/"
                 + SUBSTRING(pData, 1 ,4).

    RETURN cData.

END FUNCTION.


FUNCTION fu-trans-dec RETURNS DECIMAL 
     (INPUT p-var AS CHARACTER):  
     
     DEF VAR c-var AS CHAR.
     
     ASSIGN c-var = REPLACE(p-var,".","").
     
     RETURN DEC(p-var). 
    
    // RETURN DEC(c-var). 
END FUNCTION.


FUNCTION PreencherComZeros RETURNS CHARACTER
    (INPUT valor AS INTEGER):
    
    DEF VAR valorFormatado AS CHARACTER NO-UNDO.
    DEF VAR resultado AS CHARACTER NO-UNDO.

    valorFormatado = STRING(valor, "9999999").
    
    resultado = FILL("0", 7 - LENGTH(valorFormatado)) + valorFormatado.
    
    RETURN resultado.
END FUNCTION.


RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
RUN pi-inicializar IN h-acomp (INPUT "Processando..."). 

RUN pi-integra-nfe.

RUN pi-finalizar IN h-acomp.  
OUTPUT STREAM s-critica CLOSE.

RETURN "OK":U .

PROCEDURE pi-integra-nfe:

    RUN pi-acompanhar IN h-acomp (INPUT "Preparando Nota Fiscal").
    
    CREATE tt-versao-integr . ASSIGN 
           tt-versao-integr.registro              = 0
           tt-versao-integr.cod-versao-integracao = 004.

    DEF BUFFER bf-item-fornec FOR item-fornec .

    DEF VAR iSeq            AS INT     NO-UNDO.
    DEF VAR cCodDeposPadrao AS CHAR    NO-UNDO.
    DEF VAR d-tot-nota      AS DECIMAL NO-UNDO.

       FOR EACH tt-nota-fis:

     // CONSISTE EERROS DE IMPORTA€ÇO QUANDO HA ERRO EM UMA DAS NOTAS NO ARQUIVO
            
     
      FOR EACH tt-it-nota-fis WHERE tt-it-nota-fis.nf_numnf = tt-nota-fis.nf_numnf
          :
          
            FIND FIRST ITEM 
                 WHERE ITEM.it-codigo = tt-it-nota-fis.nf_ite_codprod
                NO-LOCK NO-ERROR.
            IF NOT AVAIL ITEM THEN
            DO:
            
                CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Item n’o encontrado " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorParameters   = tt-nota-fis.nf_numnf
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                    
                    
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take1"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                  
            END.
                         
            FIND FIRST ordem-compra 
                WHERE ordem-compra.numero-ordem = INT(tt-it-nota-fis.nf_ite-ordem)  AND
                      ordem-compra.it-codigo    = tt-it-nota-fis.nf_ite_codprod
                NO-LOCK NO-ERROR.                   
              IF NOT AVAIL ordem-compra THEN 
              DO:         
            
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "OC nao encontrada na NF: " 
                        RowErrors.ErrorParameters   = tt-nota-fis.nf_numnf
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                    
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take2"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                     
                    
                END.   
                
                FIND FIRST emitente NO-LOCK
                     WHERE emitente.cod-emitente = INT(tt-nota-fis.nf_cod_fornec) NO-ERROR.

                FIND FIRST pedido-compr 
                     WHERE pedido-compr.num-pedido   = ordem-compra.num-pedido
                       AND pedido-compr.cod-emitente = emitente.cod-emitente
                NO-LOCK NO-ERROR.
                IF NOT AVAIL pedido-compr THEN 
                DO:
                   CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Pedido de Compra n’o encontrado "
                        RowErrors.ErrorParameters   = tt-nota-fis.nf_numnf
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                    
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take3"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                   
                END.
                    
                FIND FIRST cond-pagto 
                     WHERE cond-pagto.cod-cond-pag = pedido-compr.cod-cond-pag 
                NO-LOCK NO-ERROR.
                IF NOT AVAIL cond-pagto THEN
                DO:
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Condi»’o de Pagto n’o encontrado " 
                        RowErrors.ErrorParameters   = tt-nota-fis.nf_numnf
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                    
                    
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take4"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                  
                END.
            END.
   END.
   
   FOR EACH RowErrors:
     
        FOR EACH tt-nota-fis WHERE tt-nota-fis.nf_numnf = RowErrors.ErrorParameters:
            
            DELETE tt-nota-fis.
            
        END.
   END.
    
    
    
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE:  
        
        FOR EACH tt-nota-fis 
           WHERE tt-nota-fis.nf_numnf = p-nf_numnf
         :
              
           
            FIND FIRST estabelec WHERE estabelec.cgc = tt-nota-fis.cnpj_entrada NO-ERROR.
            IF AVAILABLE estabelec THEN ASSIGN c-cod-estabel =  estabelec.cod-estabel.
            
             IF c-cod-estabel = "101" THEN ASSIGN c-serie = "2".
             IF c-cod-estabel = "111" THEN ASSIGN c-serie = "1".
           
           
           EMPTY TEMP-TABLE RowErrors.
            EMPTY TEMP-TABLE RowErrors-aux.
            EMPTY TEMP-TABLE tt-docum-est.
            EMPTY TEMP-TABLE tt-docto-estoq-nfe-imp.
            EMPTY TEMP-TABLE tt-item-docto-estoq-nfe-imp.
            EMPTY TEMP-TABLE tt-rat-docum.
            EMPTY TEMP-TABLE tt-item-doc-est.
            EMPTY TEMP-TABLE tt-dupli-apagar.
            EMPTY TEMP-TABLE tt-dupli-apagar-cex.
            EMPTY TEMP-TABLE tt-dupli-imp.
            EMPTY TEMP-TABLE tt-despesa-aces.
            EMPTY TEMP-TABLE tt-docum-est-cex.
            EMPTY TEMP-TABLE tt-versao-Integr.
            EMPTY TEMP-TABLE tt-docto-estoq-embal.
            EMPTY TEMP-TABLE tt-total-item.
            EMPTY TEMP-TABLE tt-desp-embarque.
                    
            RUN inbo/boin090.p PERSISTENT SET h-boin090 .
            RUN openQueryStatic IN h-boin090(INPUT "Main") .

            RUN inbo/boin176.p PERSISTENT SET h-boin176 .
            RUN openQueryStatic IN h-boin176(INPUT "Main") .

            RUN inbo/boin092.p PERSISTENT SET h-boin092 .
            RUN openQueryStatic IN h-boin092(INPUT "Main") .
            
            RUN inbo/boin0813.p PERSISTENT SET h-boin813 .
            RUN openQueryStatic IN h-boin813(INPUT "Main") .
            
            RUN inbo/boin0814.p PERSISTENT SET h-boin814.
            RUN openQueryStatic IN h-boin814(INPUT "Main") .

            RUN inbo/boin0815.p PERSISTENT SET h-boin815 .
            RUN openQueryStatic IN h-boin815(INPUT "Main") . 
            
            RUN cxbo/bocx090.p PERSISTENT SET h-bocx090 .
            RUN openQueryStatic IN h-bocx090(INPUT "Main") .

            RUN cxbo/bocx255.p PERSISTENT SET h-bocx255 .
            RUN openQueryStatic IN h-bocx255(INPUT "Main") .
            
            RUN cxbo/bocx310.p PERSISTENT SET h-bocx310.
            RUN cxbo/bocx220.p PERSISTENT SET h-bocx220.
            
            
            RUN cdp/cdapi995.p PERSISTENT SET h-cdapi995 .
                
            ASSIGN 
                cCodDeposPadrao   = "10" 
                i-parcela         = 0
                d-tot-vlr-despesa = 0
                iSeq              = 0
                d-tot-icms        = 0. 
                
            ASSIGN i-nro-docto = PreencherComZeros(INT(tt-nota-fis.nf_numnf)).
             
               ASSIGN tt-nota-fis.nf_pesoli           = REPLACE(tt-nota-fis.nf_pesoli, ".", ",")
                   tt-nota-fis.nf_pesobr              = REPLACE(tt-nota-fis.nf_pesobr, "." , ",") 
                   tt-nota-fis.nf_vrfrete             = REPLACE(tt-nota-fis.nf_vrfrete, "." , ",")
                   tt-nota-fis.nf_vrseguro            = REPLACE(tt-nota-fis.nf_vrseguro, "." , ",")
                   tt-nota-fis.nf_vrdespesa           = REPLACE(tt-nota-fis.nf_vrdespesa, ".", ",") 
                   tt-nota-fis.nf_vrmerca             = REPLACE(tt-nota-fis.nf_vrmerca, "." , ",")
                   tt-nota-fis.nf_vripi               = REPLACE(tt-nota-fis.nf_vripi, "." , ",")   
                   tt-nota-fis.nf_vrtotal             = REPLACE(tt-nota-fis.nf_vrtotal, ".", ",")
                   tt-nota-fis.nf_baseicms            = REPLACE(tt-nota-fis.nf_baseicms, "." , ",")
                   tt-nota-fis.nf_baseipi             = REPLACE(tt-nota-fis.nf_baseipi, "." , ",")
                   tt-nota-fis.nf_vricms              = REPLACE(tt-nota-fis.nf_vricms, ".", ",") 
                   tt-nota-fis.nf_vrt_cofins          = REPLACE(tt-nota-fis.nf_vrt_cofins, ".",",")
                   tt-nota-fis.nf_vrt_pis             = REPLACE(tt-nota-fis.nf_vrt_pis,".",",")    
                   tt-nota-fis.nf_vrt_cofins          = REPLACE(tt-nota-fis.nf_vrt_cofins, ".",",")
                   tt-nota-fis.nf_vrseguro            = REPLACE(tt-nota-fis.nf_vrseguro, "." , ",")
                   tt-nota-fis.nf_basecofins          = REPLACE(tt-nota-fis.nf_basecofins,".",",")
                   tt-nota-fis.nf_basepis             = REPLACE(tt-nota-fis.nf_basepis,".", ",")
                   tt-nota-fis.nf_ii                  = REPLACE(tt-nota-fis.nf_ii, "." , ",") 
                   tt-nota-fis.nf_pesoli              = REPLACE(tt-nota-fis.nf_pesoli, ".",",")
                   tt-nota-fis.nf_nat_oper            = tt-nota-fis.nf_nat_oper + "00"  
                   tt-nota-fis.peso-bruto-tot         = REPLACE(tt-nota-fis.peso-bruto-tot, "." , ",")
                   tt-nota-fis.nf_qtde_volume         = REPLACE(tt-nota-fis.nf_qtde_volume, "." , ",")
                   tt-nota-fis.nf_fob_mob             = REPLACE(tt-nota-fis.nf_fob_mob, "." , ",")
                   tt-nota-fis.nf_taxa_fob            = REPLACE(tt-nota-fis.nf_taxa_fob, "." , ",")
                  .
                   
                    
            FIND FIRST docum-est WHERE
                       docum-est.cod-emitente = INT(tt-nota-fis.nf_cod_fornec)
                   AND docum-est.serie-docto  = c-serie
                   AND docum-est.nro-docto    = STRING(i-nro-docto,"9999999")
                   AND docum-est.nat-operacao = tt-nota-fis.nf_nat_oper 
            NO-LOCK NO-ERROR.
            IF AVAILABLE docum-est THEN 
            DO:
                CREATE RowErrors.
                ASSIGN 
                    RowErrors.ErrorNumber       = 0
                    RowErrors.ErrorDescription  = "Documento jÿ existe"
                    RowErrors.ErrorParameters   = ""
                    RowErrors.ErrorHelp         = "cod.emitente: " + tt-nota-fis.nf_cod_fornec + " Nat." + tt-nota-fis.nf_nat_oper
                    RowErrors.ErrorSubType      = "ERROR".
                    
                PUT STREAM s-critica UNFORMATTED
                    STRING(i-nro-docto,"9999999")   AT 01
                    tt-nota-fis.nf_cod_processo     AT 10
                    "boin090-create-take5"                AT 30
                    RowErrors.ErrorNumber           AT 50
                    RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                    RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                    RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                NEXT. //UNDO TRA1, LEAVE TRA1.                
            END.
       
            // CARREGA AS DESPESAS DA NOTA
            FOR EACH tt-despesa-nf NO-LOCK
               WHERE tt-despesa-nf.nf_numnf = tt-nota-fis.nf_numnf :
                
                IF INT(tt-despesa-nf.id_despesa_erp) = 67 THEN NEXT. //IPI
                
                ASSIGN tt-despesa-nf.valor_despesa = REPLACE(tt-despesa-nf.valor_despesa,"." , ",").

                FIND FIRST emitente NO-LOCK
                     WHERE emitente.cod-emitente = INT(tt-despesa-nf.credor) NO-ERROR.

                IF AVAILABLE emitente THEN DO:
                    ASSIGN d-tot-vlr-despesa = d-tot-vlr-despesa + fu-trans-dec(tt-despesa-nf.valor_despesa).
                END.
            END.
              
            CASE tt-nota-fis.nf_viatra:
                WHEN "R" THEN ASSIGN i-via_tranporte = 1.
                WHEN "A" THEN ASSIGN i-via_tranporte = 2.
                WHEN "M" THEN ASSIGN i-via_tranporte = 3.
                WHEN "F" THEN ASSIGN i-via_tranporte = 4.
                WHEN "O" THEN ASSIGN i-via_tranporte = 8.
            END CASE.
                 
             
            FIND FIRST transporte WHERE transporte.cgc = tt-nota-fis.cnpj-transp-local NO-ERROR.
           
            EMPTY TEMP-TABLE tt-docum-est.
            CREATE tt-docum-est. 
            ASSIGN tt-docum-est.cod-emitente   = INT(tt-nota-fis.nf_cod_fornec)
                   tt-docum-est.serie-docto    = c-serie
                   tt-docum-est.nro-docto      = STRING(i-nro-docto,"9999999")
                   tt-docum-est.nat-operacao   = tt-nota-fis.nf_nat_oper
                   tt-docum-est.cod-observa    = 2 //1 /* Industria */
                   tt-docum-est.cod-estabel    = c-cod-estabel  // PEGAR O ESTABELECIMENTO PELO CNPJ DO ARQUIVO
                   tt-docum-est.dt-emissao     = TODAY
                   tt-docum-est.dt-trans       = TODAY
                   tt-docum-est.embarque       = tt-nota-fis.nf_cod_processo //STRING(i-nro-docto,"9999999") //tt-nota-fis.nf_embarque
                   tt-docum-est.nome-transp    = transporte.nome-abrev
                   OVERLAY(tt-docum-est.char-1,1,11)  =  STRING(i-nro-docto,"9999999")
                   .
            
            RUN emptyRowErrors IN h-boin090 .
            RUN setRecord IN h-boin090(INPUT TABLE tt-docum-est).
            RUN createRecord IN h-boin090.
            RUN getRowErrors IN h-boin090(OUTPUT TABLE RowErrors) .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
            DO:
                FOR EACH RowErrors:
                    PUT STREAM s-critica UNFORMATTED                    
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take6 "         AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                END.
                NEXT. //UNDO TRA1, LEAVE TRA1.
            END.
             
            RUN getRecord IN h-boin090(OUTPUT TABLE tt-docum-est) .
            FIND FIRST tt-docum-est NO-ERROR.
            
             
             ASSIGN           
               tt-docum-est.cod-observa     = 1 //2  
               tt-docum-est.despesa-nota   = d-tot-vlr-despesa //fu-trans-dec(tt-nota-fis.nf_vrdespesa) 
               tt-docum-est.valor-outras   = d-tot-vlr-despesa -  //d-tot-vlr-despesa
                                             fu-trans-dec(tt-nota-fis.nf_vrfrete) - 
                                             fu-trans-dec(tt-nota-fis.nf_vrseguro)
               tt-docum-est.valor-frete      = fu-trans-dec(tt-nota-fis.nf_vrfrete)                       
               tt-docum-est.valor-seguro     = fu-trans-dec(tt-nota-fis.nf_vrseguro)                       
               tt-docum-est.valor-mercad     = fu-trans-dec(tt-nota-fis.nf_vrmerca)
               tt-docum-est.ct-transit       = "90000013" /* TRANSIT…RIA DE IMPORTA°€O*/
               tt-docum-est.esp-docto        = 21 /* NFE */
               tt-docum-est.tipo-docto       = 1 /* Entrada */
               tt-docum-est.observacao       = tt-nota-fis.nf_observacao 
               tt-docum-est.uf               = "EX"  
               tt-docum-est.tot-peso         = fu-trans-dec(tt-nota-fis.nf_pesoli)
               tt-docum-est.dec-2            = tt-docum-est.valor-mercad
               gc-peso-bruto-tot =  STRING(fu-trans-dec(tt-nota-fis.nf_pesoli)).
               //tt-docum-est.peso-bruto-tot   = fu-trans-dec(tt-nota-fis.peso-bruto-tot)
               //OVERLAY(tt-docum-est.char-1,157,17) = string(fu-trans-dec(tt-nota-fis.peso-bruto-tot))

            RUN emptyRowErrors IN h-boin090.           
            RUN setRecord IN h-boin090(INPUT TABLE tt-docum-est).
            RUN UpdateRecord IN h-boin090 .
            RUN getRowErrors IN h-boin090(OUTPUT TABLE RowErrors) .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
            DO: 
               FOR EACH RowErrors:
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 09
                        "boin090-update"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"  AT 80
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140
                        .
                END.
              UNDO TRA1, LEAVE TRA1.
            END.
            
          // Itens  
       
            FOR EACH tt-it-nota-fis 
               WHERE tt-it-nota-fis.nf_numnf = tt-nota-fis.nf_numnf
                    :  
               ASSIGN tt-it-nota-fis.nf_ite_qtde         = REPLACE(tt-it-nota-fis.nf_ite_qtde,'.',',')
                       tt-it-nota-fis.nf_ite_prtot        = REPLACE(tt-it-nota-fis.nf_ite_prtot, ".", ",") 
                       tt-it-nota-fis.nf_ite_vrtotal_nf   = REPLACE(tt-it-nota-fis.nf_ite_vrtotal_nf, "." , ",")
                       tt-it-nota-fis.nf_ite_vlr_item     = REPLACE(tt-it-nota-fis.nf_ite_vlr_item, ".", ",")
                       tt-it-nota-fis.nf_ite_qtde         = REPLACE(tt-it-nota-fis.nf_ite_qtde, ".", ",")
                       tt-it-nota-fis.nf_ite_peso_li      = REPLACE(tt-it-nota-fis.nf_ite_peso_li, "." , ",") 
                       tt-it-nota-fis.nf_ite_vrdespesa    = REPLACE(tt-it-nota-fis.nf_ite_vrdespesa, ".", ",") 
                       tt-it-nota-fis.nf_ite_baseipi      = REPLACE(tt-it-nota-fis.nf_ite_baseipi , ".", ",")
                       tt-it-nota-fis.nf_ite_aliq_icms_st = REPLACE(tt-it-nota-fis.nf_ite_aliq_icms_st, "." , ",") 
                       tt-it-nota-fis.nf_ite_baseicms     = REPLACE(tt-it-nota-fis.nf_ite_baseicms, "." , ",")
                       tt-it-nota-fis.nf_ite_vricms       = REPLACE(tt-it-nota-fis.nf_ite_vricms , ".", ",")
                       tt-it-nota-fis.nf_ite_prunit       = REPLACE(tt-it-nota-fis.nf_ite_prunit, ".",",")
                       tt-it-nota-fis.nf_ite_vripi        = REPLACE(tt-it-nota-fis.nf_ite_vripi, ".", ",")
                       tt-it-nota-fis.nf_ite_peripi       = REPLACE(tt-it-nota-fis.nf_ite_peripi, "." , ",")
                       tt-it-nota-fis.nf_ite_pericms      = REPLACE(tt-it-nota-fis.nf_ite_pericms, "." , ",")
                       tt-it-nota-fis.nf_ite_aliq_cofins  = REPLACE(tt-it-nota-fis.nf_ite_aliq_cofins, "." , ",")
                       tt-it-nota-fis.nf_ite_aliq_pis     = REPLACE(tt-it-nota-fis.nf_ite_aliq_pis, "." , ",")
                       tt-it-nota-fis.nf_ite_prtot        = REPLACE(tt-it-nota-fis.nf_ite_vrtotal_nf, "." , ",")
                       tt-it-nota-fis.nf_ite_vrpis        = REPLACE(tt-it-nota-fis.nf_ite_vrpis,"." , ",")
                       tt-it-nota-fis.nf_ite_basepis      = REPLACE(tt-it-nota-fis.nf_ite_basepis,"." , ",")
                       tt-it-nota-fis.nf_ite_vrcofins     = REPLACE(tt-it-nota-fis.nf_ite_vrcofins,"." , ",")
                       tt-it-nota-fis.nf_ite_basecofins   = REPLACE(tt-it-nota-fis.nf_ite_basecofins,"." , ",")
                       tt-it-nota-fis.nf_ite_nm_adicao	   = REPLACE(tt-it-nota-fis.nf_ite_nm_adicao,"." , ",")
                       tt-it-nota-fis.nf_ite_seq_it_adicao = REPLACE(tt-it-nota-fis.nf_ite_seq_it_adicao,"." , ",")
                       tt-it-nota-fis.nf_ite_codprod        = TRIM(tt-it-nota-fis.nf_ite_codprod)
                       tt-it-nota-fis.nf_ite_vl_frete_rateado = REPLACE(tt-it-nota-fis.nf_ite_vl_frete_rateado,"." , ",")
                       tt-it-nota-fis.nf_ite_vrii             = REPLACE(tt-it-nota-fis.nf_ite_vrii,"." , ",")
                       
                       .
                FIND FIRST ITEM 
                     WHERE ITEM.it-codigo = tt-it-nota-fis.nf_ite_codprod
                NO-LOCK NO-ERROR.
                IF NOT AVAIL ITEM THEN
                DO:
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Item n’o encontrado " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorParameters   = ""
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                        
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-take7"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    UNDO TRA1, LEAVE TRA1.
                END.
                         
                FIND FIRST ordem-compra 
                     WHERE ordem-compra.numero-ordem = INT(tt-it-nota-fis.nf_ite-ordem)  AND
                           ordem-compra.it-codigo    = tt-it-nota-fis.nf_ite_codprod
                NO-LOCK NO-ERROR.                   
                IF NOT AVAIL ordem-compra THEN 
                DO:         
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "OC n’o encontrada: " + STRING(tt-it-nota-fis.nf_ite-ordem)
                        RowErrors.ErrorParameters   = ""
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                        
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-ordem"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    UNDO TRA1, LEAVE TRA1.                
                END.   
                
                FIND FIRST pedido-compr 
                     WHERE pedido-compr.num-pedido   = ordem-compra.num-pedido
                       AND pedido-compr.cod-emitente = tt-docum-est.cod-emitente
                NO-LOCK NO-ERROR.
                IF NOT AVAIL pedido-compr THEN 
                DO:
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Pedido de Compra n’o encontrado " + STRING(ordem-compra.num-pedido)
                        RowErrors.ErrorParameters   = ""
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                        
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-pedido"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    UNDO TRA1, LEAVE TRA1.                
                END.
                    
                FIND FIRST cond-pagto 
                     WHERE cond-pagto.cod-cond-pag = pedido-compr.cod-cond-pag 
                NO-LOCK NO-ERROR.
                IF NOT AVAIL cond-pagto THEN
                DO:
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Condi»’o de Pagto n’o encontrado " + STRING(pedido-compr.cod-cond-pag)
                        RowErrors.ErrorParameters   = ""
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                        
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-cond-pagto"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                  UNDO TRA1, LEAVE TRA1.
                END.
                 
                FIND FIRST prazo-compra 
                     WHERE prazo-compra.numero-ordem = ordem-compra.numero-ordem
                NO-LOCK NO-ERROR .                    
                IF NOT AVAIL prazo-compra THEN 
                DO:
                    CREATE RowErrors.
                    ASSIGN 
                        RowErrors.ErrorNumber       = 0
                        RowErrors.ErrorDescription  = "Prazo Compra n’o encontrado " + STRING(ordem-compra.numero-ordem)
                        RowErrors.ErrorParameters   = ""
                        RowErrors.ErrorHelp         = "Item: " + tt-it-nota-fis.nf_ite_codprod
                        RowErrors.ErrorSubType      = "ERROR".
                        
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin090-create-prazo-compra"   AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    UNDO TRA1, LEAVE TRA1.
                END. 
                    
                ASSIGN iSeq = iSeq + 1 . 
             
                EMPTY TEMP-TABLE tt-item-doc-est.
                EMPTY TEMP-TABLE RowErrors-aux.                
                
                CREATE tt-item-doc-est . 
                ASSIGN tt-item-doc-est.serie-docto             = c-serie
                       tt-item-doc-est.sequencia               = iSeq
                       tt-item-doc-est.it-codigo               = ITEM.it-codigo
                       tt-item-doc-est.nro-docto               = tt-docum-est.nro-docto //STRING(i-nro-docto,"9999999")
                       tt-item-doc-est.cod-emitente            = tt-docum-est.cod-emitente
                       tt-item-doc-est.nat-operacao            = tt-docum-est.nat-operacao
                       tt-item-doc-est.qt-do-forn              = tt-item-doc-est.quantidade
                       tt-item-doc-est.quantidade              = fu-trans-dec(tt-it-nota-fis.nf_ite_qtde)
                       tt-item-doc-est.class-fiscal            = ITEM.class-fiscal
                       tt-item-doc-est.un                      = ITEM.un
                       tt-item-doc-est.preco-unit              = fu-trans-dec(tt-it-nota-fis.nf_ite_prunit)
                       tt-item-doc-est.valor-ipi               = fu-trans-dec(tt-it-nota-fis.nf_ite_vripi)
                       tt-item-doc-est.narrativa               = "Nota Fiscal OSGT"
                       tt-item-doc-est.peso-liquido            = fu-trans-dec(tt-it-nota-fis.nf_ite_peso_li)
                       tt-item-doc-est.peso-liquido-item       = fu-trans-dec(tt-it-nota-fis.nf_ite_peso_li)
                       tt-item-doc-est.peso-bruto-item         = fu-trans-dec(tt-it-nota-fis.nf_ite_peso_li) // fu-trans-dec(tt-nota-fis.nf_pesobr) 29/08/2025
                       tt-item-doc-est.num-pedido              = ordem-compra.num-pedido
                       tt-item-doc-est.numero-ordem            = ordem-compra.numero-ordem
                       tt-item-doc-est.parcela                 = prazo-compra.parcela
                       tt-item-doc-est.preco-total             = fu-trans-dec(tt-it-nota-fis.nf_ite_qtde)   *
                                                                 fu-trans-dec(tt-it-nota-fis.nf_ite_prunit) 
                       tt-item-doc-est.val-aliq-pis            = fu-trans-dec(tt-it-nota-fis.nf_ite_aliq_pis)
                       tt-item-doc-est.vl-imp-impor            = fu-trans-dec(tt-it-nota-fis.nf_ite_vrii)
                       .
                     
                   
                IF ITEM.tipo-contr = 4 /* Debito Direto / Improdutivo */ THEN 
                DO:
                    ASSIGN tt-item-doc-est.ct-codigo = ITEM.ct-codigo 
                           tt-item-doc-est.sc-codigo = ITEM.sc-codigo.
                END.
                
                RUN emptyRowErrors IN h-boin176 .
                RUN setRecord IN h-boin176(INPUT TABLE tt-item-doc-est) .
                RUN createRecord IN h-boin176.
                RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors-aux) .
                            
                IF CAN-FIND(FIRST RowErrors-aux 
                            WHERE RowErrors-aux.ErrorSubType = "ERROR") THEN 
                DO:
                    FOR EACH RowErrors-aux NO-LOCK
                       WHERE RowErrors-aux.ErrorSubType = "ERROR":
                        CREATE RowErrors . 
                        BUFFER-COPY RowErrors-aux TO RowErrors .
                        ASSIGN RowErrors.ErrorHelp = "Item: " + tt-item-doc-est.it-codigo + " " + TRIM(RowErrors.ErrorHelp).
                    END.
                  FOR EACH RowErrors:
                        PUT STREAM s-critica UNFORMATTED
                            STRING(i-nro-docto,"9999999")   AT 01
                            tt-nota-fis.nf_cod_processo     AT 10
                            "boin176-create-take8"                AT 30
                            RowErrors.ErrorNumber           AT 50
                            RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                            RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                            RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    END.
                   UNDO TRA1, LEAVE TRA1.
                END.
                    
                IF LOG-MANAGER:LOGFILE-NAME <> ? THEN 
                DO:
                    LOG-MANAGER:WRITE-MESSAGE("bojrx211 - pi-integrar-nfe - TAKE003") .
                    LOG-MANAGER:WRITE-MESSAGE("Item: " + ITEM.it-codigo) .
                END.    
                    
                RUN getRecord IN h-boin176(OUTPUT TABLE tt-item-doc-est) .
                 
                IF fu-trans-dec(tt-it-nota-fis.nf_ite_vricms) <> 0   THEN
                DO:
                    ASSIGN d-aliquota-icm = (fu-trans-dec(tt-it-nota-fis.nf_ite_vricms) / fu-trans-dec(tt-it-nota-fis.nf_ite_baseicms)) * 100.
                       
                END.
                
                FIND FIRST tt-item-doc-est EXCLUSIVE-LOCK.
                ASSIGN tt-item-doc-est.idi-tributac-pis        = 1
                       tt-item-doc-est.idi-tributac-cofins     = 1
                       tt-item-doc-est.cd-trib-ipi             = 1
                       tt-item-doc-est.cd-trib-ICM             = 1
                       tt-item-doc-est.num-sit-trib-icms       = 151
                       OVERLAY(tt-item-doc-est.char-2,502,3)   = "151"    
                       tt-item-doc-est.aliquota-ipi            = fu-trans-dec(tt-it-nota-fis.nf_ite_peripi)
                       tt-item-doc-est.base-ipi                = fu-trans-dec(tt-it-nota-fis.nf_ite_baseipi)
                       tt-item-doc-est.valor-ipi               = fu-trans-dec(tt-it-nota-fis.nf_ite_vripi)
                       tt-item-doc-est.aliquota-icm            = d-aliquota-icm
                       tt-item-doc-est.base-icm                = fu-trans-dec(tt-it-nota-fis.nf_ite_baseicms)
                       tt-item-doc-est.valor-icm               = fu-trans-dec(tt-it-nota-fis.nf_ite_vricms)
                       tt-item-doc-est.val-aliq-cofins         = fu-trans-dec(tt-it-nota-fis.nf_ite_aliq_cofins)
                       tt-item-doc-est.val-base-calc-cofins    = fu-trans-dec(tt-it-nota-fis.nf_ite_basecofins)
                       tt-item-doc-est.base-pis                = fu-trans-dec(tt-it-nota-fis.nf_ite_basepis)
                       tt-item-doc-est.valor-pis               = fu-trans-dec(tt-it-nota-fis.nf_ite_basepis) * (fu-trans-dec(tt-it-nota-fis.nf_ite_aliq_pis) / 100)
                       tt-item-doc-est.val-cofins              = fu-trans-dec(tt-it-nota-fis.nf_ite_basecofins) * (fu-trans-dec(tt-it-nota-fis.nf_ite_aliq_cofins) / 100)   //fu-trans-dec(tt-it-nota-fis.nf_ite_vrcofins)
                       .

                ASSIGN d-tot-icms = d-tot-icms + fu-trans-dec(tt-it-nota-fis.nf_ite_vricms).
                
                IF tt-item-doc-est.base-pis < tt-item-doc-est.preco-total[1] THEN DO:
                    ASSIGN tt-item-doc-est.idi-tributac-pis = 4 /* Reduzida */ .
                END.
                IF tt-item-doc-est.val-base-calc-cofins < tt-item-doc-est.preco-total[1] THEN DO:
                    ASSIGN tt-item-doc-est.idi-tributac-cofins = 4 /* Reduzida */ .
                END.

                RUN emptyRowErrors IN h-boin176 .
                RUN setRecord IN h-boin176(INPUT TABLE tt-item-doc-est) .
                RUN setAliquotaPIS IN h-boin176(INPUT tt-item-doc-est.val-aliq-pis) .
                RUN setAliquotaCOFINS IN h-boin176(INPUT tt-item-doc-est.val-aliq-cofins) .

                    /* Grava aliquotas PIS e COFINS */
                RUN grava-aliquotas IN h-cdapi995 
                        (INPUT "item-doc-est",
                         INPUT tt-item-doc-est.serie-docto + "/" + 
                               tt-item-doc-est.nro-docto + "/" + 
                               STRING(tt-item-doc-est.cod-emitente) + "/" + 
                               tt-item-doc-est.nat-operacao + "/" + 
                               STRING(tt-item-doc-est.sequencia) ,
                         INPUT tt-item-doc-est.val-aliq-pis , 
                         INPUT tt-item-doc-est.val-aliq-cofins)
                        .
                   /**/

                RUN updateRecord IN h-boin176 .
                RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors-aux) .
                FOR EACH RowErrors-aux NO-LOCK
                   WHERE RowErrors.ErrorSubType = "ERROR":
                    CREATE RowErrors . 
                    BUFFER-COPY RowErrors-aux TO RowErrors .
                    ASSIGN RowErrors.ErrorHelp = "Item: " + tt-item-doc-est.it-codigo + " " + TRIM(RowErrors.ErrorHelp).
                END.

                IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
                DO:
                    FOR EACH RowErrors:
                        PUT STREAM s-critica UNFORMATTED
                            STRING(i-nro-docto,"9999999")   AT 01
                            tt-nota-fis.nf_cod_processo     AT 10
                            "boin176-update"                AT 30
                            RowErrors.ErrorNumber           AT 50
                            RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                            RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                            RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    END.
                   UNDO TRA1, LEAVE TRA1.
                END.
                
                IF LOG-MANAGER:LOGFILE-NAME <> ? THEN 
                DO:
                    LOG-MANAGER:WRITE-MESSAGE("bojrx211 - pi-integrar-nfe - TAKE004") .
                    LOG-MANAGER:WRITE-MESSAGE("Item: " + ITEM.it-codigo) .
                END.  
                
              ASSIGN  d-tot-vlr-dupli = d-tot-vlr-dupli +  (ordem-compra.preco-fornec *  fu-trans-dec(tt-it-nota-fis.nf_ite_qtde)).
                        
         END.  // tt-item-doc-est 

          
          RUN TransferTotalItensNota IN h-boin176 (INPUT tt-docum-est.cod-emitente ,
                                                   INPUT tt-docum-est.serie-docto ,
                                                   INPUT tt-docum-est.nro-docto ,
                                                   INPUT tt-docum-est.nat-operacao) .
            
            //DUPLICATAS
            /**
             FOR EACH cond-pagto WHERE cond-pagto.cod-cond-pag = 103: 
     DISP    
         cond-pagto.cod-cond-pag
         cond-pagto.prazos[1].
         
END.         
    
            
            **/
          
          
            EMPTY TEMP-TABLE tt-dupli-apagar .
            ASSIGN i-parcela = i-parcela + 1.
            
            CREATE tt-dupli-apagar .      //2
            ASSIGN tt-dupli-apagar.serie-docto     = c-serie
                   tt-dupli-apagar.nro-docto       = tt-docum-est.nro-docto // STRING(i-nro-docto,"9999999") //tt-docum-est.nro-docto 
                   tt-dupli-apagar.cod-emitente    = tt-docum-est.cod-emitente
                   tt-dupli-apagar.nat-operacao    = tt-docum-est.nat-operacao
                   tt-dupli-apagar.cod-esp         = "CE"
                   tt-dupli-apagar.nr-duplic       = tt-nota-fis.nf_cod_processo  
                   tt-dupli-apagar.parcela         = STRING(i-parcela, "99")
                   tt-dupli-apagar.dt-emissao      = TODAY 
                   tt-dupli-apagar.dt-trans        = TODAY 
                   tt-dupli-apagar.dt-vencim        =  DATE(fnData(tt-nota-fis.nf_data_conhecimento)) + (IF AVAIL cond-pagto THEN cond-pagto.prazos[1] ELSE 0)
                   tt-dupli-apagar.vl-a-pagar      = tt-docum-est.valor-mercad
                   tt-dupli-apagar.mo              = tt-docum-est.valor-mercad
                   tt-dupli-apagar.mo-codigo       = 1
                   tt-dupli-apagar.vl-a-pagar-mo    = d-tot-vlr-despesa
                   tt-dupli-apagar.valor-a-pagar-me = d-tot-vlr-despesa
                   tt-dupli-apagar.ep-codigo       = "super"
                   tt-dupli-apagar.cod-estabel     = tt-docum-est.cod-estabel
                   tt-dupli-apagar.tp-despesa      = 12
                   OVERLAY(tt-dupli-apagar.char-1,1,10) = "1"
                   OVERLAY(tt-dupli-apagar.char-1,21,25) = STRING(d-tot-vlr-dupli). // MPS d-vl-dolar
                        

            RUN emptyRowErrors IN h-boin092 .         
            RUN setRecord IN h-boin092(INPUT TABLE tt-dupli-apagar) .
            RUN createRecord IN h-boin092.
            RUN getRowErrors IN h-boin092(OUTPUT TABLE RowErrors APPEND) .

            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
            DO:
                FOR EACH RowErrors:
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin092-update"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                END.
                UNDO TRA1, LEAVE TRA1.
            END.
            
          
          // DESPESAS 
            FOR EACH tt-despesa-nf
               WHERE tt-despesa-nf.nf_numnf = tt-nota-fis.nf_numnf 
                  BY tt-despesa-nf.id_despesa_erp:
                
                IF INT(tt-despesa-nf.id_despesa_erp) = 0  THEN NEXT. 
                IF INT(tt-despesa-nf.id_despesa_erp) = 41 THEN NEXT. // COFINS INPORTA
                IF INT(tt-despesa-nf.id_despesa_erp) = 42 THEN NEXT. // PIS IMPORTA
                IF INT(tt-despesa-nf.id_despesa_erp) = 43 THEN NEXT. //COFINS IMPORTA
                IF INT(tt-despesa-nf.id_despesa_erp) = 44 THEN NEXT. // ICMS IMPORTA
                IF INT(tt-despesa-nf.id_despesa_erp) = 67 THEN NEXT. //IPI

                ASSIGN tt-despesa-nf.valor_despesa = REPLACE(tt-despesa-nf.valor_despesa,"." , ",").
                ASSIGN i-parcela-cex   = i-parcela-cex + 1.
                       
                EMPTY TEMP-TABLE tt-docum-est-cex . 
                CREATE tt-docum-est-cex . 
                ASSIGN tt-docum-est-cex.serie-docto       = c-serie //99
                       tt-docum-est-cex.nro-docto         = tt-docum-est.nro-docto 
                       tt-docum-est-cex.cod-emitente      = tt-docum-est.cod-emitente 
                       tt-docum-est-cex.nat-operacao      = tt-docum-est.nat-operacao
                       tt-docum-est-cex.cod-emitente-desp = INT(tt-despesa-nf.credor)
                       tt-docum-est-cex.cod-desp          = INT(tt-despesa-nf.id_despesa_erp)   
                       tt-docum-est-cex.val-desp          = fu-trans-dec(tt-despesa-nf.valor_despesa)
                       //tt-docum-est-cex.cod-cond-pag    = cond-pagto.cod-cond-pag
                       tt-docum-est-cex.mo-codigo         = 1
                       tt-docum-est-cex.cotacao           = 1.
                            
                
                RUN emptyRowErrors IN h-bocx090 .
                RUN setRecord IN h-bocx090(INPUT TABLE tt-docum-est-cex) .
                RUN createRecord IN h-bocx090.
                RUN getRowErrors IN h-bocx090(OUTPUT TABLE RowErrors APPEND) .

                IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
                DO:
                    FOR EACH RowErrors:
                        RowErrors.ErrorHelp = "Desp: " + tt-despesa-nf.id_despesa_erp + " " + RowErrors.ErrorHelp.
                        PUT STREAM s-critica UNFORMATTED
                            STRING(i-nro-docto,"9999999")   AT 01
                            tt-nota-fis.nf_cod_processo     AT 10
                            "bocx090-create"                AT 30
                            RowErrors.ErrorNumber           AT 50
                            RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                            RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                            RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    END.
                  UNDO TRA1, LEAVE TRA1.
                END.
            END.
            
            
            FOR EACH tt-despesa-nf
               WHERE tt-despesa-nf.nf_numnf = tt-nota-fis.nf_numnf 
                  BY tt-despesa-nf.id_despesa_erp:
            
                ASSIGN tt-despesa-nf.valor_despesa = REPLACE(tt-despesa-nf.valor_despesa,"." , ",").
                EMPTY TEMP-TABLE tt-dupli-apagar-cex. 
                
                ASSIGN i-parcela-dupli = i-parcela-dupli + 1.
                 
                CREATE tt-dupli-apagar-cex.     //
                ASSIGN tt-dupli-apagar-cex.cod-emitente      = tt-docum-est.cod-emitente 
                       tt-dupli-apagar-cex.cod-emitente-desp = INT(tt-despesa-nf.credor)
                       tt-dupli-apagar-cex.parcela           = STRING(i-parcela-dupli, "99")
                       tt-dupli-apagar-cex.cod-esp           = "DP"
                       tt-dupli-apagar-cex.serie-docto       = c-serie
                       tt-dupli-apagar-cex.nro-docto         = tt-docum-est.nro-docto 
                       tt-dupli-apagar-cex.nat-operacao      = tt-docum-est.nat-operacao
                       tt-dupli-apagar-cex.tp-despesa        = 20
                       tt-dupli-apagar-cex.desconto          = 0
                                                            
                       
                       //tt-dupli-apagar-cex.dt-emissao        = DATE(fnData(tt-nota-fis.nf_dt_emiss)) //TODAY
                       
                       tt-dupli-apagar-cex.dt-emissao        = TODAY
                       tt-dupli-apagar-cex.dt-venc-desc      = TODAY + (IF AVAIL cond-pagto THEN cond-pagto.prazos[1] ELSE 0)
                       tt-dupli-apagar-cex.dt-vencim         = TODAY + (IF AVAIL cond-pagto THEN cond-pagto.prazos[1] ELSE 0)
                      
                       tt-dupli-apagar-cex.vl-a-pagar         = fu-trans-dec(tt-despesa-nf.valor_despesa)
                       tt-dupli-apagar-cex.mo-codigo         = 0  //1 - dolar
                       tt-dupli-apagar-cex.vl-a-pagar-mo     = fu-trans-dec(tt-despesa-nf.valor_despesa)
                       tt-dupli-apagar-cex.dt-trans          = TODAY.
                                   
                
                RUN emptyRowErrors IN h-bocx255 .
                RUN setRecord IN h-bocx255(INPUT TABLE tt-dupli-apagar-cex) .
                RUN createRecord IN h-bocx255 .
                RUN getRowErrors IN h-bocx255(OUTPUT TABLE RowErrors APPEND) .

                IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
                DO:
                    FOR EACH RowErrors:
                        RowErrors.ErrorHelp = "Parc: " + STRING(tt-dupli-apagar-cex.parcela) + " " + RowErrors.ErrorHelp.
                        PUT STREAM s-critica UNFORMATTED
                            STRING(i-nro-docto,"9999999")   AT 01
                            tt-nota-fis.nf_cod_processo     AT 10
                            "bocx255-create"                AT 30
                            RowErrors.ErrorNumber           AT 50
                            RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                            RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                            RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                    END.
                   UNDO TRA1, LEAVE TRA1.
                END.
                
               FIND FIRST docto-estoq-nfe-imp WHERE 
                           docto-estoq-nfe-imp.cod-ser-docto  = c-serie //"2" 
                       AND docto-estoq-nfe-imp.cod-docto      = tt-docum-est.nro-docto 
                       AND docto-estoq-nfe-imp.cdn-emitente   = tt-docum-est.cod-emitente 
                       AND docto-estoq-nfe-imp.cod-natur-oper = tt-docum-est.nat-operacao
                            NO-LOCK NO-ERROR.
                IF NOT AVAILABLE docto-estoq-nfe-imp THEN
                DO:
                    IF tt-docum-est.cod-estabel = "101" THEN ASSIGN c-cod-uf = "PR".
                    IF tt-docum-est.cod-estabel = "111" THEN ASSIGN c-cod-uf = "ES".
                     
                    EMPTY TEMP-TABLE tt-docto-estoq-nfe-imp.
                    CREATE tt-docto-estoq-nfe-imp.
                    ASSIGN tt-docto-estoq-nfe-imp.cod-ser-docto   = c-serie //"2" 
                           tt-docto-estoq-nfe-imp.cod-docto        = tt-docum-est.nro-docto 
                           tt-docto-estoq-nfe-imp.cdn-emitente     = tt-docum-est.cod-emitente 
                           tt-docto-estoq-nfe-imp.cod-natur-oper   = tt-docum-est.nat-operacao
                           tt-docto-estoq-nfe-imp.des-decla-import = STRING(tt-nota-fis.nf_numero_di)
                           tt-docto-estoq-nfe-imp.des-descr-gener  = "REGISTRO DI"
                           tt-docto-estoq-nfe-imp.cod-uf           = c-cod-uf   
                           
                           tt-docto-estoq-nfe-imp.dat-decla-import = DATE(fnData(tt-nota-fis.nf_data_registro_di))
                           tt-docto-estoq-nfe-imp.dat-desembarac   = DATE(fnData(tt-nota-fis.nf_data_desembaraco))
                           
                           tt-docto-estoq-nfe-imp.cdn-expdor       = tt-docum-est.cod-emitente // INT(tt-despesa-nf.credor)
                           OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,1,2)    = "1"  
                           OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,3,4)    = "0,00"  
                           OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,41 ,1)  = "0"
                           OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,23,2)   = "1"
                            .                                                    
                    RUN emptyRowErrors IN h-boin813 .
                    RUN setRecord IN h-boin813(INPUT TABLE tt-docto-estoq-nfe-imp) .
                    RUN createRecord IN h-boin813 .
                    RUN getRowErrors IN h-boin813(OUTPUT TABLE RowErrors APPEND) .
                   
                    IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
                    DO:
                        FOR EACH RowErrors:
                            RowErrors.ErrorHelp = "DI: " + STRING(tt-nota-fis.nf_numero_di) + " " + RowErrors.ErrorHelp.
                            PUT STREAM s-critica UNFORMATTED
                                STRING(i-nro-docto,"9999999")   AT 01
                                tt-nota-fis.nf_cod_processo     AT 10
                                "bocx255-create"                AT 30
                                RowErrors.ErrorNumber           AT 50
                                RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                                RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                                RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                        END.
                      NEXT.  // UNDO TRA1, LEAVE TRA1.
                    END.
                    
                    FIND FIRST embarque-imp  WHERE embarque-imp.embarque = tt-nota-fis.nf_cod_processo   AND 
                               embarque-imp.cod-estabel = tt-docum-est.cod-estabel NO-ERROR.
                     IF AVAIL embarque-imp  THEN DO:
                        ASSIGN embarque-imp.declaracao-import = STRING(tt-nota-fis.nf_numero_di)
                               embarque-imp.data-di           = DATE(fnData(tt-nota-fis.nf_data_registro_di)).
                     END.
                END.  
              
            END. // tt-despesa 
            
            // Embalagem
            
            ASSIGN l-new-record = YES.
            EMPTY TEMP-TABLE tt-docto-estoq-embal.
            
            CREATE tt-docto-estoq-embal.
            ASSIGN tt-docto-estoq-embal.cod-ser-docto    = c-serie //"2"
                   tt-docto-estoq-embal.cod-docto        = tt-docum-est.nro-docto //STRING(i-nro-docto,"9999999")
                   tt-docto-estoq-embal.cdn-emitente     = tt-docum-est.cod-emitente
                   tt-docto-estoq-embal.cod-natur-operac = tt-docum-est.nat-operacao
                   tt-docto-estoq-embal.cod-sig-embal    = "CX"
                   tt-docto-estoq-embal.cod-embal        = "CAIXA"
                   tt-docto-estoq-embal.num-vol          = 0
                   tt-docto-estoq-embal.des-marca-vol    = "CAIXA"
                   tt-docto-estoq-embal.des-espec-volum  = "CAIXA"
                   tt-docto-estoq-embal.qtd-vol          = fu-trans-dec(tt-nota-fis.nf_qtde_volume)
                   tt-docto-estoq-embal.val-peso-embal   = fu-trans-dec(tt-nota-fis.peso-bruto-tot)
                   tt-docto-estoq-embal.des-descr-gener  = "CAIXA".
            
            RUN gotokey  IN h-boin815  (INPUT tt-docto-estoq-embal.cod-ser-docto,     
                                        INPUT tt-docto-estoq-embal.cod-docto,           
                                        INPUT tt-docto-estoq-embal.cdn-emitente,    
                                        INPUT tt-docto-estoq-embal.cod-natur-operac,
                                        INPUT tt-docto-estoq-embal.cod-sig-embal).    
            
            IF RETURN-VALUE <>  "OK":U OR (l-new-record AND RETURN-VALUE =  "OK":U)  THEN 
            DO:
                RUN emptyRowErrors IN h-boin815.
                RUN setRecord IN h-boin815 (INPUT TABLE tt-docto-estoq-embal).
                RUN CreateRecord IN h-boin815.
            END.
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN 
            DO:
                FOR EACH RowErrors:
                    RowErrors.ErrorHelp = "Emb: " + tt-docto-estoq-embal.cod-embal + " " + RowErrors.ErrorHelp.
                    PUT STREAM s-critica UNFORMATTED
                        STRING(i-nro-docto,"9999999")   AT 01
                        tt-nota-fis.nf_cod_processo     AT 10
                        "boin815-create"                AT 30
                        RowErrors.ErrorNumber           AT 50
                        RowErrors.ErrorDescription FORMAT "x(60)"   AT 60
                        RowErrors.ErrorParameters  FORMAT "x(20)"   AT 120
                        RowErrors.ErrorHelp        FORMAT "x(60)"   AT 140.
                END.
               UNDO TRA1, LEAVE TRA1.
            END.
            
            
            // Acerta o Embarque E O Valor total da nota
            FIND docum-est OF tt-docum-est EXCLUSIVE-LOCK NO-ERROR.
            IF AVAIL docum-est THEN
            DO:
              ASSIGN OVERLAY(docum-est.char-1,1,11) = tt-nota-fis.nf_cod_processo.
              ASSIGN docum-est.tot-valor  = docum-est.tot-valor - d-tot-icms. 
               .     
            END.
            FIND CURRENT docum-est NO-LOCK NO-ERROR.
          
         
            IF VALID-HANDLE(h-boin090) THEN DO:
                RUN destroy IN h-boin090 .
                DELETE PROCEDURE h-boin090 NO-ERROR .
                ASSIGN h-boin090 = ? .
            END.
            
            IF VALID-HANDLE(h-boin813) THEN DO:
                RUN destroy IN h-boin813 .
                DELETE PROCEDURE h-boin813 NO-ERROR .
                ASSIGN h-boin813 = ? .
            END.

            IF VALID-HANDLE(h-boin814) THEN DO:
                RUN destroy IN h-boin814 .
                DELETE PROCEDURE h-boin814 NO-ERROR .
                ASSIGN h-boin814 = ? .
            END.

            IF VALID-HANDLE(h-boin815) THEN DO:
                RUN destroy IN h-boin815 .
                DELETE PROCEDURE h-boin815 NO-ERROR .
                ASSIGN h-boin815 = ? .
            END.

            IF VALID-HANDLE(h-bocx255) THEN DO:
                RUN destroy IN h-bocx255 .
                DELETE PROCEDURE h-bocx255 NO-ERROR .
                ASSIGN h-bocx255 = ? .
            END.

            IF VALID-HANDLE(h-boin176) THEN DO:
                RUN destroy IN h-boin176 .
                DELETE PROCEDURE h-boin176 NO-ERROR .
                ASSIGN h-boin176 = ? .
            END.

            IF VALID-HANDLE(h-boin092) THEN DO:
                RUN destroy IN h-boin092 .
                DELETE PROCEDURE h-boin092 NO-ERROR .
                ASSIGN h-boin092 = ? .
            END.
            
            IF VALID-HANDLE(h-bocx090) THEN DO:
                RUN destroy IN h-bocx090 .
                DELETE PROCEDURE h-bocx090 NO-ERROR .
                ASSIGN h-bocx090 = ? .
            END.

            IF VALID-HANDLE(h-cdapi995) THEN DO:
                RUN pi-finalizar IN h-cdapi995 .
                DELETE PROCEDURE h-cdapi995 NO-ERROR .
                ASSIGN h-cdapi995 = ? .
            END.
            
            IF VALID-HANDLE(h-bocx310) THEN DO:
                DELETE PROCEDURE h-bocx310 NO-ERROR .
                ASSIGN h-bocx310 = ? .
            END.

            IF VALID-HANDLE(h-bocx220) THEN DO:
                DELETE PROCEDURE h-bocx220 NO-ERROR .
                ASSIGN h-bocx220 = ? .
            END.

                    
    END. // tt-nota-fis
    
END. // DO TRANSACTION

END PROCEDURE.
