/*
*/

{PDFinclude/pdf_inc.i} /* h_PDFinc */
ASSIGN h_PDFinc:PRIVATE-DATA = 'Persistent PDFinc' .

DEF VAR hPDF        AS HANDLE NO-UNDO .
DEF VAR cStr        AS CHAR NO-UNDO .
DEF VAR cArqPDF     AS CHAR NO-UNDO .

ASSIGN hPDF = h_PDFinc .
ASSIGN cStr = "Spdf" .
ASSIGN cArqPDF = SESSION:TEMP-DIR + "teste.pdf" .

RUN pdf_new IN hPDF(cStr, cArqPDF) .
RUN pdf_set_PaperType IN hPDF(cStr, "A4").
RUN pdf_load_template IN hPDF(cStr, "cabecalho", SEARCH("layout/esft0003_cabecalho.txt")) .

RUN pdf_new_page IN hPDF(cStr).
RUN pdf_use_template IN hPDF(cStr, "cabecalho").

/**/
FINALLY:
    IF VALID-HANDLE(hPDF) THEN DO:
        RUN pdf_close IN hPDF(cStr).
        DELETE PROCEDURE hPDF NO-ERROR .
        ASSIGN hPDF = ? .
    END.
END FINALLY.


