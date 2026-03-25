/*
*/

{utp/ut-api.i}

{utp/ut-glob.i}

{method/dbotterr.i} /* RowErrors */

{utp/ut-api-action.i "pi-post-manual-ft4003" "POST" "/ManualFT4003*" }
{utp/ut-api-action.i "pi-get-nfe-xml" "GET" "/NFEXML*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

{cdp/cdcfgdis.i} /* Necessario para usar bodi317 */
{dibo/bodi317ef.i1} /* tt-notas-geradas */

{ftp/ft0910tt.i "-ft0910"} /* tt-param-ft0910 */
{ftp/ft0527tt.i "-ft0527"} /* tt-param-ft0527 tt-digita-ft0527 */

DEF TEMP-TABLE tt-nota-fiscal NO-UNDO LIKE nota-fiscal
    FIELD r-rowid AS ROWID
    .

DEF VAR raw-param        AS RAW NO-UNDO.

DEF TEMP-TABLE tt-raw-digita NO-UNDO
    FIELD raw-digita      AS RAW
    .

PROCEDURE pi-post-manual-ft4003:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .

    DEF VAR h-bodi317in             AS HANDLE NO-UNDO .
    DEF VAR h-bodi317pr             AS HANDLE NO-UNDO .
    DEF VAR h-bodi317sd             AS HANDLE NO-UNDO .
    DEF VAR h-bodi317im1bra         AS HANDLE NO-UNDO .
    DEF VAR h-bodi317va             AS HANDLE NO-UNDO .
    DEF VAR h-bodi317ef             AS HANDLE NO-UNDO .
    DEF VAR l-ok                    AS LOGICAL NO-UNDO .
    DEF VAR i-seq-wt-docto          AS INT     NO-UNDO .
    DEF VAR i-seq-wt-it-docto       AS INT     NO-UNDO .
    DEF VAR l-proc-ok-aux           AS LOGICAL NO-UNDO .
    DEF VAR c-ult-metodo-exec       AS CHAR    NO-UNDO .
    DEF VAR d-qtd-un                AS DECIMAL NO-UNDO .
  
    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .

    FIND FIRST emitente NO-LOCK
        WHERE emitente.cod-emitente = fnApiGetInt(oHeader, "cod_cli_for")
        NO-ERROR .
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Cliente/Fornecedor n∆o encontrado") .
        RETURN .
    END.

    IF fnApiGetInt(oHeader, "cod_rep") <> 0 THEN DO:
        FIND FIRST repres NO-LOCK
            WHERE repres.cod-rep = fnApiGetInt(oHeader, "cod_rep")
            NO-ERROR .
        IF NOT AVAIL repres THEN DO:
            oOut = fnApiErro("Representante n∆o encontrado") .
            RETURN .
        END.
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

    IF oItensArray:LENGTH = 0 THEN DO:
        oOut = fnApiErro("N∆o foram informados itens na nota fiscal") .
        RETURN .
    END.

    RUN dibo/bodi317in.p PERSISTENT SET h-bodi317in .
    RUN inicializaBOS IN h-bodi317in
        (OUTPUT h-bodi317pr,
         OUTPUT h-bodi317sd,
         OUTPUT h-bodi317im1bra,
         OUTPUT h-bodi317va)
        .

    ASSIGN l-ok = FALSE .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE ON STOP UNDO , LEAVE
        :
        RUN emptyRowErrors IN h-bodi317sd .
        RUN criaWtDocto IN h-bodi317sd
            (INPUT  c-seg-usuario,
             INPUT  fnApiGetChar(oHeader, "cod_estabel"),
             INPUT  fnApiGetChar(oHeader, "serie"),
             INPUT  "1", /* p-c-nr-nota Numero da Nota Manual */
             INPUT  emitente.nome-abrev,
             INPUT  "", /* p-c-nr-pedcli */
             INPUT  4, /* Nota Comp Merc */
             INPUT  4003, /* Programa */
             INPUT  TODAY, /* p-da-dt-emis-nota */
             INPUT  0, /*p-i-nr-embarque */
             INPUT  fnApiGetChar(oHeader, "nat_operacao"),
             INPUT  fnApiGetChar(oHeader, "cod_canal_venda"),
             OUTPUT i-seq-wt-docto,
             OUTPUT l-proc-ok-aux)
            .
        RUN devolveErrosbodi317sd IN h-bodi317sd
            (OUTPUT c-ult-metodo-exec ,
             OUTPUT TABLE RowErrors)
            .
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
            UNDO TRA1, LEAVE TRA1 .   
        END.

        FIND FIRST wt-docto WHERE wt-docto.seq-wt-docto = i-seq-wt-docto .
        ASSIGN 
            wt-docto.no-ab-reppri       = IF AVAIL repres THEN repres.nome-abrev ELSE ""
            wt-docto.nome-transp        = IF AVAIL transporte THEN transporte.nome-abrev ELSE ""
            wt-docto.mo-codigo          = fnApiGetInt(oHeader, "cod_moeda")
            wt-docto.cod-cond-pag       = fnApiGetInt(oHeader, "cod_cond_pag")
            wt-docto.nr-tabpre          = fnApiGetChar(oHeader, "nr_tabpre")
            wt-docto.vl-frete           = fnApiGetDecimal(oHeader, "vl_frete")
            wt-docto.marca-volume       = "IMPRESS DECOR BRASIL"
            wt-docto.nr-volumes         = STRING(fnApiGetInt(oHeader, "qt_volume"))
            wt-docto.nr-proc-exp        = fnApiGetChar(oHeader, "nr_proc_exp")
            wt-docto.observ-nota        = fnApiGetChar(oHeader, "inf_nota")
            .
        
        CREATE wt-nota-embal . ASSIGN
            wt-nota-embal.seq-wt-docto  = i-seq-wt-docto
            wt-nota-embal.sigla-emb     = "VOL"
            wt-nota-embal.qt-volumes    = fnApiGetInt(oHeader, "qt_volume")
            wt-nota-embal.desc-vol      = fnApiGetChar(oHeader, "cod_volume")
            .
        IF wt-nota-embal.desc-vol MATCHES "*PALLET*" THEN DO:
            ASSIGN wt-nota-embal.sigla-emb = "PAL" .
        END.
        ELSE IF wt-nota-embal.desc-vol MATCHES "*BOBINA*" THEN DO:
            ASSIGN wt-nota-embal.sigla-emb = "BOB" .
        END.

        DO iCont = 1 TO oItensArray:LENGTH
            :
            ASSIGN oItem = oItensArray:GetJsonObject(iCont) .

            RUN emptyRowErrors IN h-bodi317sd .
            RUN criaWtItDocto IN h-bodi317sd 
                (INPUT ? , /* Rowid ped-item */
                 INPUT "" , /* se existir ped-item */
                 INPUT iCont * 10 ,
                 INPUT fnApiGetChar(oItem, "it_codigo") ,
                 INPUT "" /* cod-refer */ ,
                 INPUT fnApiGetChar(oItem, "nat_operacao") ,
                 OUTPUT i-seq-wt-it-docto ,
                 OUTPUT l-ok)
                .
            RUN devolveErrosbodi317sd IN h-bodi317sd
                (OUTPUT c-ult-metodo-exec ,
                 OUTPUT TABLE RowErrors)
                .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
                UNDO TRA1, LEAVE TRA1 .   
            END.

            RUN emptyRowErrors IN h-bodi317sd .
            RUN gravaInfGeraisWtItDocto IN h-bodi317sd
                (INPUT i-seq-wt-docto ,
                 INPUT i-seq-wt-it-docto ,
                 INPUT fnApiGetDecimal(oItem, "quantidade") ,
                 INPUT fnApiGetDecimal(oItem, "vl_preori") ,
                 INPUT 0 ,
                 INPUT fnApiGetDecimal(oItem, "vl_desconto") / fnApiGetDecimal(oItem, "vl_preori") * 100 )
                .
            RUN devolveErrosbodi317sd IN h-bodi317sd
                (OUTPUT c-ult-metodo-exec ,
                 OUTPUT TABLE RowErrors)
                .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
                UNDO TRA1, LEAVE TRA1 .   
            END.

            RUN emptyRowErrors IN h-bodi317sd .
            RUN gravaQtUnMedida IN h-bodi317sd
                (INPUT i-seq-wt-docto,
                 INPUT i-seq-wt-it-docto ,
                 INPUT fnApiGetDecimal(oItem, "quantidade") ,
                 INPUT fnApiGetDecimal(oItem, "quantidade") ,
                 INPUT fnApiGetChar(oItem, "un") ,
                 INPUT fnApiGetChar(oItem, "un") )
                .
            RUN devolveErrosbodi317sd IN h-bodi317sd
                (OUTPUT c-ult-metodo-exec ,
                 OUTPUT TABLE RowErrors)
                .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
                UNDO TRA1, LEAVE TRA1 .   
            END.

            RUN emptyRowErrors IN h-bodi317pr .
            RUN localizaWtDocto IN h-bodi317pr
                (INPUT i-seq-wt-docto , 
                 OUTPUT l-ok) 
                .
            RUN localizaWtItDocto IN h-bodi317pr
                (INPUT i-seq-wt-docto ,
                 INPUT i-seq-wt-it-docto ,
                 OUTPUT l-ok)
                .
            RUN localizaWtItImposto IN h-bodi317pr
                (INPUT i-seq-wt-docto ,
                 INPUT i-seq-wt-it-docto ,
                 OUTPUT l-ok)
                .
            RUN atualizaDadosItemNota IN h-bodi317pr(OUTPUT l-ok) .
            RUN devolveErrosbodi317pr IN h-bodi317pr
                (OUTPUT c-ult-metodo-exec ,
                 OUTPUT TABLE RowErrors)
                .
            IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
                UNDO TRA1, LEAVE TRA1 .   
            END.

            /* Utiliza narrativa enviada pela API */
            FIND FIRST wt-it-docto
                WHERE wt-it-docto.seq-wt-docto = i-seq-wt-docto
                AND   wt-it-docto.seq-wt-it-docto = i-seq-wt-it-docto
                .
            ASSIGN
                wt-it-docto.narrativa = wt-it-docto.narrativa + fnApiGetChar(oItem, "inf_prod")
                .
        END.

        /* Calcula Nota */
        RUN emptyRowErrors IN h-bodi317pr .
        RUN calculaWtDocto IN h-bodi317pr(INPUT i-seq-wt-docto , OUTPUT l-ok) .
        RUN devolveErrosbodi317pr IN h-bodi317pr
            (OUTPUT c-ult-metodo-exec ,
             OUTPUT TABLE RowErrors)
            .
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
            UNDO TRA1, LEAVE TRA1 .   
        END.

        /* Utiliza pesos enviados pela API */
        FIND FIRST wt-docto WHERE wt-docto.seq-wt-docto = i-seq-wt-docto .
        ASSIGN
            wt-docto.peso-bru-tot       = fnApiGetDecimal(oHeader, "peso_bruto")
            wt-docto.peso-bru-tot-inf   = wt-docto.peso-bru-tot
            wt-docto.peso-liq-tot       = fnApiGetDecimal(oHeader, "peso_liquido")
            wt-docto.peso-liq-tot-inf   = wt-docto.peso-liq-tot
            .

        /* Efetiva Nota */
        IF NOT VALID-HANDLE(h-bodi317ef) THEN DO:
            RUN dibo/bodi317ef.p PERSISTENT SET h-bodi317ef .
        END.
        RUN limpaTtNotasGeradas IN h-bodi317ef(OUTPUT l-ok) .
        RUN emptyRowErrors IN h-bodi317ef .
        RUN setaHandlesBOS IN h-bodi317ef
            (INPUT h-bodi317pr ,
             INPUT h-bodi317sd ,
             INPUT h-bodi317im1bra ,
             INPUT h-bodi317va)
            .
        RUN efetivaNota IN h-bodi317ef(INPUT i-seq-wt-docto, INPUT YES, OUTPUT l-ok).
        RUN devolveErrosbodi317ef IN h-bodi317ef
            (OUTPUT c-ult-metodo-exec ,
             OUTPUT TABLE RowErrors)
            .
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR") THEN DO:
            UNDO TRA1, LEAVE TRA1 .   
        END.

        RUN buscaTTNotasGeradas IN h-bodi317ef(OUTPUT l-ok, OUTPUT TABLE tt-notas-geradas) .
        /**/

        ASSIGN l-ok = YES .
    END.

    IF VALID-HANDLE(h-bodi317in) THEN DO:
        RUN finalizaBOS IN h-bodi317in .
        DELETE PROCEDURE h-bodi317in NO-ERROR .
        ASSIGN h-bodi317in = ? .
    END.
    
    IF VALID-HANDLE(h-bodi317ef) THEN DO:
        DELETE PROCEDURE h-bodi317ef NO-ERROR .
        ASSIGN h-bodi317ef = ? .
    END.

    IF l-ok THEN DO:
        FIND FIRST tt-notas-geradas NO-LOCK .

        FIND FIRST nota-fiscal NO-LOCK WHERE
            ROWID(nota-fiscal) = tt-notas-geradas.rw-nota-fiscal
            .

        /* Envia nota via TSS */
        IF nota-fiscal.idi-sit-nf-eletro = 1 /*Nao Gerada*/ THEN DO:
            EMPTY TEMP-TABLE tt-param-ft0910 .
            EMPTY TEMP-TABLE tt-raw-digita .
            CREATE tt-param-ft0910 . ASSIGN 
                tt-param-ft0910.destino             = 3
                tt-param-ft0910.arquivo             = session:temp-direct + 'ft0910_invoice_api.txt'
                tt-param-ft0910.usuario             = c-seg-usuario
                tt-param-ft0910.data-exec           = today
                tt-param-ft0910.hora-exec           = time
                tt-param-ft0910.cod-estabel-ini     = nota-fiscal.cod-estabel
                tt-param-ft0910.cod-estabel-fim     = nota-fiscal.cod-estabel
                tt-param-ft0910.serie-ini           = nota-fiscal.serie
                tt-param-ft0910.serie-fim           = nota-fiscal.serie
                tt-param-ft0910.nr-nota-fis-ini     = nota-fiscal.nr-nota-fis
                tt-param-ft0910.nr-nota-fis-fim     = nota-fiscal.nr-nota-fis
                tt-param-ft0910.nome-ab-cli-ini     = nota-fiscal.nome-ab-cli
                tt-param-ft0910.nome-ab-cli-fim     = nota-fiscal.nome-ab-cli
                tt-param-ft0910.dt-emis-nota-ini    = nota-fiscal.dt-emis-nota
                tt-param-ft0910.dt-emis-nota-fim    = nota-fiscal.dt-emis-nota
                tt-param-ft0910.gera-nfe-n-gerada   = YES
                tt-param-ft0910.gera-nfe-gerada     = NO
                tt-param-ft0910.gera-nfe-rejeitada  = NO
                tt-param-ft0910.exporta-est-txt     = NO
                tt-param-ft0910.gera-nfe-cancel     = NO
                tt-param-ft0910.gera-nfe-inut       = NO
                tt-param-ft0910.c-motivo            = ''
                .
            RAW-TRANSFER tt-param-ft0910 TO raw-param .
            RUN ftp/ft0910rp.p(INPUT raw-param , INPUT TABLE tt-raw-digita) .
        END.
        /**/

        oOut = fnApiOK() .
        oOut:ADD("cod_estabel"  , nota-fiscal.cod-estabel).
        oOut:ADD("serie"        , nota-fiscal.serie).
        oOut:ADD("nr_nota_fis"  , nota-fiscal.nr-nota-fis).
    END.
    ELSE DO:
        FIND FIRST RowErrors WHERE RowErrors.ErrorSubType = "ERROR" .
        oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + RowErrors.ErrorDescription) .
    END.
