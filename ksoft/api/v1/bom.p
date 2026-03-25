/*
*/

{utp/ut-api.i}

{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

PROCEDURE pi-find-item-id:
    DEF INPUT PARAM p-id    AS CHAR NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    IF p-id = "" THEN DO:
        oOut = fnApiErro("id n∆o foi informado.") .
        RETURN "NOK".
    END.

    FIND FIRST ITEM NO-LOCK
        WHERE ITEM.it-codigo = p-id
        NO-ERROR .
    IF NOT AVAIL ITEM THEN DO:
        oOut = fnApiErro("Item/Produto n∆o foi encontrado. Item: " + p-id) .
        RETURN "NOK".
    END.

    RETURN "OK" .
END PROCEDURE .

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF BUFFER bf-item  FOR ITEM .

    DEF VAR deQtItem    AS DECIMAL NO-UNDO .
    DEF VAR oCompList   AS JsonArray NO-UNDO .
    DEF VAR oComp       AS JsonObject NO-UNDO .

    RUN pi-find-item-id(INPUT fnApiReadParam(oIn, "id"), OUTPUT oOut) .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    oCompList = NEW JsonArray() .
    FOR EACH estrutura NO-LOCK OF ITEM
        WHERE estrutura.data-inicio <= TODAY
        AND   estrutura.data-termino >= TODAY
        :
        FIND FIRST bf-item NO-LOCK WHERE bf-item.it-codigo = estrutura.es-codigo .

        ASSIGN deQtItem = estrutura.qtd-item .

        oComp = NEW JsonObject() .
        oComp:ADD("es_codigo"       , estrutura.es-codigo) .
        oComp:ADD("desc_comp"       , bf-item.desc-item) .
        oComp:ADD("un_comp"         , bf-item.un) .
        oComp:ADD("qtd_comp"        , estrutura.qtd-compon) .
        oComp:ADD("qtd_item"        , estrutura.qtd-item) .

        oCompList:ADD(oComp) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("it_codigo"        , ITEM.it-codigo) .
    oOut:ADD("desc_item"        , ITEM.desc-item) .
    oOut:ADD("un"               , ITEM.un) .
    oOut:ADD("qtd_item"         , deQtItem) .
    oOut:ADD("components"       , oCompList) .
END.

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn  AS JsonObject NO-UNDO.
    DEF OUTPUT PARAM oOut AS JsonObject NO-UNDO.

    DEF BUFFER bf-item  FOR ITEM .

    DEF VAR iContItem   AS INT NO-UNDO .
    DEF VAR oItensList  AS JsonArray NO-UNDO .
    DEF VAR oItem       AS JsonObject NO-UNDO .
    DEF VAR iContComp   AS INT NO-UNDO .
    DEF VAR oCompList   AS JsonArray NO-UNDO .
    DEF VAR oComp       AS JsonObject NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oItensList = fnApiGetArray(oIn, "itens") .
    DO iContItem = 1 TO oItensList:LENGTH
        :
        ASSIGN oItem = oItensList:GetJsonObject(iContItem) .

        RUN pi-find-item-id(INPUT fnApiGetChar(oItem, "it_codigo"), OUTPUT oOut) .
        IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

        TRA1:
        DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
            :
            FOR EACH estrutura EXCLUSIVE-LOCK OF ITEM
                :
                FOR EACH alternativo EXCLUSIVE-LOCK OF estrutura
                    :
                    DELETE alternativo .
                END.
                DELETE estrutura .
            END.

            ASSIGN oCompList = fnApiGetArray(oItem, "components") .
            DO iContComp = 1 TO oCompList:LENGTH
                :
                ASSIGN oComp = oCompList:GetJsonObject(iContComp) .

                FIND FIRST bf-item NO-LOCK 
                    WHERE bf-item.it-codigo = fnApiGetChar(oComp, "es_codigo")
                    AND   bf-item.cod-obsoleto = 1 /* Ativo */
                    AND   bf-item.it-codigo <> ""
                    NO-ERROR .
                IF NOT AVAIL bf-item THEN DO:
                    oOut = fnApiErro("Item/Produto do componente n∆o foi encontrado, ou n∆o est† ativo. Item: " + fnApiGetChar(oComp, "es_codigo")) .
                    UNDO , RETURN "NOK".
                END.

                CREATE estrutura . ASSIGN
                    estrutura.it-codigo     = ITEM.it-codigo
                    estrutura.sequencia     = iContComp * 10
                    estrutura.es-codigo     = bf-item.it-codigo
                    estrutura.fantasma      = NO
                    estrutura.data-inicio   = DATE("01/01/2025")
                    estrutura.data-termino  = DATE("31/12/9999")
                    estrutura.qtd-item      = fnApiGetDecimal(oItem, "qtd_item")
                    estrutura.quant-liquid  = fnApiGetDecimal(oComp , "qtd_comp")
                    estrutura.qtd-compon    = fnApiGetDecimal(oComp , "qtd_comp")
                    estrutura.quant-usada   = estrutura.qtd-compon / estrutura.qtd-item
                    .
            END.
        END.
    END.

    oOut = fnApiOK() .
END.

