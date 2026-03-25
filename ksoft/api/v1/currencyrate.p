/*
*/

{utp/ut-api.i}

{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}
{utils/fnFormatDate.i}

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn        AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut       AS JsonObject NO-UNDO .

    DEF BUFFER cotacao FOR mgcad.cotacao .

    DEF VAR iMoeda      AS INT NO-UNDO .
    DEF VAR dtCotacao   AS DATE NO-UNDO .
    DEF VAR cPeriodo    AS CHAR NO-UNDO .
    DEF VAR deCotacao   AS DECIMAL NO-UNDO .

    ASSIGN iMoeda = INT(fnApiReadParam(oIn, "curCode")) NO-ERROR .
    ASSIGN dtCotacao = fnFormatDateYYYYMMDDr(fnApiReadParam(oIn, "curDate")) NO-ERROR .

    IF iMoeda = ? OR dtCotacao = ? THEN DO:
        oOut = fnApiErro("Erro nos parƒmetros informados para a busca") . 
    END.

    ASSIGN cPeriodo = STRING(YEAR(dtCotacao), "9999") + STRING(MONTH(dtCotacao), "99") .

    FIND FIRST cotacao NO-LOCK
        WHERE cotacao.mo-codigo = iMoeda
        AND   cotacao.ano-periodo = cPeriodo
        NO-ERROR .
    IF NOT AVAIL cotacao THEN DO:
        oOut = fnApiErro("Cota‡Æo para a moeda Informada nÆo foi encontrada") .
        RETURN .
    END.

    ASSIGN deCotacao = cotacao.cotacao[DAY(dtCotacao)] . 
    IF deCotacao = ? THEN ASSIGN deCotacao = 0 .

    oOut = fnApiOK() .
    oOut:ADD("cur_code"    , iMoeda) .
    oOut:ADD("cur_date"    , dtCotacao ) .
    oOut:ADD("brl_rate"    , deCotacao) .
END PROCEDURE .

