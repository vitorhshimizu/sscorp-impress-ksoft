/*
*/

{utp/ut-api.i}

{utp/ut-glob.i}

{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-action.i "pi-get-by-di" "GET" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

{method/dbotterr.i} /* RowErrors */

DEF TEMP-TABLE RowErrors-aux NO-UNDO LIKE RowErrors .

DEF TEMP-TABLE tt-docum-est NO-UNDO LIKE docum-est
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-item-doc-est NO-UNDO LIKE item-doc-est
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-item-doc-est-cex NO-UNDO LIKE item-doc-est-cex
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-total-item NO-UNDO
    FIELD tot-peso              LIKE docum-est.tot-peso
    FIELD peso-bruto-tot        LIKE docum-est.peso-bruto-tot
    FIELD tot-desconto          LIKE docum-est.tot-desconto
    FIELD despesa-nota          LIKE docum-est.despesa-nota
    FIELD valor-mercad          LIKE docum-est.valor-mercad
    FIELD base-ipi              LIKE docum-est.base-ipi
    FIELD valor-ipi             AS DECIMAL 
    FIELD base-icm              LIKE docum-est.base-icm
    FIELD valor-icm             AS DECIMAL 
    FIELD base-iss              LIKE docum-est.base-iss
    FIELD valor-iss             AS DECIMAL
    FIELD base-subs             LIKE docum-est.base-subs
    FIELD valor-subs            AS DECIMAL
    FIELD base-icm-complem      AS DECIMAL
    FIELD icm-complem           LIKE docum-est.icm-complem
    FIELD fundo-pobreza         AS DECIMAL
    FIELD ipi-outras            LIKE docum-est.ipi-outras
    FIELD valor-pis             AS DECIMAL
    FIELD valor-cofins          AS DECIMAL
    FIELD total-pis-subst       AS DECIMAL
    FIELD total-cofins-subs     AS DECIMAL
    FIELD total-icms-diferim    AS DECIMAL
    FIELD valor-frete           LIKE docum-est.valor-frete
    FIELD valor-pedagio         AS DECIMAL
    FIELD valor-icm-trib        AS DECIMAL
    FIELD de-tot-valor-calc     LIKE docum-est.tot-valor
    .

DEF TEMP-TABLE tt-dupli-apagar NO-UNDO LIKE dupli-apagar
    FIELD r-rowid   AS ROWID
    .

DEF TEMP-TABLE tt-docto-estoq-nfe-imp NO-UNDO LIKE docto-estoq-nfe-imp
    FIELD r-rowid AS ROWID
    .

DEF NEW GLOBAL SHARED VAR gc-peso-bruto-tot AS CHAR NO-UNDO .

FUNCTION fnNowToString RETURNS CHAR
    ()
    :
    DEF VAR p-data  AS DATE NO-UNDO INIT TODAY .
    DEF VAR p-mtime AS INT NO-UNDO .

    ASSIGN p-mtime = MTIME(NOW) .

    RETURN 
        STRING(YEAR(p-data) , "9999") + 
        STRING(MONTH(p-data) , "99") + 
        STRING(DAY(p-data) , "99") +
        "_" +
        REPLACE(STRING(INT(p-mtime / 1000), "HH:MM:SS"), ":", "") + 
        "_" +
        STRING(p-mtime MOD 1000, "999")
        .
END FUNCTION .

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR l-ok                    AS LOGICAL NO-UNDO .
    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR iContAdicao             AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .
    DEF VAR oAdicaoArray            AS JsonArray NO-UNDO .
    DEF VAR oAdicao                 AS JsonObject NO-UNDO .
    DEF VAR oDespesaArray           AS JsonArray NO-UNDO .
    DEF VAR oDespesa                AS JsonObject NO-UNDO .
    DEF VAR oDuplicataImpArray      AS JsonArray NO-UNDO .
    DEF VAR oDuplicataImp           AS JsonObject NO-UNDO .

    DEF VAR cDocto          AS CHAR NO-UNDO .
    DEF VAR deVlII          AS DECIMAL NO-UNDO .
    DEF VAR deTotVlMercad   AS DECIMAL NO-UNDO .
    DEF VAR deTotPesoLiq    AS DECIMAL NO-UNDO .
    DEF VAR deTotPesoBru    AS DECIMAL NO-UNDO .
    DEF VAR deTotDesp       AS DECIMAL NO-UNDO .
    DEF VAR deTotDespTodos  AS DECIMAL NO-UNDO .

    DEF BUFFER emitente-transp  FOR emitente .
    DEF BUFFER pais             FOR mgcad.pais .
    DEF BUFFER item-doc-imp     FOR item-docto-estoq-nfe-imp .

    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .
    ASSIGN oDuplicataImpArray = fnApiGetArray(oIn, "duplicatas_imp") .

    oIn:WriteFile("C:\totvs\ksoft_log\POST_receiptImport\" + fnNowToString() + ".json", YES, "UTF-8") .

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = fnApiGetInt(oHeader, "cod_cli_for")
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Cliente/Fornecedor n∆o encontrado") .
        RETURN .
    END.

    FIND FIRST natur-oper NO-LOCK
        WHERE natur-oper.nat-operacao = fnApiGetChar(oHeader, "nat_operacao")
        NO-ERROR .
    IF NOT AVAIL natur-oper THEN DO:
        oOut = fnApiErro("Natureza de Operaá∆o n∆o encontrado") .
        RETURN .
    END.

    FIND FIRST pais NO-LOCK 
        WHERE pais.nome-pais = emitente.pais
        .

    IF fnApiGetInt(oHeader, "cod_transp") <> 0 THEN DO:
        FIND FIRST emitente-transp NO-LOCK
            WHERE emitente-transp.cod-emitente = fnApiGetInt(oHeader, "cod_transp")
            NO-ERROR .
        IF NOT AVAIL emitente-transp THEN DO:
            oOut = fnApiErro("Transportador 1 n∆o encontrado") .
            RETURN .
        END.
        FIND FIRST transporte NO-LOCK
            WHERE transporte.cgc = emitente-transp.cgc
            NO-ERROR .
        IF NOT AVAIL transporte THEN DO:
            oOut = fnApiErro("Transportador 2 n∆o encontrado") .
            RETURN .
        END.
    END.

    IF fnApiGetInt(oHeader, "cod_cond_pag") <> 0 THEN DO:
        FIND FIRST cond-pagto NO-LOCK
            WHERE cond-pagto.cod-cond-pag = fnApiGetInt(oHeader, "cod_cond_pag")
            NO-ERROR .
        IF NOT AVAIL cond-pagto THEN DO:
            oOut = fnApiErro("Condiá∆o de Pagamento n∆o encontrado") .
            RETURN .
        END.
    END.

    /**/
    DEF VAR h-boin090   AS HANDLE NO-UNDO .
    RUN inbo/boin090.p PERSISTENT SET h-boin090 .
    RUN openQueryStatic IN h-boin090(INPUT "Main") .

    DEF VAR h-boin176   AS HANDLE NO-UNDO .
    RUN inbo/boin176.p PERSISTENT SET h-boin176 .
    RUN openQueryStatic IN h-boin176(INPUT "Main") .

    DEF VAR h-bocx100   AS HANDLE NO-UNDO .
    RUN cxbo/bocx100.p PERSISTENT SET h-bocx100 .
    RUN openQueryStatic IN h-bocx100(INPUT "Main") .

    DEF VAR h-cdapi995  AS HANDLE  NO-UNDO .
    RUN cdp/cdapi995.p PERSISTENT SET h-cdapi995 .

    DEF VAR h-boin813 AS HANDLE NO-UNDO .
    RUN inbo/boin0813.p PERSISTENT SET h-boin813 .
    RUN openQueryStatic IN h-boin813(INPUT "Main") .

    oOut = fnApiErro("Erro interno, transaá∆o n∆o finalizada") .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        ASSIGN cDocto = fnApiGetChar(oHeader, "nro_docto") .
        IF LENGTH(cDocto) < 7 THEN DO:
            ASSIGN cDocto = FILL("0", 7 - LENGTH(cDocto)) + cDocto .
        END.

        EMPTY TEMP-TABLE tt-docum-est .
        CREATE tt-docum-est . ASSIGN
            tt-docum-est.cod-chave-aces-nf-eletro = fnApiGetChar(oHeader, "cod_chave_nfe")
            tt-docum-est.serie-docto        = fnApiGetChar(oHeader, "serie")
            tt-docum-est.nro-docto          = cDocto
            tt-docum-est.cod-emitente       = emitente.cod-emitente
            tt-docum-est.nat-operacao       = fnApiGetChar(oHeader, "nat_operacao")
            tt-docum-est.cod-estabel        = fnApiGetChar(oHeader, "cod_estabel")
            tt-docum-est.esp-docto          = 21 /* NFE */
            tt-docum-est.tipo-docto         = 1 /* Entrada */
            tt-docum-est.cod-observa        = fnApiGetInt(oHeader, "cod_observa")
            tt-docum-est.dt-emissao         = TODAY
            tt-docum-est.dt-trans           = TODAY
            tt-docum-est.observacao         = fnApiGetChar(oHeader, "observacao")
            tt-docum-est.embarque           = fnApiGetChar(oHeader, "embarque")
            tt-docum-est.declaracao-import  = fnApiGetChar(oHeader, "di")
            tt-docum-est.char-1             = tt-docum-est.embarque
            tt-docum-est.nome-transp        = IF AVAIL transporte THEN transporte.nome-abrev ELSE ""
            tt-docum-est.dec-2              = deTotVlMercad
            tt-docum-est.tot-peso           = 0
            gc-peso-bruto-tot               = STRING(tt-docum-est.tot-peso)
            .

        /* Transportadora */
        OVERLAY(tt-docum-est.char-2,102,12) = tt-docum-est.nome-transp .
    
        RUN emptyRowErrors IN h-boin090 .
        RUN setRecord IN h-boin090(INPUT TABLE tt-docum-est) .
        RUN createRecord IN h-boin090 .
        RUN getRowErrors IN h-boin090(OUTPUT TABLE RowErrors) .
        FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
        IF AVAIL RowErrors THEN DO:
            oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
            UNDO TRA1, LEAVE TRA1.
        END.

        RUN getRecord IN h-boin090(OUTPUT TABLE tt-docum-est) .
        FIND FIRST tt-docum-est .
        FIND FIRST docum-est NO-LOCK WHERE ROWID(docum-est) = tt-docum-est.r-rowid .

        /* Fato Gerador CBS/IBS 
        Removido por ser gerado pela BO do produto agora
        */
        /*
        CREATE ext-docum-est . ASSIGN
            ext-docum-est.serie-docto   = docum-est.serie-docto
            ext-docum-est.nro-docto     = docum-est.nro-docto 
            ext-docum-est.cod-emitente  = docum-est.cod-emitente
            ext-docum-est.nat-operacao  = docum-est.nat-operacao
            ext-docum-est.cod-param     = "fatogeradorCBS-IBS"
            ext-docum-est.cod-livre-1   = "ARAUCARIA"
            ext-docum-est.cod-livre-2   = "PR"
            ext-docum-est.cod-livre-3   = "BRASIL"
            .
        */
        /**/
        EMPTY TEMP-TABLE tt-docto-estoq-nfe-imp .
        CREATE tt-docto-estoq-nfe-imp. ASSIGN 
            tt-docto-estoq-nfe-imp.cod-ser-docto    = docum-est.serie-docto 
            tt-docto-estoq-nfe-imp.cod-docto        = docum-est.nro-docto 
            tt-docto-estoq-nfe-imp.cdn-emitente     = docum-est.cod-emitente
            tt-docto-estoq-nfe-imp.cod-natur-oper   = docum-est.nat-operacao
            tt-docto-estoq-nfe-imp.des-decla-import = fnApiGetChar(oHeader, "di")
            tt-docto-estoq-nfe-imp.des-descr-gener  = "REGISTRO DI"
            tt-docto-estoq-nfe-imp.cod-uf           = "PR"
            tt-docto-estoq-nfe-imp.dat-decla-import = fnApiGetDate(oHeader, "dt_registro_di")
            tt-docto-estoq-nfe-imp.dat-desembarac   = tt-docto-estoq-nfe-imp.dat-decla-import
            tt-docto-estoq-nfe-imp.cdn-expdor       = docum-est.cod-emitente
            .
        OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,1,2)     = STRING(fnApiGetInt(oHeader, "cod_via_transp_inter")) .
        OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,3,20)    = STRING(fnApiGetDecimal(oHeader, "vl_afrmm")) .
        OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,23,2)    = "1" . /* forma-importa */
        OVERLAY(tt-docto-estoq-nfe-imp.cod-livre-1,41,1)    = "0" . /* decla-imp */

        RUN emptyRowErrors IN h-boin813 .
        RUN setRecord IN h-boin813(INPUT TABLE tt-docto-estoq-nfe-imp) .
        RUN createRecord IN h-boin813 .
        RUN getRowErrors IN h-boin813(OUTPUT TABLE RowErrors APPEND) .
        FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
        IF AVAIL RowErrors THEN DO:
            oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
            UNDO TRA1, LEAVE TRA1.
        END.

        DO iCont = 1 TO oItensArray:LENGTH
            :
            ASSIGN oItem = oItensArray:GetJsonObject(iCont) .

            FIND FIRST ITEM NO-LOCK
                WHERE ITEM.it-codigo = fnApiGetChar(oItem, "it_codigo")
                NO-ERROR .
            IF NOT AVAIL ITEM THEN DO:
                oOut = fnApiErro("Item n∆o encontrado, Pos:" + STRING(iCont) ) .
                UNDO TRA1, LEAVE TRA1.
            END.

            EMPTY TEMP-TABLE tt-item-doc-est .
            CREATE tt-item-doc-est . ASSIGN
                tt-item-doc-est.serie-docto             = docum-est.serie-docto 
                tt-item-doc-est.nro-docto               = docum-est.nro-docto   
                tt-item-doc-est.cod-emitente            = docum-est.cod-emitente
                tt-item-doc-est.nat-operacao            = docum-est.nat-operacao
                tt-item-doc-est.sequencia               = iCont * 10
                tt-item-doc-est.it-codigo               = fnApiGetChar(oItem, "it_codigo")
                tt-item-doc-est.quantidade              = fnApiGetDecimal(oItem, "quantidade")
                tt-item-doc-est.un                      = fnApiGetChar(oItem, "un")
                tt-item-doc-est.preco-unit              = fnApiGetDecimal(oItem, "preco_unit")
                tt-item-doc-est.preco-total             = fnApiGetDecimal(oItem, "preco_total")
                tt-item-doc-est.qt-do-forn              = fnApiGetDecimal(oItem, "quantidade_for")
                tt-item-doc-est.narrativa               = fnApiGetChar(oItem, "narrativa")
                tt-item-doc-est.ct-codigo               = fnApiGetChar(oItem, "ct_codigo")
                tt-item-doc-est.sc-codigo               = fnApiGetChar(oItem, "sc_codigo")
                tt-item-doc-est.peso-bruto-item         = fnApiGetDecimal(oItem, "peso_bruto")
                tt-item-doc-est.peso-liquido            = fnApiGetDecimal(oItem, "peso_liquido")
                tt-item-doc-est.peso-liquido-item       = fnApiGetDecimal(oItem, "peso_liquido")
                tt-item-doc-est.baixa-ce                = NO
                .
            IF tt-item-doc-est.ct-codigo = "" THEN DO:
                ASSIGN tt-item-doc-est.ct-codigo = ITEM.ct-codigo .
            END.

            ASSIGN deTotPesoBru = deTotPesoBru + tt-item-doc-est.peso-bruto-item .
            ASSIGN deTotPesoLiq = deTotPesoLiq + tt-item-doc-est.peso-liquido .

            RUN emptyRowErrors IN h-boin176 .
            RUN setRecord IN h-boin176(INPUT TABLE tt-item-doc-est) .
            RUN createRecord IN h-boin176 .
            RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors) .
            FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
            IF AVAIL RowErrors THEN DO:
                oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                UNDO TRA1, LEAVE TRA1.
            END.

            RUN getRecord IN h-boin176(OUTPUT TABLE tt-item-doc-est) .
            FIND FIRST tt-item-doc-est .

            ASSIGN
                tt-item-doc-est.num-sit-trib-icms       = 151
                OVERLAY(tt-item-doc-est.char-2,502,3)   = "151"
                tt-item-doc-est.cd-trib-ipi             = 1
                tt-item-doc-est.base-ipi                = fnApiGetDecimal(oItem, "base_ipi")
                tt-item-doc-est.aliquota-ipi            = fnApiGetDecimal(oItem, "p_ipi")
                tt-item-doc-est.valor-ipi               = fnApiGetDecimal(oItem, "vl_ipi")
                tt-item-doc-est.cd-trib-icm             = natur-oper.cd-trib-icm
                tt-item-doc-est.base-icm                = fnApiGetDecimal(oItem, "base_icm")
                tt-item-doc-est.aliquota-icm            = fnApiGetDecimal(oItem, "p_icm")
                tt-item-doc-est.valor-icm               = fnApiGetDecimal(oItem, "vl_icm")
                tt-item-doc-est.idi-tributac-pis        = 1 /* Tributado */
                tt-item-doc-est.base-pis                = fnApiGetDecimal(oItem, "base_pis")
                tt-item-doc-est.val-aliq-pis            = fnApiGetDecimal(oItem, "p_pis")
                tt-item-doc-est.valor-pis               = fnApiGetDecimal(oItem, "vl_pis")
                tt-item-doc-est.idi-tributac-cofins     = 1 /* Tributado */
                tt-item-doc-est.val-base-calc-cofins    = fnApiGetDecimal(oItem, "base_cofins")
                tt-item-doc-est.val-aliq-cofins         = fnApiGetDecimal(oItem, "p_cofins")
                tt-item-doc-est.val-cofins              = fnApiGetDecimal(oItem, "vl_cofins")
                tt-item-doc-est.despesas[1]             = fnApiGetDecimal(oItem, "vl_despesa")
                .

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

            RUN updateRecord IN h-boin176 .
            RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors) .
            FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
            IF AVAIL RowErrors THEN DO:
                oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                UNDO TRA1, LEAVE TRA1.
            END.

            RUN getRecord IN h-boin176(OUTPUT TABLE tt-item-doc-est) .
            FIND FIRST tt-item-doc-est .

            ASSIGN deVlII = 0 .
            ASSIGN oAdicaoArray = fnApiGetArray(oItem, "adicoes") .
            DO iContAdicao = 1 TO oAdicaoArray:LENGTH
                :
                ASSIGN oAdicao = oAdicaoArray:GetJsonObject(iContAdicao) .

                FIND FIRST item-doc-imp
                    WHERE item-doc-imp.cod-ser-docto = tt-item-doc-est.serie-docto
                    AND   item-doc-imp.cod-docto = tt-item-doc-est.nro-docto
                    AND   item-doc-imp.cdn-emitente = tt-item-doc-est.cod-emitente
                    AND   item-doc-imp.cod-natur-operac = tt-item-doc-est.nat-operacao
                    AND   item-doc-imp.num-seq = tt-item-doc-est.sequencia
                    NO-ERROR .
                IF NOT AVAIL item-doc-imp THEN DO:
                    CREATE item-doc-imp . ASSIGN
                        item-doc-imp.cod-ser-docto = tt-item-doc-est.serie-docto
                        item-doc-imp.cod-docto = tt-item-doc-est.nro-docto
                        item-doc-imp.cdn-emitente = tt-item-doc-est.cod-emitente
                        item-doc-imp.cod-natur-operac = tt-item-doc-est.nat-operacao
                        item-doc-imp.num-seq = tt-item-doc-est.sequencia
                        item-doc-imp.cod-item = tt-item-doc-est.it-codigo
                        .
                END.
                ASSIGN
                    item-doc-imp.num-adic           = fnApiGetInt(oAdicao, "num_adic")
                    item-doc-imp.num-seq-import     = tt-item-doc-est.sequencia
                    item-doc-imp.cdn-expdor         = tt-docto-estoq-nfe-imp.cdn-expdor
                    item-doc-imp.val-base           = fnApiGetDecimal(oAdicao, "vl_base")
                    item-doc-imp.val-despesa        = fnApiGetDecimal(oAdicao, "vl_desp_aduaneira")
                    item-doc-imp.val-impto-import   = fnApiGetDecimal(oAdicao, "vl_ii")
                    item-doc-imp.des-decla-import   = tt-docto-estoq-nfe-imp.des-decla-import
                    item-doc-imp.cod-livre-1        = fnApiGetChar(oAdicao, "nr_drawback")
                    item-doc-imp.num-livre-1        = pais.cod-pais
                    .
                ASSIGN deVlII = deVlII + item-doc-imp.val-impto-import .
            END.

            ASSIGN oDespesaArray = fnApiGetArray(oItem, "despesas_imp") .
            DO iContAdicao = 1 TO oDespesaArray:LENGTH
                :
                ASSIGN oDespesa = oDespesaArray:GetJsonObject(iContAdicao) .

                EMPTY TEMP-TABLE tt-item-doc-est-cex .
                CREATE tt-item-doc-est-cex . ASSIGN
                    tt-item-doc-est-cex.serie-docto     = tt-item-doc-est.serie-docto
                    tt-item-doc-est-cex.nro-docto       = tt-item-doc-est.nro-docto
                    tt-item-doc-est-cex.cod-emitente    = tt-item-doc-est.cod-emitente
                    tt-item-doc-est-cex.nat-operacao    = tt-item-doc-est.nat-operacao
                    tt-item-doc-est-cex.sequencia       = tt-item-doc-est.sequencia
                    tt-item-doc-est-cex.cod-emitente-desp   = fnApiGetInt(oDespesa, "cod_fornecedor")
                    tt-item-doc-est-cex.cod-desp        = fnApiGetInt(oDespesa, "cod_despesa")
                    tt-item-doc-est-cex.val-desp        = fnApiGetDecimal(oDespesa, "vl_despesa")
                    .

                RUN emptyRowErrors IN h-bocx100 .
                RUN setRecord IN h-bocx100(INPUT TABLE tt-item-doc-est-cex) .
                RUN createRecord IN h-bocx100 .
                RUN getRowErrors IN h-bocx100(OUTPUT TABLE RowErrors) .
                FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
                IF AVAIL RowErrors THEN DO:
                    oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                    UNDO TRA1, LEAVE TRA1.
                END.
            END.

            /* Soma despesas impostos as despesas do item */
            RUN getRecord IN h-boin176(OUTPUT TABLE tt-item-doc-est) .
            FIND FIRST tt-item-doc-est .

            ASSIGN tt-item-doc-est.despesas[1] = tt-item-doc-est.despesas[1] +
                tt-item-doc-est.valor-icm[1] +
                tt-item-doc-est.valor-pis +
                tt-item-doc-est.val-cofins +
                deVlII
                .

            RUN emptyRowErrors IN h-boin176 .
            RUN setRecord IN h-boin176(INPUT TABLE tt-item-doc-est) .
			RUN updateRecord IN h-boin176 .
            RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors) .
            FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
            IF AVAIL RowErrors THEN DO:
                oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                UNDO TRA1, LEAVE TRA1.
            END.
        END.

        /* Fatura das Despesas */
        FOR EACH item-doc-est-cex NO-LOCK OF docum-est
            BREAK
            BY item-doc-est-cex.cod-emitente-desp
            :
            IF FIRST-OF(item-doc-est-cex.cod-emitente-desp) THEN DO:
                ASSIGN deTotDesp = 0 .
            END.

            ASSIGN deTotDesp = deTotDesp + item-doc-est-cex.val-desp .

            IF LAST-OF(item-doc-est-cex.cod-emitente-desp) THEN DO:
                CREATE dupli-apagar-cex . ASSIGN
                    dupli-apagar-cex.serie-docto        = docum-est.serie-docto
                    dupli-apagar-cex.nro-docto          = docum-est.nro-docto
                    dupli-apagar-cex.cod-emitente       = docum-est.cod-emitente
                    dupli-apagar-cex.nat-operacao       = docum-est.nat-operacao
                    dupli-apagar-cex.cod-emitente-desp  = item-doc-est-cex.cod-emitente-desp
                    dupli-apagar-cex.parcela            = "1" 
                    dupli-apagar-cex.cod-esp            = "DP"
                    dupli-apagar-cex.tp-despesa         = 6 /* Despesa COMEX */
                    dupli-apagar-cex.dt-emissao         = docum-est.dt-emissao
                    dupli-apagar-cex.dt-vencim          = dupli-apagar-cex.dt-emissao
                    dupli-apagar-cex.vl-a-pagar         = deTotDesp
                    dupli-apagar-cex.vl-a-pagar-mo      = deTotDesp
                    dupli-apagar-cex.mo-codigo          = 0
                    dupli-apagar-cex.dt-trans           = docum-est.dt-trans
                    .
                   
            END.
        END.
        
        //Totaliza Nota
        RUN TransferTotalItensNota IN h-boin176 
            (INPUT docum-est.cod-emitente,
             INPUT docum-est.serie-docto,
             INPUT docum-est.nro-docto,
             INPUT docum-est.nat-operacao)
            .

        //tt-dupli-apagar
        IF AVAIL cond-pagto THEN DO:
            FIND CURRENT emitente .
            ASSIGN emitente.cod-cond-pag = cond-pagto.cod-cond-pag .
            RUN rep/re9341.p(INPUT ROWID(docum-est), INPUT NO) .
            FOR FIRST dupli-apagar OF docum-est
                :
                ASSIGN
                    OVERLAY(dupli-apagar.char-1, 01, 20)    = STRING(fnApiGetDecimal(oHeader, "currencyCode"))
                    OVERLAY(dupli-apagar.char-1, 21, 20)    = STRING(fnApiGetDecimal(oHeader, "currencyValue"))
                    .
            END.
        END.

        //Embalagens
        CREATE docto-estoq-embal . ASSIGN
            docto-estoq-embal.cod-ser-docto     = docum-est.serie-docto
            docto-estoq-embal.cod-docto         = docum-est.nro-docto
            docto-estoq-embal.cdn-emitente      = docum-est.cod-emitente
            docto-estoq-embal.cod-natur-operac  = docum-est.nat-operacao
            docto-estoq-embal.cod-sig-embal     = "VOL"
            docto-estoq-embal.num-vol           = fnApiGetInt(oHeader, "qt_volume")
            //docto-estoq-embal.des-marca-vol     = "IMPRESS DECOR BRASIL"
            docto-estoq-embal.des-marca-vol     = emitente.nome-abrev
            docto-estoq-embal.val-peso-embal    = MAX(0, deTotPesoBru - deTotPesoLiq)
            docto-estoq-embal.qtd-vol           = docto-estoq-embal.num-vol
            docto-estoq-embal.cod-embal         = docto-estoq-embal.cod-sig-embal
            docto-estoq-embal.des-descr-gener   = fnApiGetChar(oHeader, "cod_volume")
            docto-estoq-embal.des-espec-volum   = docto-estoq-embal.des-descr-gener
            .
        IF docto-estoq-embal.des-descr-gener MATCHES "*PALLET*" THEN DO:
            ASSIGN docto-estoq-embal.cod-sig-embal  = "PAL" .
        END.
        ELSE IF docto-estoq-embal.des-descr-gener MATCHES "*BOBINA*" THEN DO:
            ASSIGN docto-estoq-embal.cod-sig-embal  = "BOB" .
        END.

        //Despesas Outros Fornecedores Importacao
        DO iCont = 1 TO oDuplicataImpArray:LENGTH
            :
            ASSIGN oDuplicataImp = oDuplicataImpArray:GetJsonObject(iCont) .

            FIND FIRST dupli-apagar-cex NO-LOCK
                WHERE dupli-apagar-cex.serie-docto          = docum-est.serie-docto
                AND   dupli-apagar-cex.nro-docto            = docum-est.nro-docto
                AND   dupli-apagar-cex.cod-emitente         = docum-est.cod-emitente
                AND   dupli-apagar-cex.nat-operacao         = docum-est.nat-operacao
                AND   dupli-apagar-cex.cod-emitente-desp    = fnApiGetInt(oDuplicataImp, "cod_fornecedor")
                AND   dupli-apagar-cex.parcela              = fnApiGetChar(oDuplicataImp, "parcela")
                NO-ERROR .
            IF AVAIL dupli-apagar-cex THEN DO:
                oOut = fnApiErro("Duplicata Importaá∆o j† existe com a chave informada") .
                UNDO TRA1, LEAVE TRA1.
            END.

            CREATE dupli-apagar-cex . ASSIGN
                dupli-apagar-cex.serie-docto        = docum-est.serie-docto
                dupli-apagar-cex.nro-docto          = docum-est.nro-docto
                dupli-apagar-cex.cod-emitente       = docum-est.cod-emitente
                dupli-apagar-cex.nat-operacao       = docum-est.nat-operacao
                dupli-apagar-cex.cod-emitente-desp  = fnApiGetInt(oDuplicataImp, "cod_fornecedor")
                dupli-apagar-cex.parcela            = fnApiGetChar(oDuplicataImp, "parcela") 
                dupli-apagar-cex.cod-esp            = fnApiGetChar(oDuplicataImp, "cod_esp")
                dupli-apagar-cex.tp-despesa         = 6 /* Despesa COMEX */
                dupli-apagar-cex.dt-emissao         = docum-est.dt-emissao
                dupli-apagar-cex.dt-vencim          = fnApiGetDate(oDuplicataImp, "dt_vencim")
                dupli-apagar-cex.vl-a-pagar         = fnApiGetDecimal(oDuplicataImp, "vl_pagar")
                dupli-apagar-cex.vl-a-pagar-mo      = dupli-apagar-cex.vl-a-pagar
                dupli-apagar-cex.mo-codigo          = fnApiGetInt(oDuplicataImp, "cod_moeda")
                dupli-apagar-cex.dt-trans           = docum-est.dt-trans
                .
        END.

        FOR EACH dupli-apagar-cex OF docum-est
            :
            /* Nao criar como CE - Solicitado pela Ana durante os testes */
            IF dupli-apagar-cex.cod-esp = "CE" THEN DO:
                ASSIGN dupli-apagar-cex.cod-esp = "DP" .
            END.
            /* Fornecedores */
            IF dupli-apagar-cex.cod-emitente-desp = 4723 /* KUEHNE NAGEL */ THEN DO:
                ASSIGN dupli-apagar-cex.cod-esp = "DP" .
            END.
            ELSE IF dupli-apagar-cex.cod-emitente-desp = 200001 /* RECEITA FEDERAL MINISTERIO DA FAZENDA */ THEN DO:
                ASSIGN dupli-apagar-cex.cod-esp = "II" .
            END.
            ASSIGN deTotDespTodos = deTotDespTodos + dupli-apagar-cex.vl-a-pagar .
        END.
        
        FOR FIRST dupli-apagar OF docum-est
            :
            ASSIGN
                dupli-apagar.vl-a-pagar  = dupli-apagar.vl-a-pagar - deTotDespTodos
                .
        END.

        /**/
        ASSIGN l-ok = YES .
    END.

    IF VALID-HANDLE(h-boin090) THEN DO:
        RUN destroy IN h-boin090 .
        DELETE PROCEDURE h-boin090 NO-ERROR .
        ASSIGN h-boin090 = ? .
    END.

    IF VALID-HANDLE(h-boin176) THEN DO:
        RUN destroy IN h-boin176 .
        DELETE PROCEDURE h-boin176 NO-ERROR .
        ASSIGN h-boin176 = ? .
    END.

    IF VALID-HANDLE(h-bocx100) THEN DO:
        RUN destroy IN h-bocx100 .
        DELETE PROCEDURE h-bocx100 NO-ERROR .
        ASSIGN h-bocx100 = ? .
    END.

    IF VALID-HANDLE(h-cdapi995) THEN DO:
        RUN pi-finalizar IN h-cdapi995 .
        DELETE PROCEDURE h-cdapi995 NO-ERROR .
        ASSIGN h-cdapi995 = ? .
    END.

    IF VALID-HANDLE(h-boin813) THEN DO:
        RUN destroy IN h-boin813 .
        DELETE PROCEDURE h-boin813 NO-ERROR .
        ASSIGN h-boin813 = ? .
    END.

    IF l-ok = TRUE THEN DO:
        oOut = fnApiOK() .
        oOut:ADD("cod_estabel"      , docum-est.cod-estabel) .
        oOut:ADD("cod_cli_for"      , docum-est.cod-emitente) .
        oOut:ADD("serie"            , docum-est.serie-docto ) .
        oOut:ADD("nro_docto"        , docum-est.nro-docto ).
        oOut:ADD("nat_operacao"     , docum-est.nat-operacao ).
        oOut:ADD("di"               , tt-docum-est.declaracao-import ).
   END.
   RETURN .
