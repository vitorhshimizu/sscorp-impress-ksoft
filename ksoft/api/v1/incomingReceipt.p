/*

dt-docum-est.tipo-documento:
"NF-e", 1,
"CT-e", 2,
"CT-e OS" ,3 ,
"NFS-e" ,4,
"NF3e", 5,
"Diversos", 6
*/

{utp/ut-api.i}

{utp/ut-api-action.i "pi-get-detail" "GET" "/detail*" }
{utp/ut-api-action.i "pi-post-confirm" "POST" "/confirm*" }
{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}
{utils/fnFormatDate.i}

PROCEDURE pi-find-doc-id:
    DEF INPUT PARAM p-docType   AS CHAR NO-UNDO .
    DEF INPUT PARAM p-docKey    AS CHAR NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR iTpDoc              AS INT NO-UNDO .

    IF p-docType = "NF-e" THEN DO:
        ASSIGN iTpDoc = 1 .
    END.
    ELSE IF p-docType = "CT-e" THEN DO:
        ASSIGN iTpDoc = 2 .
    END.
    ELSE IF p-docType = "NFS-e" THEN DO:
        ASSIGN iTpDoc = 4 .
    END.

    IF p-docType = "NFS-e" THEN DO:
        FIND FIRST dt-docum-est NO-LOCK
            WHERE dt-docum-est.serie-docto  = ENTRY(1,p-docKey,",")
            AND   dt-docum-est.nro-docto    = ENTRY(2,p-docKey,",")
            AND   dt-docum-est.cod-emitente = INT(ENTRY(3,p-docKey,","))
            AND   dt-docum-est.nat-operacao = ENTRY(4,p-docKey,",")
            AND   dt-docum-est.tipo-documento = iTpDoc
            AND   dt-docum-est.log-situacao = NO
            AND   dt-docum-est.log-cancelado = NO
            NO-ERROR .
        IF NOT AVAIL dt-docum-est THEN DO:
            oOut = fnApiErro("Documento n∆o encontrado") .
            RETURN "NOK" .
        END.
    END.
    ELSE DO:
        FIND FIRST dt-docum-est NO-LOCK
            WHERE dt-docum-est.chave-xml = p-docKey
            AND   dt-docum-est.tipo-documento = iTpDoc
            AND   dt-docum-est.log-situacao = NO
            AND   dt-docum-est.log-cancelado = NO
            NO-ERROR .
        IF NOT AVAIL dt-docum-est THEN DO:
            oOut = fnApiErro("Documento n∆o encontrado") .
            RETURN "NOK" .
        END.
    END.
END PROCEDURE .

PROCEDURE pi-get-detail:
    DEF INPUT  PARAM oIn        AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut       AS JsonObject NO-UNDO .

    DEF VAR oInvoice            AS JsonObject NO-UNDO .
    DEF VAR oInvoiceItem        AS JsonObject NO-UNDO .
    DEF VAR oInvoiceItemList    AS JsonArray NO-UNDO .

    RUN pi-find-doc-id
        (INPUT fnApiReadParam(oIn, "docType"), 
         INPUT fnApiReadParam(oIn, "docKey"),
         OUTPUT oOut )
        .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = dt-docum-est.cod-emitente
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Cliente/Fornecedor do documento n∆o encontrado") .
        RETURN .
    END.

    FIND FIRST estabelec NO-LOCK
        WHERE estabelec.cod-estabel = dt-docum-est.cod-estabel
        NO-ERROR .
    IF NOT AVAIL estabelec THEN DO:
        oOut = fnApiErro("Estabelecimento do documento n∆o encontrado") .
        RETURN .
    END.

    RUN pi-populate-document(OUTPUT oInvoice) .

    oInvoiceItemList = NEW JsonArray() .
    FOR EACH dt-it-docum-est NO-LOCK
        WHERE dt-it-docum-est.serie-docto = dt-docum-est.serie-docto
        AND   dt-it-docum-est.nro-docto = dt-docum-est.nro-docto
        AND   dt-it-docum-est.cod-emitente = dt-docum-est.cod-emitente
        AND   dt-it-docum-est.nat-operacao = dt-docum-est.nat-operacao
        :
        FIND FIRST ITEM NO-LOCK
            WHERE ITEM.it-codigo = dt-it-docum-est.item-ems
            NO-ERROR .

        oInvoiceItem = NEW JsonObject() .
        oInvoiceItem:ADD("sequencia"            , dt-it-docum-est.sequencia) .
        oInvoiceItem:ADD("it_forn"              , dt-it-docum-est.it-codigo) .
        oInvoiceItem:ADD("desc_forn"            , dt-it-docum-est.char-2) .
        oInvoiceItem:ADD("ncm_forn"             , dt-it-docum-est.class-fiscal-orig) .
        oInvoiceItem:ADD("ean_forn"             , dt-it-docum-est.cod-ean-fornec) .
        oInvoiceItem:ADD("it_codigo"            , dt-it-docum-est.item-ems) .
        oInvoiceItem:ADD("desc_item"            , IF AVAIL ITEM THEN ITEM.desc-item ELSE "") .
        oInvoiceItem:ADD("ncm"                  , dt-it-docum-est.class-fiscal) .
        oInvoiceItem:ADD("ean"                  , dt-it-docum-est.cod-ean-trib) .
        oInvoiceItem:ADD("qt_forn"              , dt-it-docum-est.qt-do-forn) .
        oInvoiceItem:ADD("un"                   , dt-it-docum-est.un) .
        oInvoiceItem:ADD("preco_unit"           , dt-it-docum-est.preco-unit) .
        oInvoiceItem:ADD("preco_total"          , dt-it-docum-est.preco-total) .
        oInvoiceItem:ADD("narrativa"            , dt-it-docum-est.narrativa) .
        oInvoiceItem:ADD("numero_ordem_forn"    , dt-it-docum-est.numero-ordem-forn) .
        oInvoiceItem:ADD("numero_ordem"         , dt-it-docum-est.numero-ordem) .

        oInvoiceItemList:ADD(oInvoiceItem) .
    END.

    DEF VAR mArqOut         AS MEMPTR NO-UNDO.
    DEF VAR lcXMLBase64     AS LONGCHAR NO-UNDO .

    COPY-LOB FROM dt-docum-est.arq-xml TO mArqOut NO-ERROR .
    ASSIGN lcXMLBase64 = BASE64-ENCODE(mArqOut) NO-ERROR .

    oInvoice:ADD("itens"    , oInvoiceItemList) .
    oInvoice:ADD("XML"      , lcXMLBase64) .

    oOut = fnApiOK() .
    oOut:ADD("document" , oInvoice) .
