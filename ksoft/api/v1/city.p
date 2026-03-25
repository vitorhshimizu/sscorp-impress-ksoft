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

    DEF BUFFER cidade FOR mgcad.cidade .
    DEF BUFFER pais   FOR mgcad.pais   .

    DEF VAR oCidade         AS JsonObject NO-UNDO.
    DEF VAR oCidadeList     AS JsonArray  NO-UNDO. 
        
    ASSIGN oCidadeList = NEW JsonArray() .
    FOR EACH cidade
        :
        FIND FIRST pais WHERE pais.nome-pais = cidade.pais .
        oCidade = NEW JsonObject() .
        oCidade:ADD("cidade"        , cidade.cidade) .
        oCidade:ADD("pais"          , cidade.pais) .
        oCidade:ADD("uf"            , cidade.estado) .
        oCidade:ADD("cod_pais_iso"  , SUBSTRING(pais.char-1, 23,2)) .
        oCidade:ADD("sigla"         , cidade.sigla) .

        oCidadeList:ADD(oCidade) .
    END.

    oOut = fnApiOK() .
    oOut:ADD("records", oCidadeList) . 
END.

