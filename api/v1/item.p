/*
*/

USING PROGRESS.Lang.ERROR.
USING com.totvs.framework.api.JsonApiResponseBuilder .

{utp/ut-api.i}

{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-action.i "pi-post" "POST" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

{cdp/cdapi300.i1} /* tt-versao-integr tt-erros-geral */ 
{cdp/cdapi244.i} /* tt-item tt-item-aux */

/* Exporta Item x Estab */
DEF TEMP-TABLE tt-estabel NO-UNDO
    FIELD cod-estabel AS CHAR
    FIELD log-exporta AS LOG FORMAT "*/ "
    INDEX codigo IS PRIMARY UNIQUE cod-estabel
    INDEX exporta log-exporta
    .

DEF NEW SHARED TEMP-TABLE tt-old-item NO-UNDO LIKE ITEM USE-INDEX codigo .
DEF NEW SHARED TEMP-TABLE tt-old-item-mat NO-UNDO LIKE item-mat .
/**/

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
        oOut = fnApiErro("Item/Produto n∆o foi encontrado.") .
        RETURN "NOK".
    END.

    RETURN "OK" .
END PROCEDURE .

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    RUN pi-find-item-id(INPUT fnApiReadParam(oIn, "id"), OUTPUT oOut) .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    oOut = fnApiOK() .
    oOut:ADD("codigo"           , ITEM.it-codigo) .
    oOut:ADD("desc_item"        , ITEM.desc-item) .
    oOut:ADD("ge_codigo"        , ITEM.ge-codigo) .
    oOut:ADD("fm_codigo"        , ITEM.fm-codigo) .
    oOut:ADD("fm_cod_com"       , ITEM.fm-cod-com) .
    oOut:ADD("un"               , ITEM.un) .
    oOut:ADD("cod_obsoleto"     , ITEM.cod-obsoleto) .
    oOut:ADD("narrativa"        , ITEM.narrativa) .
    oOut:ADD("ncm"              , ITEM.class-fiscal) .
    oOut:ADD("cod_unid_negoc"   , ITEM.cod-unid-negoc) .
    oOut:ADD("peso_bruto"       , ITEM.peso-bruto) .
    oOut:ADD("peso_liquido"     , ITEM.peso-liquido) .
    oOut:ADD("altura"           , ITEM.altura) .
    oOut:ADD("largura"          , ITEM.largura) .
    oOut:ADD("comprim"          , ITEM.comprim) .
    oOut:ADD("ind_item_fat"     , ITEM.ind-item-fat) .
END.

PROCEDURE pi-post:
    DEF INPUT  PARAM oIn  AS JsonObject NO-UNDO.
    DEF OUTPUT PARAM oOut AS JsonObject NO-UNDO.

    ASSIGN oIn = fnApiReadBody(oIn) .

    FIND FIRST classif-fisc NO-LOCK
        WHERE classif-fisc.class-fiscal = fnApiGetChar(oIn, "ncm")
        NO-ERROR .
    IF NOT AVAIL classif-fisc THEN DO:
        oOut = fnApiErro("Classificaá∆o Fiscal n∆o encontrada") .
        RETURN .
    END.

    FIND FIRST unid-negoc NO-LOCK
        WHERE unid-negoc.cod-unid-negoc = fnApiGetChar(oIn, "cod_unid_negoc")
        NO-ERROR .
    IF NOT AVAIL unid-negoc THEN DO:
        oOut = fnApiErro("Unidade de Negocio n∆o encontrada") .
        RETURN .
    END.

    IF fnApiGetDecimal(oIn, "peso_liquido") > fnApiGetDecimal(oIn, "peso_bruto") THEN DO:
        oOut = fnApiErro("Peso Liquido n∆o pode ser maior que o Peso Bruto") .
        RETURN .
    END.

    RUN pi-find-item-id(INPUT fnApiGetChar(oIn, "codigo"), OUTPUT oOut) .

    EMPTY TEMP-TABLE tt-versao-integr .
    EMPTY TEMP-TABLE tt-item .

    CREATE tt-versao-integr. ASSIGN 
        tt-versao-integr.cod-versao-integr = 1
        .

    CREATE tt-item . ASSIGN
        tt-item.ind-tipo-movto          = IF NOT AVAIL ITEM THEN 1 /* Criaá∆o */ ELSE 2 /* Alteraá∆o */ 
        tt-item.it-codigo               = fnApiGetChar(oIn, "codigo")
        tt-item.desc-item               = UPPER(fnApiGetChar(oIn, "desc_item"))        
        tt-item.ge-codigo               = fnApiGetInt(oIn, "ge_codigo")              
        tt-item.fm-codigo               = fnApiGetChar(oIn, "fm_codigo")
        tt-item.fm-cod-com              = fnApiGetChar(oIn, "fm_cod_com")
        tt-item.un                      = fnApiGetChar(oIn, "un")
        tt-item.cod-obsoleto            = fnApiGetInt(oIn, "cod_obsoleto")
        tt-item.narrativa               = fnApiGetChar(oIn, "narrativa") 
        tt-item.class-fiscal            = fnApiGetChar(oIn, "ncm")
        tt-item.cod-unid-negoc          = fnApiGetChar(oIn, "cod_unid_negoc")
        tt-item.peso-bruto              = fnApiGetDecimal(oIn, "peso_bruto")
        tt-item.peso-liquido            = fnApiGetDecimal(oIn, "peso_liquido")
        tt-item.altura                  = fnApiGetDecimal(oIn, "altura")
        tt-item.largura                 = fnApiGetDecimal(oIn, "largura")
        tt-item.comprim                 = fnApiGetDecimal(oIn, "comprim")
        tt-item.ind-item-fat            = fnApiGetLogical(oIn, "ind_item_fat")
        tt-item.cod-estabel             = "101"
        .

    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        RUN cdp/cdapi344.p
            (INPUT TABLE tt-versao-integr,
             OUTPUT TABLE tt-erros-geral,
             INPUT-OUTPUT TABLE tt-item)
            .
        FIND FIRST tt-item .
        IF tt-item.des-erro <> "" THEN DO:
            oOut = fnApiErro(STRING(tt-item.cod-erro) + " - " + tt-item.des-erro) .
            RETURN .
        END.

        /* Campos nao alterados via API */
        FIND FIRST ITEM WHERE ITEM.it-codigo = tt-item.it-codigo .

        ASSIGN 
            ITEM.class-fiscal       = fnApiGetChar(oIn, "ncm")
            ITEM.cod-unid-negoc     = fnApiGetChar(oIn, "cod_unid_negoc")
            ITEM.peso-bruto         = fnApiGetDecimal(oIn, "peso_bruto")
            ITEM.peso-liquido       = fnApiGetDecimal(oIn, "peso_liquido")
            ITEM.altura             = fnApiGetDecimal(oIn, "altura")
            ITEM.largura            = fnApiGetDecimal(oIn, "largura")
            ITEM.comprim            = fnApiGetDecimal(oIn, "comprim")
            ITEM.ind-item-fat       = fnApiGetLogical(oIn, "ind_item_fat")
            .

        /* Exporta item x estab */
        EMPTY TEMP-TABLE tt-estabel .
        EMPTY TEMP-TABLE tt-old-item .
        EMPTY TEMP-TABLE tt-old-item-mat .

        FOR EACH estabelec NO-LOCK
            :
            CREATE tt-estabel . ASSIGN
                tt-estabel.cod-estabel = estabelec.cod-estabel
                tt-estabel.log-exporta = YES
                .
        END.
        
        CREATE tt-old-item . 
        BUFFER-COPY ITEM TO tt-old-item .
        
        FIND FIRST item-mat WHERE item-mat.it-codigo = ITEM.it-codigo .

        CREATE tt-old-item-mat .
        BUFFER-COPY item-mat TO tt-old-item-mat .

        RUN cdp/cd0138b.p
            (INPUT ITEM.it-codigo ,
             INPUT "M" ,
             INPUT YES ,
             INPUT YES ,
             INPUT YES ,
             INPUT "cd0138.w" ,
             INPUT TABLE tt-estabel ,
             INPUT TABLE tt-old-item ,
             INPUT TABLE tt-old-item-mat )
            .
        FOR EACH item-uni-estab WHERE item-uni-estab.it-codigo = ITEM.it-codigo
            :
            ASSIGN item-uni-estab.nat-despesa       = ITEM.nat-despesa .
            ASSIGN item-uni-estab.tp-desp-padrao    = ITEM.tp-desp-padrao .
            ASSIGN item-uni-estab.cod-unid-negoc    = ITEM.cod-unid-negoc .
        END.
        /* */
    END.

    oOut = fnApiOK() .

    CATCH oE AS ERROR:
        oOut = fnApiErro(oE:GetMessage(1)) .  
    END CATCH.
    FINALLY:
    END.
END.