END PROCEDURE .

PROCEDURE pi-get-by-di:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR oDocument   AS JsonObject NO-UNDO .
    DEF VAR oArray      AS JsonArray NO-UNDO .

    IF fnApiReadParam(oIn, "di") = "" THEN DO:
        oOut = fnApiErro("DI deve ser informada") .
        RETURN "NOK" .
    END.

    ASSIGN oArray = NEW JsonArray() .
    FOR EACH docum-est NO-LOCK
        WHERE docum-est.declaracao-import = fnApiReadParam(oIn, "di")
        AND   docum-est.serie-docto = fnApiReadParam(oIn, "serie")
        AND   docum-est.cod-emitente = INTEGER(fnApiReadParam(oIn, "cod_cli_for"))
        AND   docum-est.nat-operacao = fnApiReadParam(oIn, "nat_operacao")
        AND   docum-est.ce-atual = YES
        BY    docum-est.nro-docto 
        :
        oDocument = NEW JsonObject() .
        oDocument:ADD("cod_estabel"      , docum-est.cod-estabel) .
        oDocument:ADD("cod_cli_for"      , docum-est.cod-emitente) .
        oDocument:ADD("serie"            , docum-est.serie-docto ) .
        oDocument:ADD("nro_docto"        , docum-est.nro-docto ) .
        oDocument:ADD("nat_operacao"     , docum-est.nat-operacao ).
        oDocument:ADD("di"               , docum-est.declaracao-import ).
        oDocument:ADD("tot_peso"         , docum-est.tot-peso ).
        oDocument:ADD("valor_mercad"     , docum-est.valor-mercad ).
        oArray:ADD(oDocument) .
    END.
    oOut = fnApiOK() .
    oOut:ADD("records", oArray) .
    RETURN .
END PROCEDURE .