END PROCEDURE .

PROCEDURE pi-post-confirm:
    DEF INPUT  PARAM oIn        AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut       AS JsonObject NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .

    RUN pi-find-doc-id
        (INPUT fnApiGetChar(oIn, "docType"), 
         INPUT fnApiGetChar(oIn, "docKey"),
         OUTPUT oOut )
        .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        FIND CURRENT dt-docum-est EXCLUSIVE-LOCK .
        ASSIGN dt-docum-est.l-documento-confir = fnApiGetLogical(oIn, "confirm") .
        FIND CURRENT dt-docum-est NO-LOCK .
    END.

    oOut = fnApiOK() .
END PROCEDURE .

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn        AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut       AS JsonObject NO-UNDO .

    DEF VAR oInvoice            AS JsonObject NO-UNDO .
    DEF VAR oInvoiceList        AS JsonArray NO-UNDO .

    DEF VAR dtEmissaoIni        AS DATE NO-UNDO .
    DEF VAR dtEmissaoFim        AS DATE NO-UNDO .

    ASSIGN dtEmissaoIni = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "IssueStartDate")) NO-ERROR .
    IF dtEmissaoIni = ? THEN ASSIGN dtEmissaoIni = TODAY .

    ASSIGN dtEmissaoFim = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "IssueEndDate")) NO-ERROR .
    IF dtEmissaoFim = ? THEN ASSIGN dtEmissaoFim = TODAY .

    oInvoiceList = NEW JsonArray() .
    FOR EACH dt-docum-est NO-LOCK
        WHERE dt-docum-est.dt-emissao >= dtEmissaoIni
        AND   dt-docum-est.dt-emissao <= dtEmissaoFim
        AND   (dt-docum-est.tipo-documento = 1 /* NF-e */ OR
               dt-docum-est.tipo-documento = 2 /* CT-e */ OR
               dt-docum-est.tipo-documento = 4 /* NFS-e */  )
        AND   dt-docum-est.log-situacao = NO
        AND   dt-docum-est.log-cancelado = NO
        BY dt-docum-est.dt-emissao
        :
        FIND FIRST emitente NO-LOCK
            WHERE emitente.cod-emitente = dt-docum-est.cod-emitente
            NO-ERROR .
        IF NOT AVAIL emitente THEN NEXT .

        FIND FIRST estabelec NO-LOCK
            WHERE estabelec.cod-estabel = dt-docum-est.cod-estabel
            NO-ERROR .
        IF NOT AVAIL estabelec THEN NEXT .

        RUN pi-populate-document(OUTPUT oInvoice) .
        oInvoiceList:ADD(oInvoice) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("incomingReceipts" , oInvoiceList) .
END PROCEDURE .

PROCEDURE pi-populate-document
    :
    DEF OUTPUT PARAM p-doc  AS JsonObject NO-UNDO .

    DEF VAR cTpDoc      AS CHAR NO-UNDO .

    IF dt-docum-est.tipo-documento = 1 THEN DO:
        ASSIGN cTpDoc = "NF-e" .
    END.
    ELSE IF dt-docum-est.tipo-documento = 2 THEN DO:
        ASSIGN cTpDoc = "CT-e" .
    END.
    ELSE IF dt-docum-est.tipo-documento = 4 THEN DO:
        ASSIGN cTpDoc = "NFS-e" .
    END.
    ELSE DO:
        ASSIGN cTpDoc = "Outras" .
    END.

    p-doc = NEW JsonObject() .
    p-doc:ADD("doc_type"                , cTpDoc) .
    p-doc:ADD("doc_key"                 , dt-docum-est.chave-xml) .
    p-doc:ADD("dt_emissao"              , dt-docum-est.dt-emissao) .
    p-doc:ADD("serie"                   , dt-docum-est.serie-docto) .
    p-doc:ADD("nro_docto"               , dt-docum-est.nro-docto) .
    p-doc:ADD("emitente_codigo"         , dt-docum-est.cod-emitente) .
    p-doc:ADD("emitente_cnpj"           , emitente.cgc) .
    p-doc:ADD("emitente_nome_emit"      , emitente.nome-emit) .
    p-doc:ADD("emitente_nome_abrev"     , emitente.nome-abrev) .
    p-doc:ADD("dest_codigo"             , dt-docum-est.cod-estabel) .
    p-doc:ADD("dest_cnpj"               , estabelec.cgc) .
    p-doc:ADD("dest_nome"               , estabelec.nome) .
    p-doc:ADD("nat_operacao"            , dt-docum-est.nat-operacao) .
    p-doc:ADD("tot_valor"               , dt-docum-est.tot-valor) .
    p-doc:ADD("l_confirmado"            , dt-docum-est.l-documento-confir) .

    RETURN .
END PROCEDURE .



