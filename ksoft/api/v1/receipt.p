/*
*/

{utp/ut-api.i}
                                   
{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-action.i "pi-post" "POST" "*" }
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

DEF TEMP-TABLE tt-dupli-apagar NO-UNDO LIKE dupli-apagar
    FIELD r-rowid   AS ROWID
    .

{inbo/boin366.i tt2-rat-docum }
{inbo/boin366.i1 tt-imposto}

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

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR cDocto  AS CHAR NO-UNDO .

    ASSIGN cDocto = fnApiReadParam(oIn, "nro_docto") .
    IF LENGTH(cDocto) < 7 THEN DO:
        ASSIGN cDocto = FILL("0", 7 - LENGTH(cDocto)) + cDocto .
    END.

    FIND FIRST docum-est NO-LOCK
        WHERE docum-est.serie-docto     = fnApiReadParam(oIn, "serie")
        AND   docum-est.nro-docto       = cDocto
        AND   docum-est.cod-emitente    = INT(fnApiReadParam(oIn, "cod_cli_for"))
        AND   docum-est.nat-operacao    = fnApiReadParam(oIn, "nat_operacao")
        NO-ERROR .
    IF NOT AVAIL docum-est THEN DO:
        oOut = fnApiErro("Documento n∆o encontrado.") .
        RETURN "NOK".
    END.

    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .

    ASSIGN oItensArray = NEW JsonArray() .
    FOR EACH item-doc-est NO-LOCK OF docum-est
        :
        FIND FIRST movto-estoq NO-LOCK
            WHERE movto-estoq.serie-docto   = docum-est.serie-docto
            AND   movto-estoq.nro-docto     = docum-est.nro-docto   
            AND   movto-estoq.cod-emitente  = docum-est.cod-emitente
            AND   movto-estoq.nat-operacao  = docum-est.nat-operacao
            AND   movto-estoq.sequen-nf     = item-doc-est.sequencia
            NO-ERROR .

        FIND FIRST ITEM NO-LOCK
            WHERE ITEM.it-codigo = movto-estoq.it-codigo
            .

        ASSIGN oItem = NEW JsonObject() .
        oItem:ADD("sequencia"   , item-doc-est.sequencia) .
        oItem:ADD("it_codigo"   , item-doc-est.it-codigo) .
        oItem:ADD("quantidade"  , item-doc-est.quantidade) .
        oItem:ADD("un"          , ITEM.un) .
        oItem:ADD("stock_value" , ROUND( (movto-estoq.valor-mat-m[1] + movto-estoq.valor-mob-m[1] + movto-estoq.valor-ggf-m[1]) / 
                                         item-doc-est.quantidade , 2 )) .
        oItensArray:ADD(oItem) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("cod_estabel"      , docum-est.cod-estabel) .
    oOut:ADD("cod_cli_for"      , docum-est.cod-emitente) .
    oOut:ADD("serie"            , docum-est.serie-docto ) .
    oOut:ADD("nro_docto"        , docum-est.nro-docto ) .
    oOut:ADD("nat_operacao"     , docum-est.nat-operacao ).
    oOut:ADD("confirmed"        , docum-est.ce-atual ).
    oOut:ADD("items"            , oItensArray ).
