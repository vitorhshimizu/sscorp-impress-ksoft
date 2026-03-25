/*
Revisado conforme APB325AA.p padrao
*/

DEF BUFFER fornecedor   FOR emscad.fornecedor .
DEF BUFFER espec_docto  FOR emscad.espec_docto .

DEF TEMP-TABLE tt-forn NO-UNDO
    FIELD cdn_fornecedor    LIKE fornecedor.cdn_fornecedor
    FIELD nom_abrev         LIKE fornecedor.nom_abrev
    FIELD nom_pessoa        LIKE fornecedor.nom_pessoa
    FIELD cod_grp_fornec    LIKE fornecedor.cod_grp_fornec
    FIELD vl_periodo        AS DECIMAL EXTENT 12
    FIELD vl_total          AS DECIMAL
    INDEX idx_key AS UNIQUE PRIMARY cdn_fornecedor
    .

DEF VAR i-mes           AS INT NO-UNDO .
DEF VAR de-vl           AS DECIMAL NO-UNDO .
DEF VAR i-cont-trans    AS INT NO-UNDO .
DEF VAR c-trans-abrev   AS CHAR NO-UNDO .

OUTPUT TO VALUE("C:\temp\payments.csv") NO-CONVERT .
            
PUT UNFORM "Est" .
PUT UNFORM ";Dt Trans" .
PUT UNFORM ";Supplier" .
PUT UNFORM ";Short Name" .
PUT UNFORM ";Payment Value" .
PUT UNFORM ";Payment Type" .
PUT UNFORM ";Payment ID" .
PUT UNFORM ";Payment Esp" .
PUT UNFORM SKIP .

ASSIGN c-trans-abrev = "IMPL,PGEF,PFCC,CPCC" .

FOR EACH estabelecimento NO-LOCK
    :
    DO i-cont-trans = 1 TO NUM-ENTRIES(c-trans-abrev)
        :
        FOR EACH movto_tit_ap NO-LOCK
            WHERE movto_tit_ap.cod_estab = estabelecimento.cod_estab
            AND   movto_tit_ap.ind_trans_ap_abrev  = ENTRY(i-cont-trans, c-trans-abrev)
            AND   movto_tit_ap.dat_transacao >= DATE("01/01/2025")
            AND   movto_tit_ap.dat_transacao <= DATE("31/12/2025")
            AND   movto_tit_ap.cdn_fornecedor <> 0
            AND   movto_tit_ap.log_movto_estordo = NO
            :
            ASSIGN i-mes = MONTH(movto_tit_ap.dat_transacao) .

            /* Filtrar especies consideradas */
            FIND FIRST espec_docto NO-LOCK
                WHERE espec_docto.cod_espec_docto = movto_tit_ap.cod_espec_docto
                .
            IF espec_docto.ind_tip_espec_docto <> "Normal" AND
               espec_docto.ind_tip_espec_docto <> "Nota Fiscal" AND 
               espec_docto.ind_tip_espec_docto <> "Previs∆o" AND
               espec_docto.ind_tip_espec_docto <> "Provis∆o" 
            THEN NEXT .

            /* Criar tt do fornecedor */
            FIND FIRST tt-forn
                WHERE tt-forn.cdn_fornecedor = movto_tit_ap.cdn_fornecedor
                NO-ERROR .
            IF NOT AVAIL tt-forn THEN DO:
                FIND FIRST fornecedor NO-LOCK 
                    WHERE fornecedor.cdn_fornecedor = movto_tit_ap.cdn_fornecedor
                    .
                CREATE tt-forn .
                BUFFER-COPY fornecedor TO tt-forn .
            END.
    
            /* Converte todos os valores para reais */
            ASSIGN de-vl = 0.
            FOR EACH val_tit_ap NO-LOCK
                WHERE val_tit_ap.cod_estab           = movto_tit_ap.cod_estab
                AND   val_tit_ap.num_id_tit_ap       = movto_tit_ap.num_id_tit_ap
                AND   val_tit_ap.cod_finalid_econ    = "Corrente"
                :
                ASSIGN de-vl = de-vl + val_tit_ap.val_origin_tit_ap .
            END.
    
            /* Somatorio mensal por fornecedor */
            ASSIGN tt-forn.vl_periodo[i-mes] = tt-forn.vl_periodo[i-mes] + de-vl .
            ASSIGN tt-forn.vl_total = tt-forn.vl_total + de-vl .

            /* Imprimir */
            PUT UNFORMATTED
                    movto_tit_ap.cod_estab
                ';' STRING(movto_tit_ap.dat_transacao, "99/99/9999")
                ';' tt-forn.cdn_fornecedor
                ';' tt-forn.nom_abrev
                ';' de-vl
                ';' movto_tit_ap.ind_trans_ap
                ';' movto_tit_ap.num_id_movto_tit_ap
                ';' movto_tit_ap.cod_espec_docto
                SKIP .
        END.
    END.
END.

OUTPUT CLOSE .

OUTPUT TO VALUE("C:\temp\supplier_turnover_by_payments.csv") NO-CONVERT .

PUT UNFORM "Supplier" .
PUT UNFORM ";Short Name" .
PUT UNFORM ";Name" .
PUT UNFORM ";Sup Group" .
PUT UNFORM ";T01;T02;T03;T04;T05;T06;T07;T08;T09;T10;T11;T12" .
PUT UNFORM ";Turnover Total" .
PUT UNFORM SKIP .

FOR EACH tt-forn NO-LOCK
    BY tt-forn.vl_total DESC
    :
    PUT UNFORMATTED
            tt-forn.cdn_fornecedor
        ';' tt-forn.nom_abrev
        ';' tt-forn.nom_pessoa
        ';' tt-forn.cod_grp_fornec
        .
    DO i-mes = 1 TO 12
        :
        PUT UNFORMATTED ';' tt-forn.vl_periodo[i-mes] .
    END.
    PUT UNFORMATTED
        ';' tt-forn.vl_total
        SKIP .
END.

OUTPUT CLOSE .




