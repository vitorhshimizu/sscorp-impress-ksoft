
/*
*/

DEF VAR cNarrativa  AS CHAR NO-UNDO .
DEF VAR iPedSeqIni  AS INT NO-UNDO .
DEF VAR iPedSeqFim  AS INT NO-UNDO .
DEF VAR cPedSeq     AS CHAR NO-UNDO .

ASSIGN cNarrativa = "90112 UNICOLOR BRANCO 181 IP063 2760x1860mm | PAPEL IMPREG | | Certificado do Produto FSC Mix Credit SGSCH-COC-009163 | Codigo producto del cliente 20000021 | Seu material BRANCO | Ped/Seq: 4520125646/130" .
ASSIGN iPedSeqIni = INDEX(cNarrativa, "Ped/Seq: ", 1) + 9 .

IF iPedSeqIni > 0 THEN DO:
    ASSIGN iPedSeqFim = LENGTH(cNarrativa) .
    ASSIGN cPedSeq = SUBSTRING(cNarrativa, iPedSeqIni, iPedSeqFim - iPedSeqIni + 1) . 
END.

MESSAGE
    iPedSeqIni SKIP
    iPedSeqFim SKIP
    cPedSeq SKIP
    ENTRY(1, cPedSeq, "/") SKIP
    ENTRY(2, cPedSeq, "/") SKIP
    VIEW-AS ALERT-BOX .


