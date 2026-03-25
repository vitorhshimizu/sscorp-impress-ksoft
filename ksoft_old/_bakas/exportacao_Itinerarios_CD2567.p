/*
*/

OUTPUT TO VALUE("C:\temp\Itinerarios_CD2567.csv") NO-CONVERT .

PUT UNFORM "ID Itiner rio;" .
PUT UNFORM "Descri‡Æo;" .
PUT UNFORM "Pto Despacho;" .
PUT UNFORM "Pto Embarque;" .
PUT UNFORM "Pto Nacionaliz;" .
PUT UNFORM "Pto Recebimento;" .
PUT UNFORM "Pto Encerramento;" .
PUT UNFORM "Dias Trajeto" .
PUT UNFORM SKIP .

FOR EACH itinerario NO-LOCK
    :
    PUT UNFORMATTED
            itinerario.cod-itiner
        ';' itinerario.descricao
        ';' itinerario.pto-despacho
        ';' itinerario.pto-embarque
        ';' itinerario.pto-desembarque
        ';' SUBSTRING(itinerario.char-1,1,5)
        ';' itinerario.pto-chegada
        ';' itinerario.nr-dias
        SKIP .
END.

OUTPUT CLOSE .
