/*
NF-e n∆o gerada 1
Em processamento 2
Uso autorizado 3
Uso denegado 4
Documento Rejeitado 5
Documento Cancelado 6
Documento Inutilizado 7
Em processamento no aplicativo de transmiss∆o 8
Em processamento na SEFAZ 9
Em processamento no SCAN 10
NF-e Gerada 11
NF-e em Processo de Cancelamento 12
NF-e em Processo de Inutilizaá∆o 13
NF-e Pendente de Retorno 14
EPEC recebido pelo SCE 15
*/                       

FIND nota-fiscal
    WHERE nota-fiscal.cod-estabel = "101"
    AND   nota-fiscal.serie = "3"
    AND   nota-fiscal.nr-nota-fis = "0078767"
    .

ASSIGN nota-fiscal.idi-sit-nf-eletro = 7 .

/* Se for cancelada ou inutilizada deve rodar tambem o codigo abaixo*/
/*
ASSIGN nota-fiscal.dt-cancela = nota-fiscal.dt-emis-nota .
FOR EACH it-nota-fisc OF nota-fiscal
    :
    ASSIGN it-nota-fisc.dt-cancela = nota-fiscal.dt-cancela .
END.
*/