END PROCEDURE .

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF BUFFER ref-docum-est    FOR docum-est .

    DEF VAR l-ok                    AS LOGICAL NO-UNDO .
    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .

    DEF VAR cDocto          AS CHAR NO-UNDO .
    DEF VAR deVlTotalItens  AS DECIMAL NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .

    oIn:WriteFile("C:\totvs\ksoft_log\POST_receipt\" + fnNowToString() + ".json", YES, "UTF-8") .

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

    IF fnApiGetInt(oHeader, "cod_transp") <> 0 THEN DO:
        FIND FIRST transporte NO-LOCK
            WHERE transporte.cod-transp = fnApiGetInt(oHeader, "cod_transp")
            NO-ERROR .
        IF NOT AVAIL transporte THEN DO:
            oOut = fnApiErro("Transportador n∆o encontrado") .
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

    DEF VAR h-boin090   AS HANDLE NO-UNDO .
    RUN inbo/boin090.p PERSISTENT SET h-boin090 .
    RUN openQueryStatic IN h-boin090(INPUT "Main") .

    DEF VAR h-boin176   AS HANDLE NO-UNDO .
    RUN inbo/boin176.p PERSISTENT SET h-boin176 .
    RUN openQueryStatic IN h-boin176(INPUT "Main") .

    DEF VAR h-boin366   AS HANDLE NO-UNDO .
    RUN inbo/boin366.p PERSISTENT SET h-boin366 .
    RUN openQueryStatic IN h-boin366(INPUT "Main") .

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
            tt-docum-est.serie-docto    = fnApiGetChar(oHeader, "serie")
            tt-docum-est.nro-docto      = cDocto
            tt-docum-est.cod-emitente   = emitente.cod-emitente
            tt-docum-est.nat-operacao   = fnApiGetChar(oHeader, "nat_operacao")
            tt-docum-est.cod-estabel    = fnApiGetChar(oHeader, "cod_estabel")
            tt-docum-est.esp-docto      = 21 /* NFE */
            tt-docum-est.tipo-docto     = 1 /* Entrada */
            tt-docum-est.cod-observa    = fnApiGetInt(oHeader, "cod_observa")
            tt-docum-est.dt-emissao     = fnApiGetDate(oHeader, "dt_emissao")
            tt-docum-est.dt-trans       = fnApiGetDate(oHeader, "dt_trans")
            tt-docum-est.observacao     = fnApiGetChar(oHeader, "observacao")
            .
    
        RUN emptyRowErrors IN h-boin090 .
        RUN setRecord IN h-boin090(INPUT TABLE tt-docum-est) .
        RUN createRecord IN h-boin090 .
        RUN getRowErrors IN h-boin090(OUTPUT TABLE RowErrors) .
        FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
        IF AVAIL RowErrors THEN DO:
            oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
            UNDO , LEAVE .
        END.

        FIND FIRST docum-est NO-LOCK
            WHERE docum-est.serie-docto     = tt-docum-est.serie-docto
            AND   docum-est.nro-docto       = tt-docum-est.nro-docto   
            AND   docum-est.cod-emitente    = tt-docum-est.cod-emitente
            AND   docum-est.nat-operacao    = tt-docum-est.nat-operacao
            .

        RUN goToKey IN h-boin090
            (tt-docum-est.serie-docto,
             tt-docum-est.nro-docto,
             tt-docum-est.cod-emitente,
             tt-docum-est.nat-operacao)
            .

        ASSIGN deVlTotalItens = 0 .
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

            ASSIGN deVlTotalItens = deVlTotalItens + fnApiGetDecimal(oItem, "preco_total") .

            IF natur-oper.nota-rateio = YES THEN DO:
                IF fnApiGetChar(oItem, "ref_cod_chave_nfe") = "" THEN DO:
                    oOut = fnApiErro("Documento de Rateio Ref n∆o foi informado, Pos:" + STRING(iCont) ) .
                    UNDO TRA1, LEAVE TRA1.
                END.

                FIND FIRST ref-docum-est NO-LOCK
                    WHERE ref-docum-est.cod-chave-aces-nf-eletro = fnApiGetChar(oItem, "ref_cod_chave_nfe")
                    NO-ERROR .
                IF NOT AVAIL ref-docum-est THEN DO:
                    oOut = fnApiErro("Documento de Rateio Ref n∆o encontrado, Pos:" + STRING(iCont) ) .
                    UNDO TRA1, LEAVE TRA1.
                END.

                EMPTY TEMP-TABLE tt2-rat-docum .
                CREATE tt2-rat-docum . ASSIGN 
                    tt2-rat-docum.cod-emitente = docum-est.cod-emitente
                    tt2-rat-docum.serie-docto  = docum-est.serie-docto
                    tt2-rat-docum.nro-docto    = docum-est.nro-docto
                    tt2-rat-docum.nat-operacao = docum-est.nat-operacao
                    tt2-rat-docum.nf-emitente  = ref-docum-est.cod-emitente
                    tt2-rat-docum.nf-serie     = ref-docum-est.serie-docto
                    tt2-rat-docum.nf-nro       = ref-docum-est.nro-docto
                    tt2-rat-docum.nf-nat-oper  = ref-docum-est.nat-operacao
                    tt2-rat-docum.dec-1        = fnApiGetDecimal(oItem, "preco_total")
                    .
                RUN emptyRowErrors IN h-boin366 .        
                RUN setRecord IN h-boin366(INPUT TABLE tt2-rat-docum) .
                RUN createRecord IN h-boin366 .
                RUN getRowErrors IN h-boin366(OUTPUT TABLE RowErrors) .
                FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
                IF AVAIL RowErrors THEN DO:
                    oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                    UNDO TRA1, LEAVE TRA1.
                END.
            END.
            ELSE DO:
                EMPTY TEMP-TABLE tt-item-doc-est .
                CREATE tt-item-doc-est . ASSIGN
                    tt-item-doc-est.serie-docto             = tt-docum-est.serie-docto 
                    tt-item-doc-est.nro-docto               = tt-docum-est.nro-docto   
                    tt-item-doc-est.cod-emitente            = tt-docum-est.cod-emitente
                    tt-item-doc-est.nat-operacao            = tt-docum-est.nat-operacao
                    tt-item-doc-est.sequencia               = iCont * 10
                    tt-item-doc-est.it-codigo               = ITEM.it-codigo
                    tt-item-doc-est.quantidade              = fnApiGetDecimal(oItem, "quantidade")
                    tt-item-doc-est.un                      = fnApiGetChar(oItem, "un_for")
                    tt-item-doc-est.qt-do-forn              = fnApiGetDecimal(oItem, "quantidade_for")
                    tt-item-doc-est.preco-unit              = fnApiGetDecimal(oItem, "preco_unit")
                    tt-item-doc-est.preco-total             = fnApiGetDecimal(oItem, "preco_total")
                    tt-item-doc-est.narrativa               = fnApiGetChar(oItem, "narrativa")
                    tt-item-doc-est.ct-codigo               = fnApiGetChar(oItem, "ct_codigo")
                    tt-item-doc-est.sc-codigo               = fnApiGetChar(oItem, "sc_codigo")
                    tt-item-doc-est.peso-bruto-item         = fnApiGetDecimal(oItem, "peso_bruto")
                    tt-item-doc-est.peso-liquido            = fnApiGetDecimal(oItem, "peso_liquido")
                    tt-item-doc-est.peso-liquido-item       = fnApiGetDecimal(oItem, "peso_liquido")
                    //Puxar da Natureza tt-item-doc-est.baixa-ce                = NO
                    tt-item-doc-est.cd-trib-ipi             = 1
                    tt-item-doc-est.base-ipi                = fnApiGetDecimal(oItem, "base_ipi")
                    tt-item-doc-est.aliquota-ipi            = fnApiGetDecimal(oItem, "p_ipi")
                    tt-item-doc-est.valor-ipi               = fnApiGetDecimal(oItem, "vl_ipi")
                    tt-item-doc-est.class-fiscal            = ITEM.class-fiscal
                    tt-item-doc-est.cod-unid-negoc          = fnApiGetChar(oItem, "cod_unid_negoc")
                    .

                /* Se conta contabil, centro de custo ou unidade negoc for vazia, puxar do item */
                IF tt-item-doc-est.ct-codigo = "" THEN DO:
                    ASSIGN tt-item-doc-est.ct-codigo = ITEM.ct-codigo .
                END.
                IF tt-item-doc-est.sc-codigo = "" THEN DO:
                    ASSIGN tt-item-doc-est.sc-codigo = ITEM.sc-codigo .
                END.
                IF tt-item-doc-est.cod-unid-negoc = "" THEN DO:
                    ASSIGN tt-item-doc-est.cod-unid-negoc = ITEM.cod-unid-negoc .
                END.

                /* Se no cadastro do item a NCM for vazio puxar do Loader  */
                IF tt-item-doc-est.class-fiscal = "" THEN DO:
                    FOR FIRST dt-it-docum-est NO-LOCK
                        WHERE dt-it-docum-est.serie-docto = tt-item-doc-est.serie-docto
                        AND   dt-it-docum-est.nro-docto = tt-item-doc-est.nro-docto
                        AND   dt-it-docum-est.cod-emitente = tt-item-doc-est.cod-emitente
                        AND   dt-it-docum-est.sequencia = tt-item-doc-est.sequencia / 10
                        AND   dt-it-docum-est.class-fiscal-orig <> ""
                        :
                        ASSIGN tt-item-doc-est.class-fiscal = dt-it-docum-est.class-fiscal-orig .
                    END.
                END.

                /* Se ainda assim for vazio, preenche com 0  */
                IF tt-item-doc-est.class-fiscal = "" THEN DO:
                    ASSIGN tt-item-doc-est.class-fiscal = "00000000" .
                END.
                    
                RUN emptyRowErrors IN h-boin176 .
                RUN setRecord IN h-boin176(INPUT TABLE tt-item-doc-est) .
                RUN createRecord IN h-boin176 .
                RUN getRowErrors IN h-boin176(OUTPUT TABLE RowErrors) .
                FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
                IF AVAIL RowErrors THEN DO:
                    oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                    UNDO TRA1, LEAVE TRA1.
                END.
            END.
        END.

        IF natur-oper.nota-rateio = YES THEN DO:
            FIND CURRENT docum-est .

            /* Se for CTE, puxar Municipio Origem e Destino do Loader */
            FOR FIRST dt-docum-est NO-LOCK
                WHERE dt-docum-est.cod-emitente = docum-est.cod-emitente
                AND   dt-docum-est.serie-docto = docum-est.serie-docto
                AND   dt-docum-est.nro-docto = docum-est.nro-docto
                :
                OVERLAY(docum-est.char-2, 151, 1) =  SUBSTRING(dt-docum-est.char-2, 151, 1) . /* Tipo CTe */
                OVERLAY(docum-est.char-2, 236, 10) = SUBSTRING(dt-docum-est.char-2, 236, 10) . /* Cod Munic Dest */
                OVERLAY(docum-est.char-2, 246, 10) = SUBSTRING(dt-docum-est.char-2, 246, 10) . /* Cod Munic Orig */
            END.

            /* Regra da aba Rateio para gerar os itens */
            ASSIGN docum-est.valor-mercad = deVlTotalItens .

            EMPTY TEMP-TABLE tt-imposto .
            CREATE tt-imposto . ASSIGN
                //tt-imposto.aliquota-ipi    = natur-oper.aliquota-ipi
                //tt-imposto.cd-trib-ipi     = natur-oper.cd-trib-ipi
                //tt-imposto.perc-red-ipi    = natur-oper.perc-red-ipi
                tt-imposto.aliquota-icm    = natur-oper.aliquota-icm
                tt-imposto.cd-trib-icm     = natur-oper.cd-trib-icm
                tt-imposto.perc-red-icm    = natur-oper.perc-red-icm
                tt-imposto.aliquota-pis    = DEC(SUBSTRING(natur-oper.char-1,76,5))
                tt-imposto.aliquota-cofins = DEC(SUBSTRING(natur-oper.char-1,81,5))
                tt-imposto.cd-trib-pis     = INT(SUBSTRING(natur-oper.char-1,86,1)) 
                tt-imposto.cd-trib-cofins  = INT(SUBSTRING(natur-oper.char-1,87,1))
                .

            RUN setHandleDocumEst IN h-boin366(INPUT h-boin090) .
            RUN setHandleItemDocumEst IN h-boin366(INPUT h-boin176) .
            RUN linkToDocumEst IN h-boin366(INPUT h-boin090) .

            RUN setTTImposto IN h-boin366(INPUT TABLE tt-imposto) .
            RUN setAliqIBSCbs IN h-boin366(INPUT 0, INPUT 0, INPUT 0) .
            RUN setDoacao IN h-boin366(INPUT NO) .
            RUN createRateio in h-boin366 .
            RUN getRowErrors IN h-boin366(OUTPUT TABLE RowErrors) .
            FIND FIRST RowErrors NO-LOCK WHERE RowErrors.ErrorSubType = "ERROR" NO-ERROR .
            IF AVAIL RowErrors THEN DO:
                oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
                UNDO TRA1, LEAVE TRA1.
            END.
        END.

        //Totaliza
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

    IF VALID-HANDLE(h-boin366) THEN DO:
        RUN destroy IN h-boin366.
        DELETE PROCEDURE h-boin366 NO-ERROR .
        ASSIGN h-boin366 = ? .
    END.

    IF l-ok = TRUE THEN DO:
        oOut = fnApiOK() .
        oOut:ADD("cod_estabel"      , fnApiGetChar(oHeader, "cod_estabel") ).
        oOut:ADD("cod_cli_for"      , emitente.cod-emitente).
        oOut:ADD("serie"            , fnApiGetChar(oHeader, "serie") ).
        oOut:ADD("nro_docto"        , fnApiGetChar(oHeader, "nro_docto") ).
        oOut:ADD("nat_operacao"     , fnApiGetChar(oHeader, "nat_operacao") ).
   END.
   RETURN .
END PROCEDURE .



