/*
*/

OUTPUT TO VALUE("C:\temp\Itinerarios_Pto_Controle_CD2567.csv") NO-CONVERT .

PUT UNFORM "ID Itiner rio;" .
PUT UNFORM "Descri‡Æo;" .
PUT UNFORM "Seq;" .
PUT UNFORM "ID Ponto Controle;" .
PUT UNFORM "Descri‡Æo;" .
PUT UNFORM "Dias Trajeto" .
PUT UNFORM SKIP .

FOR EACH itinerario NO-LOCK
    ,
    EACH pto-itiner NO-LOCK OF itinerario
    ,
    FIRST pto-contr NO-LOCK OF pto-itiner
    :
    PUT UNFORMATTED
            itinerario.cod-itiner
        ';' itinerario.descricao
        ';' pto-itiner.sequencia
        ';' pto-itiner.cod-pto-contr
        ';' pto-contr.descricao
        ';' pto-itiner.nr-dias
        SKIP .
END.

OUTPUT CLOSE .


