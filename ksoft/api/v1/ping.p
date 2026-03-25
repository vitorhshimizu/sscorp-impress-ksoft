/*
*/

{utp/ut-api.i}

{utp/ut-glob.i}

{utp/ut-api-action.i "pi-get" "GET" "*" }
{utp/ut-api-notfound.i}
{utils/fnAPI.i}

PROCEDURE pi-get:
    DEF INPUT  PARAM oIn    AS JsonObject NO-UNDO .
    DEF OUTPUT PARAM oOut   AS JsonObject NO-UNDO .
     
    oOut = fnApiOK() .
    oOut:ADD("_version", "1.00.00.000") .
    oOut:ADD("_userid", c-seg-usuario) .
    oOut:ADD("data", oIn) .
END.