END PROCEDURE .






/**/





PROCEDURE pi-get-nfe-xml:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR h-bodi520       AS HANDLE NO-UNDO .
    DEF VAR cDirHistorXML   AS CHAR NO-UNDO .
    DEF VAR cFileName       AS CHAR NO-UNDO .
    DEF VAR cPathName       AS CHAR NO-UNDO .
    DEF VAR cTypeDesc       AS CHAR NO-UNDO .

    DEF VAR mArqOut         AS MEMPTR NO-UNDO.
    DEF VAR cXMLFile        AS CHAR NO-UNDO .
    DEF VAR lcXMLBase64     AS LONGCHAR NO-UNDO .
    DEF VAR cPDFFile        AS CHAR NO-UNDO .
    DEF VAR lcPDFBase64     AS LONGCHAR NO-UNDO .

    DEF VAR cMsg            AS CHAR NO-UNDO .

    FIND FIRST nota-fiscal NO-LOCK
        WHERE nota-fiscal.cod-estabel = fnApiReadParam(oIn, "cod_estabel")
        AND   nota-fiscal.serie = fnApiReadParam(oIn, "serie")
        AND   nota-fiscal.nr-nota-fis = fnApiReadParam(oIn, "nr_nota_fis")
        NO-ERROR .
    IF NOT AVAIL nota-fiscal THEN DO:
        oOut = fnApiErro("Nota fiscal n∆o encontrada") .
        RETURN .
    END.

    /* Retornar Status do TSS */
    IF nota-fiscal.idi-sit-nf-eletro <> 3 /* Uso Autorizado */ AND 
       nota-fiscal.idi-sit-nf-eletro <> 5 /* Documento Rejeitado */ AND
       nota-fiscal.idi-sit-nf-eletro <> 6 /* Documento Cancelado */ AND
       nota-fiscal.idi-sit-nf-eletro <> 7 /* Documento Inutilizado */
    THEN DO:
        EMPTY TEMP-TABLE tt-nota-fiscal . 
        CREATE tt-nota-fiscal . 
        BUFFER-COPY nota-fiscal TO tt-nota-fiscal .
        ASSIGN tt-nota-fiscal.r-rowid = ROWID(nota-fiscal) .
    
        RUN ftp/ft0915a.p(
            INPUT TABLE tt-nota-fiscal,
            INPUT NO,
            INPUT ?,
            OUTPUT TABLE RowErrors)
            .
    
        FIND CURRENT nota-fiscal NO-LOCK .
    END.

    /* Retornar pasta Historico XML */
    IF NOT VALID-HANDLE(h-bodi520) THEN DO:
        RUN dibo/bodi520.p PERSISTENT SET h-bodi520.
        RUN openQueryStatic IN h-bodi520 (INPUT "Main":U).
    END.

    RUN goToKey IN h-bodi520 (INPUT nota-fiscal.cod-estabel).
    RUN getCharField IN h-bodi520(INPUT "cod-dir-histor-xml", OUTPUT cDirHistorXML).

    ASSIGN cDirHistorXML = REPLACE(cDirHistorXML, "N:", "//server11/data") .

    ASSIGN cDirHistorXML = REPLACE(cDirHistorXML,"~\","/") .
    IF NOT SUBSTR(cDirHistorXML, LENGTH(cDirHistorXML), 1) = "/" THEN DO:
        ASSIGN cDirHistorXML = cDirHistorXML + "/".
    END.
    ASSIGN cDirHistorXML = TRIM(cDirHistorXML)
        + TRIM(nota-fiscal.cod-estabel)
        + TRIM(STRING(INTEGER(nota-fiscal.serie), "999"))
        + TRIM(STRING(INTEGER(nota-fiscal.nr-nota-fis),">>9999999"))
        .

    IF VALID-HANDLE(h-bodi520) THEN DO:
        DELETE PROCEDURE h-bodi520.
        ASSIGN h-bodi520 = ?.
    END.

    /* Ler Arquivo XML */
    ASSIGN FILE-INFO:FILE-NAME = cDirHistorXML .
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO: /* Dir existe */
        INPUT FROM OS-DIR(cDirHistorXML) CONVERT TARGET "iso8859-1":U.
        REPEAT:
            IMPORT cFileName cPathName cTypeDesc.
            IF cTypeDesc = "F" THEN DO:
                ASSIGN FILE-INFO:FILE-NAME = cPathName.
                IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
                    /*COPY-LOB FROM FILE cPathName TO lcXMLBase64 .*/
                    COPY-LOB FROM FILE cPathName TO mArqOut .
                    LEAVE .
                END.
            END.
        END.
        INPUT CLOSE .
    END.

    /* XML Convert memptr content to Base64 */
    ASSIGN lcXMLBase64 = BASE64-ENCODE(mArqOut) .

    /* Impressao DANFE PDF */
    IF nota-fiscal.idi-sit-nf-eletro = 3 /* Uso Autorizado */
    THEN DO:
        EMPTY TEMP-TABLE tt-param-ft0527 .
        EMPTY TEMP-TABLE tt-digita-ft0527 .
        EMPTY TEMP-TABLE tt-raw-digita .

        CREATE tt-param-ft0527 . ASSIGN
            tt-param-ft0527.destino                 = 2 /* Arquivo */  
            tt-param-ft0527.arquivo                 = SESSION:TEMP-DIR + nota-fiscal.cod-chave-aces-nf-eletro + ".pdf"          
            tt-param-ft0527.usuario                 = c-seg-usuario         
            tt-param-ft0527.data-exec               = TODAY
            tt-param-ft0527.hora-exec               = TIME
            tt-param-ft0527.parametro               = NO
            tt-param-ft0527.formato                 = 1
            tt-param-ft0527.cod-layout              = "DANFE-Mod.1"
            tt-param-ft0527.des-layout              = ""
            tt-param-ft0527.log-impr-dados          = NO
            tt-param-ft0527.v_num_tip_aces_usuar    = v_num_tip_aces_usuar
            tt-param-ft0527.ep-codigo               = i-ep-codigo-usuario
            tt-param-ft0527.c-cod-estabel           = nota-fiscal.cod-estabel
            tt-param-ft0527.c-serie                 = nota-fiscal.serie
            tt-param-ft0527.c-nr-nota-fis-ini       = nota-fiscal.nr-nota-fis
            tt-param-ft0527.c-nr-nota-fis-fim       = nota-fiscal.nr-nota-fis
            tt-param-ft0527.de-cdd-embarque-ini     = 0
            tt-param-ft0527.de-cdd-embarque-fim     = 999999999
            tt-param-ft0527.da-dt-saida             = nota-fiscal.dt-saida
            tt-param-ft0527.c-hr-saida              = ""
            tt-param-ft0527.rs-imprime              = nota-fiscal.ind-sit-nota
            tt-param-ft0527.nr-copias               = 1
            tt-param-ft0527.l-gera-danfe-xml        = NO
            .

        CREATE tt-digita-ft0527. ASSIGN
            tt-digita-ft0527.ordem   = 1
            tt-digita-ft0527.exemplo = c-seg-usuario
            .
        
        FOR EACH tt-digita-ft0527 NO-LOCK
            :
            CREATE tt-raw-digita .
            RAW-TRANSFER tt-digita-ft0527 TO tt-raw-digita.raw-digita .
        END.

        RAW-TRANSFER tt-param-ft0527 TO raw-param .
        RUN ftp/ft0527rp.p(INPUT raw-param , INPUT TABLE tt-raw-digita) .

        COPY-LOB FROM FILE tt-param-ft0527.arquivo TO mArqOut .
        ASSIGN lcPDFBase64 = BASE64-ENCODE(mArqOut) .
    END.

    /* Ultima mensagem de retorno do Sefaz */
    IF nota-fiscal.idi-sit-nf-eletro <> 3 /* Uso Autorizado */ THEN DO:
        ASSIGN cMsg = "" .
        FOR EACH ret-nf-eletro NO-LOCK
            WHERE ret-nf-eletro.cod-estabel = nota-fiscal.cod-estabel
            AND   ret-nf-eletro.cod-serie = nota-fiscal.serie
            AND   ret-nf-eletro.nr-nota-fis = nota-fiscal.nr-nota-fis
            BY ret-nf-eletro.dat-ret DESC
            BY ret-nf-eletro.hra-ret DESC
            :
            ASSIGN cMsg = STRING(ret-nf-eletro.cod-msg) + " - " + ret-nf-eletro.cod-livre-2 .
            LEAVE .
        END.
        oOut = fnApiErro(cMsg) .
    END.
    ELSE DO:
        oOut = fnApiOK() .
    END.
    
    oOut:ADD("nfe_status"       , {diinc/i01di135.i 4 nota-fiscal.idi-sit-nf-eletro} ) .
    oOut:ADD("cod_chave_nfe"    , nota-fiscal.cod-chave-aces-nf-eletro) .
    oOut:ADD("XML"              , lcXMLBase64) .
    oOut:ADD("DANFE_PDF"        , lcPDFBase64) .
END PROCEDURE .

