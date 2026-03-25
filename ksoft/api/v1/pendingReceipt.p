/*
*/

{utp/ut-api.i}
{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .

    DEF VAR oRecord           AS JsonObject NO-UNDO.
    DEF VAR oRecordList       AS JsonArray  NO-UNDO. 

    ASSIGN oRecordList = NEW JsonArray() .
    FOR EACH docum-est NO-LOCK
        WHERE docum-est.ce-atual = NO
        :
        FIND FIRST emitente NO-LOCK
            WHERE emitente.cod-emitente = docum-est.cod-emitente
            .
        oRecord = NEW JsonObject() .
        oRecord:ADD("cod_estabel"   , docum-est.cod-estabel) .
        oRecord:ADD("cod_cli_for"   , docum-est.cod-emitente).
        oRecord:ADD("nome_abrev"    , emitente.nome-abrev) .
        oRecord:ADD("serie"         , docum-est.serie-docto) .
        oRecord:ADD("nro_docto"     , docum-est.nro-docto) .
        oRecord:ADD("nat_operacao"  , docum-est.nat-operacao ).
        oRecord:ADD("tot_valor"     , docum-est.tot-valor ).
        oRecordList:ADD(oRecord) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("records", oRecordList) . 
END.

