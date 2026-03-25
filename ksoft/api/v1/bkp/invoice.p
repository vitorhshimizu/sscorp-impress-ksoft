/*
*/

{utp/ut-api.i}

{utp/ut-glob.i}

{method/dbotterr.i} /* RowErrors */

{utp/ut-api-action.i "pi-post-manual-ft4003" "POST" "/ManualFT4003*" }
{utp/ut-api-action.i "pi-get-nfe-xml" "GET" "/NFEXML*" }
{utp/ut-api-action.i "pi-cancel" "POST" "/cancel*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

{cdp/cdcfgdis.i} /* Necessario para usar bodi317 */
{dibo/bodi317ef.i1} /* tt-notas-geradas */

{ftp/ft0910tt.i "-ft0910"} /* tt-param-ft0910 */
{ftp/ft0527tt.i "-ft0527"} /* tt-param-ft0527 tt-digita-ft0527 */
{ftp/ft2200tt.i "-ft2200"} /* tt-param-ft2200 */

DEF TEMP-TABLE tt-nota-fiscal NO-UNDO LIKE nota-fiscal
    FIELD r-rowid AS ROWID
    .

DEF VAR raw-param        AS RAW NO-UNDO.

DEF TEMP-TABLE tt-raw-digita NO-UNDO
    FIELD raw-digita      AS RAW
    .

DEF BUFFER portador FOR mgcad.portador .

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

PROCEDURE pi-post-manual-ft4003:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR iCont                   AS INT NO-UNDO .
    DEF VAR oHeader                 AS JsonObject NO-UNDO .
    DEF VAR oItensArray             AS JsonArray NO-UNDO .
    DEF VAR oItem                   AS JsonObject NO-UNDO .
    
    DEF VAR h-cspdapi002            AS HANDLE NO-UNDO .
    DEF VAR de-aliquota-pis         AS DECIMAL NO-UNDO .
    DEF VAR de-aliquota-cofins      AS DECIMAL NO-UNDO .
    DEF VAR de-aliquota-icms        AS DECIMAL NO-UNDO .
    DEF VAR de-aliq-dif-icms        AS DECIMAL NO-UNDO .
    DEF VAR de-preco-final          AS DECIMAL NO-UNDO .
    DEF VAR de-preco-fatur          AS DECIMAL NO-UNDO .
    DEF VAR de-tot-duplic           AS DECIMAL NO-UNDO .

    DEF VAR l-ok-transaction        AS LOGICAL NO-UNDO .
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

    DEF BUFFER bf-emitente-transp   FOR emitente .
    DEF BUFFER bf-emitente-tri      FOR emitente .
    DEF BUFFER ext-it-nota-fisc     FOR mgmov.ext-it-nota-fisc .
  
    ASSIGN oIn = fnApiReadBody(oIn) .
    ASSIGN oHeader = fnApiGetObject(oIn, "header") .
    ASSIGN oItensArray = fnApiGetArray(oIn, "itens") .

    oIn:WriteFile("C:\totvs\ksoft_log\POST_invoice\" + fnNowToString() + ".json", YES, "UTF-8") .

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
    IF NOT AVAIL emitente THEN DO:
        oOut = fnApiErro("Natureza de Operaá∆o n∆o encontrada") .
        RETURN .
    END.

    IF natur-oper.log-oper-triang = YES THEN DO:
        FIND FIRST bf-emitente-tri NO-LOCK
            WHERE bf-emitente-tri.cod-emitente = fnApiGetInt(oHeader, "cod_cli_for_tri")
            NO-ERROR .
        IF NOT AVAIL bf-emitente-tri THEN DO:
            oOut = fnApiErro("Cliente/Fornecedor da Operaá∆o Triangular n∆o encontrado") .
            RETURN .
        END.
    END.

    FIND FIRST portador NO-LOCK
        WHERE portador.ep-codigo = i-ep-codigo-usuario
        AND   portador.cod-portador = emitente.portador
        AND   portador.modalidade = emitente.modalidade
        NO-ERROR .
    IF NOT AVAIL portador THEN DO:
        oOut = fnApiErro("Portador do cliente n∆o encontrado, verifique o cadastro do cliente") .
        RETURN .
    END.

    IF portador.mo-codigo <> fnApiGetDecimal(oHeader, "currencyCode") THEN DO:
        oOut = fnApiErro("Moeda do Portador do cliente diferente da moeda para faturas") .
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

    IF fnApiGetInt(oHeader, "cod_transp") > 1 THEN DO:
        FIND FIRST bf-emitente-transp NO-LOCK
            WHERE bf-emitente-transp.cod-emitente = fnApiGetInt(oHeader, "cod_transp")
            NO-ERROR .
        IF NOT AVAIL bf-emitente-transp OR bf-emitente-transp.cgc = "" THEN DO:
            oOut = fnApiErro("Transportador Emitente n∆o encontrado") .
            RETURN .
        END.
        FIND FIRST transporte NO-LOCK
            WHERE transporte.cgc = bf-emitente-transp.cgc
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

    RUN cstp/cspdapi002.p PERSISTENT SET h-cspdapi002 .

    ASSIGN l-ok-transaction = FALSE .
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
            wt-docto.no-ab-reppri           = IF AVAIL repres THEN repres.nome-abrev ELSE ""
            wt-docto.nome-transp            = IF AVAIL transporte THEN transporte.nome-abrev ELSE ""
            wt-docto.mo-codigo              = fnApiGetInt(oHeader, "cod_moeda")
            wt-docto.cod-cond-pag           = fnApiGetInt(oHeader, "cod_cond_pag")
            wt-docto.nr-tabpre              = fnApiGetChar(oHeader, "nr_tabpre")
            wt-docto.vl-frete               = fnApiGetDecimal(oHeader, "vl_frete")
            wt-docto.vl-frete-inf           = wt-docto.vl-frete
            wt-docto.vl-seguro              = fnApiGetDecimal(oHeader, "vl_seguro")
            wt-docto.vl-seguro-inf          = wt-docto.vl-seguro
            wt-docto.vl-embalagem           = fnApiGetDecimal(oHeader, "vl_despesas")
            wt-docto.vl-embalagem-inf       = wt-docto.vl-embalagem
            wt-docto.marca-volume           = "IMPRESS DECOR BRASIL"
            wt-docto.nr-volumes             = STRING(fnApiGetInt(oHeader, "qt_volume"))
            wt-docto.nr-proc-exp            = fnApiGetChar(oHeader, "nr_proc_exp")
            wt-docto.observ-nota            = fnApiGetChar(oHeader, "inf_nota")
            wt-docto.cod-rota               = ""
            wt-docto.nome-abrev-tri         = IF AVAIL bf-emitente-tri THEN bf-emitente-tri.nome-abrev ELSE ""
            .
        OVERLAY(wt-docto.char-1,21,5)       = STRING(wt-docto.mo-codigo) . // Moeda Faturamento
        
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

        FOR FIRST loc-entr NO-LOCK
            WHERE loc-entr.nome-abrev = emitente.nome-abrev
            AND   loc-entr.cod-entrega = "Padr∆o"
            :
            ASSIGN wt-docto.cod-rota = loc-entr.cod-rota .
        END.

        DO iCont = 1 TO oItensArray:LENGTH
            :
            ASSIGN oItem = oItensArray:GetJsonObject(iCont) .

            FIND FIRST ITEM NO-LOCK
                WHERE ITEM.it-codigo = fnApiGetChar(oItem, "it_codigo")
                NO-ERROR .
            IF NOT AVAIL ITEM THEN DO:
                RUN insertErrorManual(17242, "EMS", "ERROR", "", "Item n∆o foi encontrado", fnApiGetChar(oItem, "it_codigo") ) .
                UNDO TRA1, LEAVE TRA1 . 
            END.

            RUN emptyRowErrors IN h-bodi317sd .
            RUN criaWtItDocto IN h-bodi317sd 
                (INPUT ? , /* Rowid ped-item */
                 INPUT "" , /* se existir ped-item */
                 INPUT iCont * 10 ,
                 INPUT ITEM.it-codigo ,
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

            //ASSIGN de-preco-final = fnApiGetDecimal(oItem, "vl_preori") - fnApiGetDecimal(oItem, "vl_desconto") .
            ASSIGN de-preco-final = fnApiGetDecimal(oItem, "final_price") .

            RUN pi-aliquota-pis-cofins-icms IN h-cspdapi002 
                (INPUT fnApiGetChar(oItem, "nat_operacao") ,
                 INPUT "101" ,
                 INPUT emitente.estado ,
                 INPUT emitente.pais,
                 INPUT ITEM.it-codigo ,
                 INPUT emitente.nome-abrev ,
                 OUTPUT de-aliquota-pis,
                 OUTPUT de-aliquota-cofins,
                 OUTPUT de-aliquota-icms,
                 OUTPUT de-aliq-dif-icms )
                .
            
            RUN pi-preco-final-fatur-ped-item IN h-cspdapi002 
                (INPUT de-preco-final , 
                 INPUT 0 , /* Preco Moeda */
                 INPUT 1 , /* Ptax */
                 INPUT emitente.nome-abrev ,
                 INPUT ITEM.it-codigo ,
                 INPUT NO /* Preco Informado */ ,
                 INPUT de-preco-final ,
                 INPUT de-aliquota-pis ,
                 INPUT de-aliquota-cofins ,
                 INPUT de-aliquota-icms ,
                 INPUT de-aliq-dif-icms , 
                 INPUT 1 /* Aberto */ ,
                 INPUT 1 /* Qt Pedida */,
                 INPUT 0 /* Qt Atendida */ ,
                 INPUT de-preco-final ,
                 OUTPUT de-preco-final,
                 OUTPUT de-preco-fatur)
                .

            /* Arredondar 2 casas decimais */
            ASSIGN de-preco-final = ROUND(de-preco-final, 2) .
            ASSIGN de-preco-fatur = ROUND(de-preco-fatur, 2) .

            RUN emptyRowErrors IN h-bodi317sd .
            RUN gravaInfGeraisWtItDocto IN h-bodi317sd
                (INPUT i-seq-wt-docto ,
                 INPUT i-seq-wt-it-docto ,
                 INPUT fnApiGetDecimal(oItem, "quantidade") ,
                 INPUT de-preco-fatur ,
                 INPUT 0 /* p-de-pct-desc-tb-preco */ ,
                 INPUT 0 /* p-de-per-des-item */ )
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
                 INPUT ITEM.un ,
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
                wt-it-docto.narrativa = fnApiGetChar(oItem, "inf_prod")
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
        FIND FIRST wt-docto EXCLUSIVE-LOCK WHERE wt-docto.seq-wt-docto = i-seq-wt-docto .
        ASSIGN
            wt-docto.peso-bru-tot       = fnApiGetDecimal(oHeader, "peso_bruto")
            wt-docto.peso-bru-tot-inf   = wt-docto.peso-bru-tot
            wt-docto.peso-liq-tot       = fnApiGetDecimal(oHeader, "peso_liquido")
            wt-docto.peso-liq-tot-inf   = wt-docto.peso-liq-tot
            .
        FIND FIRST wt-it-docto EXCLUSIVE-LOCK WHERE wt-it-docto.seq-wt-docto = i-seq-wt-docto .
        ASSIGN
            wt-it-docto.peso-bru-it-inf = wt-docto.peso-bru-tot-inf
            wt-it-docto.peso-liq-it-inf = wt-docto.peso-liq-tot-inf
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

        /* Atualiza financeiro em moeda estrangeira */
        IF fnApiGetDecimal(oHeader, "currencyCode") <> 0 THEN DO:
            FIND FIRST tt-notas-geradas NO-LOCK .

            FIND FIRST nota-fiscal WHERE
                ROWID(nota-fiscal) = tt-notas-geradas.rw-nota-fiscal
                .

            ASSIGN
                nota-fiscal.cod-portador = emitente.portador
                nota-fiscal.modalidade = emitente.modalidade
                .

            ASSIGN de-tot-duplic = 0 .
            FOR EACH fat-duplic NO-LOCK
                WHERE fat-duplic.cod-estabel = nota-fiscal.cod-estabel 
                AND   fat-duplic.serie = nota-fiscal.serie
                AND   fat-duplic.nr-fatura = nota-fiscal.nr-fatura
                :
                ASSIGN de-tot-duplic = de-tot-duplic + fat-duplic.vl-parcela .
            END.

            FOR EACH fat-duplic
                WHERE fat-duplic.cod-estabel = nota-fiscal.cod-estabel 
                AND   fat-duplic.serie = nota-fiscal.serie
                AND   fat-duplic.nr-fatura = nota-fiscal.nr-fatura
                :
                ASSIGN
                    fat-duplic.mo-negoc         = fnApiGetDecimal(oHeader, "currencyCode")
                    fat-duplic.vl-parcela-me    = fnApiGetDecimal(oHeader, "currencyValue") * (fat-duplic.vl-parcela / de-tot-duplic)
                    fat-duplic.vl-comis-me      = fat-duplic.vl-parcela-me
                    .
            END.

            /* Necessario devido ao recalculo na ftapi001 */
            ASSIGN de-tot-duplic = 0 .
            FOR EACH it-nota-fisc NO-LOCK OF nota-fiscal
                :
                ASSIGN de-tot-duplic = de-tot-duplic + it-nota-fisc.vl-merc-liq .
            END.

            FOR EACH it-nota-fisc OF nota-fiscal
                :
                ASSIGN it-nota-fisc.vl-merc-liq-me = fnApiGetDecimal(oHeader, "currencyValue") * (it-nota-fisc.vl-merc-liq / de-tot-duplic) .
            END.
        END.

        /* Armazena a Taxa/Surcharge */
        FOR EACH tt-notas-geradas NO-LOCK
            ,
            EACH nota-fiscal NO-LOCK WHERE
            ROWID(nota-fiscal) = tt-notas-geradas.rw-nota-fiscal
            :
            ASSIGN iCont = 0 .
            FOR EACH it-nota-fisc NO-LOCK OF nota-fiscal
                :
                ASSIGN iCont = iCont + 1 .
                ASSIGN oItem = oItensArray:GetJsonObject(iCont) .
                CREATE ext-it-nota-fisc . ASSIGN
                    ext-it-nota-fisc.cod-estabel    = it-nota-fisc.cod-estabel
                    ext-it-nota-fisc.serie          = it-nota-fisc.serie
                    ext-it-nota-fisc.nr-nota-fis    = it-nota-fisc.nr-nota-fis
                    ext-it-nota-fisc.nr-seq-fat     = it-nota-fisc.nr-seq-fat
                    ext-it-nota-fisc.it-codigo      = it-nota-fisc.it-codigo
                    ext-it-nota-fisc.cod-param      = "ksoft"
                    ext-it-nota-fisc.val-livre-1    = fnApiGetDecimal(oItem, "surcharge")
                    .
            END.
        END.

        ASSIGN l-ok-transaction = YES .
    END.

    IF VALID-HANDLE(h-cspdapi002) THEN DO:
        DELETE PROCEDURE h-cspdapi002 NO-ERROR .
        ASSIGN h-cspdapi002 = ? .
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

    IF l-ok-transaction THEN DO:
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
PROCEDURE pi-find-nota-fiscal:
    DEF INPUT PARAM p-cod-estabel   AS CHAR NO-UNDO .
    DEF INPUT PARAM p-serie         AS CHAR NO-UNDO .
    DEF INPUT PARAM p-nr-nota-fis   AS CHAR NO-UNDO .
    DEF OUTPUT PARAM oOut           AS JsonObject NO-UNDO .

    FIND FIRST nota-fiscal NO-LOCK
        WHERE nota-fiscal.cod-estabel = p-cod-estabel
        AND   nota-fiscal.serie = p-serie
        AND   nota-fiscal.nr-nota-fis = p-nr-nota-fis
        NO-ERROR .
    IF NOT AVAIL nota-fiscal THEN DO:
        oOut = fnApiErro("Nota fiscal n∆o encontrada") .
        RETURN "NOK" .
    END.

    RETURN "OK" .
END PROCEDURE .

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

    RUN pi-find-nota-fiscal
        (INPUT fnApiReadParam(oIn, "cod_estabel"),
         INPUT fnApiReadParam(oIn, "serie"),
         INPUT fnApiReadParam(oIn, "nr_nota_fis") , 
         OUTPUT oOut )
        .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

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

    /* APENAS DEVIDO AO ERRO NO SEFAZ - AGUARDANDO ATUALIZACAO DA TOTVS */
    /*
    IF nota-fiscal.idi-sit-nf-eletro = 5 /* Rejeitada */ THEN DO:
        DO TRANSACTION ON ERROR UNDO , LEAVE
            :
            FIND CURRENT nota-fiscal EXCLUSIVE-LOCK .
            ASSIGN nota-fiscal.idi-sit-nf-eletro = 3 /* Uso Autorizado */ .
        END.
    END.
    */

    /* Retornar pasta de arquivos XML */
    IF NOT VALID-HANDLE(h-bodi520) THEN DO:
        RUN dibo/bodi520.p PERSISTENT SET h-bodi520.
        RUN openQueryStatic IN h-bodi520 (INPUT "Main":U).
    END.

    /*
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
    
    MESSAGE "LOG XML NFE: " cDirHistorXML VIEW-AS ALERT-BOX .
    
    /* Ler Arquivo XML da Pasta */
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
    */

    RUN goToKey IN h-bodi520 (INPUT nota-fiscal.cod-estabel).
    RUN getCharField IN h-bodi520(INPUT "cod-caminho-xml ", OUTPUT cDirHistorXML).

    ASSIGN cDirHistorXML = REPLACE(cDirHistorXML, "N:", "//server11/data") .

    ASSIGN cDirHistorXML = REPLACE(cDirHistorXML,"~\","/") .
    IF NOT SUBSTR(cDirHistorXML, LENGTH(cDirHistorXML), 1) = "/" THEN DO:
        ASSIGN cDirHistorXML = cDirHistorXML + "/".
    END.
    ASSIGN cDirHistorXML = TRIM(cDirHistorXML)
        + TRIM(nota-fiscal.cod-estabel)
        + TRIM(STRING(INTEGER(nota-fiscal.serie), "999"))
        + TRIM(STRING(INTEGER(nota-fiscal.nr-nota-fis),">>9999999"))
        + ".xml"
        .
    
    MESSAGE "LOG XML NFE: " cDirHistorXML VIEW-AS ALERT-BOX .
    
    ASSIGN FILE-INFO:FILE-NAME = cDirHistorXML .
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
        COPY-LOB FROM FILE cDirHistorXML TO mArqOut .
    END.

    IF VALID-HANDLE(h-bodi520) THEN DO:
        DELETE PROCEDURE h-bodi520.
        ASSIGN h-bodi520 = ?.
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
            //tt-digita-ft0527.exemplo = c-seg-usuario
            tt-digita-ft0527.exemplo = ""
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
        FOR LAST ret-nf-eletro NO-LOCK
            WHERE ret-nf-eletro.cod-estabel = nota-fiscal.cod-estabel
            AND   ret-nf-eletro.cod-serie = nota-fiscal.serie
            AND   ret-nf-eletro.nr-nota-fis = nota-fiscal.nr-nota-fis
            AND   ret-nf-eletro.cod-livre-2 <> ""
            BY ret-nf-eletro.dat-ret
            BY ret-nf-eletro.hra-ret
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

PROCEDURE pi-cancel
    :
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR l-ok            AS LOGICAL NO-UNDO .
    DEF VAR h-bodi135cancel AS HANDLE NO-UNDO .

    ASSIGN oIn = fnApiReadBody(oIn) .

    RUN pi-find-nota-fiscal
        (INPUT fnApiGetChar(oIn, "cod_estabel"),
         INPUT fnApiGetChar(oIn, "serie"),
         INPUT fnApiGetChar(oIn, "nr_nota_fis") , 
         OUTPUT oOut )
        .
    IF RETURN-VALUE <> "OK" THEN RETURN RETURN-VALUE .

    ASSIGN l-ok = FALSE .
    TRA1:
    DO TRANSACTION ON ERROR UNDO , LEAVE
        :
        RUN dibo/bodi135cancel.p PERSISTENT SET h-bodi135cancel .
        RUN emptyRowErrors IN h-bodi135cancel .
        RUN cancelaNotaFiscal IN h-bodi135cancel
            (INPUT nota-fiscal.cod-estabel,
             INPUT nota-fiscal.serie,
             INPUT nota-fiscal.nr-nota-fis,
             INPUT TODAY, /* p-dt-cancela */
             INPUT fnApiGetChar(oIn, "motivo_cancelamento"),
             INPUT NO, /* l-valida-dt-saida */
             INPUT NO, /* p-reabre-resumo */
             INPUT NO, /* p-cancela-titulos */
             INPUT SESSION:TEMP-DIR + "ft2100.txt", /* p-arq-estoque */
             INPUT c-seg-usuario )
            .
        RUN getRowErrors IN h-bodi135cancel(OUTPUT TABLE RowErrors) .
        IF CAN-FIND(FIRST RowErrors 
                    WHERE RowErrors.ErrorSubType = "ERROR" 
                    AND   RowErrors.ErrorNumber <> 17006 ) 
        THEN DO:
            UNDO TRA1, LEAVE TRA1 .   
        END.
        /**/
        EMPTY TEMP-TABLE tt-param-ft2200 .
        EMPTY TEMP-TABLE tt-digita-ft2200 .
        EMPTY TEMP-TABLE tt-raw-digita .
    
        CREATE tt-param-ft2200 . ASSIGN
            tt-param-ft2200.destino                 = 2 /* Arquivo */  
            tt-param-ft2200.arquivo                 = SESSION:TEMP-DIR + "ft2200.txt"          
            tt-param-ft2200.usuario                 = c-seg-usuario
            tt-param-ft2200.data-exec               = TODAY
            tt-param-ft2200.hora-exec               = TIME
            tt-param-ft2200.cod-estabel             = nota-fiscal.cod-estabel
            tt-param-ft2200.serie                   = nota-fiscal.serie
            tt-param-ft2200.nr-nota-fis             = nota-fiscal.nr-nota-fis
            tt-param-ft2200.dt-cancela              = TODAY
            tt-param-ft2200.desc-cancela            = fnApiGetChar(oIn, "motivo_cancelamento")
            tt-param-ft2200.arquivo-estoq           = SESSION:TEMP-DIR + "ft2100.txt"
            tt-param-ft2200.reabre-resumo           = NO
            tt-param-ft2200.cancela-titulos         = NO
            tt-param-ft2200.imprime-ajuda           = YES
            tt-param-ft2200.l-valida-dt-saida       = NO
            tt-param-ft2200.elimina-nota-nfse       = NO
            .
    
        CREATE tt-digita-ft2200. ASSIGN
            tt-digita-ft2200.ordem   = 1
            tt-digita-ft2200.exemplo = c-seg-usuario
            .
        
        FOR EACH tt-digita-ft2200 NO-LOCK
            :
            CREATE tt-raw-digita .
            RAW-TRANSFER tt-digita-ft2200 TO tt-raw-digita.raw-digita .
        END.
    
        RAW-TRANSFER tt-param-ft2200 TO raw-param .
        RUN ftp/ft2200rp.p(INPUT raw-param , INPUT TABLE tt-raw-digita) .

        ASSIGN l-ok = TRUE .
    END.

    IF VALID-HANDLE(h-bodi135cancel) THEN DO:
        DELETE PROCEDURE h-bodi135cancel NO-ERROR .
        ASSIGN h-bodi135cancel = ? .
    END.

    IF l-ok THEN DO:
        /* Envia nota via TSS */
        IF nota-fiscal.dt-cancela <> ? THEN DO:
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
                tt-param-ft0910.gera-nfe-n-gerada   = NO
                tt-param-ft0910.gera-nfe-gerada     = NO
                tt-param-ft0910.gera-nfe-rejeitada  = NO
                tt-param-ft0910.exporta-est-txt     = NO
                tt-param-ft0910.gera-nfe-cancel     = YES
                tt-param-ft0910.gera-nfe-inut       = YES
                tt-param-ft0910.c-motivo            = fnApiGetChar(oIn, "motivo_cancelamento")
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
        FIND FIRST RowErrors 
            WHERE RowErrors.ErrorSubType = "ERROR" 
            AND   RowErrors.ErrorNumber <> 17006
            .
        oOut = fnApiErro(STRING(RowErrors.ErrorNumber) + " - " + 
                         RowErrors.ErrorDescription + " " + RowErrors.ErrorHelp) 
            .
    END.
END PROCEDURE .

PROCEDURE insertErrorManual:
    DEF INPUT PARAMETER p-errorNumber       AS INTEGER   NO-UNDO .
    DEF INPUT PARAMETER p-errorType         AS CHARACTER NO-UNDO .
    DEF INPUT PARAMETER p-errorSubType      AS CHARACTER NO-UNDO .
    DEF INPUT PARAMETER p-errorParameters   AS CHARACTER NO-UNDO .
    DEF INPUT PARAMETER p-errorDescription  AS CHARACTER NO-UNDO .
    DEF INPUT PARAMETER p-errorHelp         AS CHARACTER NO-UNDO .
    
    DEF VAR iErrorSequence  AS INTEGER   NO-UNDO INIT 1.
    
    FIND LAST RowErrors NO-LOCK NO-ERROR .
    IF AVAIL RowErrors THEN DO:
        ASSIGN iErrorSequence = iErrorSequence + 1 .
    END.
    CREATE RowErrors . ASSIGN 
        RowErrors.ErrorSequence    = iErrorSequence
        RowErrors.ErrorNumber      = p-errorNumber
        RowErrors.ErrorType        = p-errorType
        RowErrors.ErrorSubType     = p-errorSubType
        RowErrors.ErrorParameters  = p-errorParameters
        RowErrors.ErrorDescription = p-errorDescription
        RowErrors.ErrorHelp        = p-errorHelp
        .
    RETURN "OK":U .
END PROCEDURE.
