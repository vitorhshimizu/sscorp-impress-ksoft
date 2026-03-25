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

    DEF BUFFER pais   FOR mgcad.pais   .

    DEF VAR oPais           AS JsonObject NO-UNDO.
    DEF VAR oPaisList       AS JsonArray  NO-UNDO. 

    ASSIGN oPaisList        = NEW JsonArray() .

    FOR EACH pais
        :
        oPais = NEW JsonObject() .
        oPais:ADD("cod_pais"     , pais.cod-pais)                .
        oPais:ADD("nome_pais"    , pais.nome-pais)               .
        oPais:ADD("nome_compl"   , pais.nome-compl)              .
        oPais:ADD("cod_pais_iso" , SUBSTRING(pais.char-1, 23,2)) .
        

        oPaisList:ADD(oPais) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("records", oPaisList) . 
END.

