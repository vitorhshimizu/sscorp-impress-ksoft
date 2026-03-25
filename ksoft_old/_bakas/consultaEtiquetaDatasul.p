/*
*/

{utils/fnPlanilha.i} 

DEF BUFFER cst-etiqueta FOR cst_embalagem_producao .

RUN piIniPlanilha(SESSION:TEMP-DIR + "etiquetas.xlsx") .
RUN piCol("ID Label"        , "CHAR", "12") .
RUN piCol("MA Number"       , "CHAR", "16") .
RUN piCol("MA Description"  , "CHAR", "60") .
RUN piCol("MA Width"        , "INT" , ">>>,>>>,>>9") .
RUN piCol("HU Number"       , "CHAR", "14") .
RUN piCol("Batch Number"    , "CHAR", "20") .
RUN piCol("Square Meter"    , "DEC" , ">>>,>>>,>>9.99") .
RUN piCol("Gross Weight"    , "DEC" , ">>>,>>>,>>9.999") .
RUN piCol("Net Weight"      , "DEC" , ">>>,>>>,>>9.999") .

FOR EACH zz-etiqueta NO-LOCK
    WHERE zz-etiqueta.cod-etiqueta = "000000383370"
    :
    FIND FIRST ITEM NO-LOCK
        WHERE ITEM.it-codigo = zz-etiqueta.it-codigo
        .

    FIND FIRST cst-etiqueta NO-LOCK
        WHERE cst-etiqueta.id = INT(zz-etiqueta.cod-etiqueta)
        .

    RUN piLin .
    RUN piCel(zz-etiqueta.cod-etiqueta) .
    RUN piCel(zz-etiqueta.it-codigo) .
    RUN piCel(ITEM.desc-item) .
    RUN piCel(cst-etiqueta.largura_saida) .
    RUN piCel(zz-etiqueta.cod-etiqueta) .
    RUN piCel(zz-etiqueta.lote) .
    RUN piCel(cst-etiqueta.m_quadrados) .
    RUN piCel(cst-etiqueta.kg_bruto) .
    RUN piCel(cst-etiqueta.kg_liquido) .
END.

RUN piFimPlanilha("Etiquetas", NO, YES) .

/* ***************************  PROCEDURES  ************************** */
