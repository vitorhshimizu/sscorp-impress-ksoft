
/*
FIND FIRST histor-tag NO-LOCK
    WHERE histor-tag.nom-tab-histor-tag = "xml-aut-nota-fiscal"
    AND histor-tag.cod-histor-tag = "41260302644907000119550030000743131669091890"
    .

COPY-LOB histor-tag.blb-arq-xml TO FILE "C:\temp\nota.xml" NO-CONVERT.
*/

{include/i-epc200.i ft0527f4}

{adapters/xml/ep2/axsep037.i} /*Temp-Tables da NF-e, ttNFe, ttIde, ttDet, etc. | 3.10*/

RUN ftp/ftapi553.p
    (INPUT "2"                   ,
     INPUT ""  ,
     INPUT ""         ,
     INPUT "41260302644907000119550030000743131669091890" ,
OUTPUT TABLE ttAdi              ,      
OUTPUT TABLE ttArma             ,
OUTPUT TABLE ttAutXML           ,
OUTPUT TABLE ttAvulsa           ,
OUTPUT TABLE ttCobr             ,
OUTPUT TABLE ttCOFINSAliq       ,
OUTPUT TABLE ttCOFINSNT         ,
OUTPUT TABLE ttCOFINSOutr       ,
OUTPUT TABLE ttCOFINSQtde       ,
OUTPUT TABLE ttCOFINSST         ,
OUTPUT TABLE ttICMSUFDest       ,
OUTPUT TABLE ttComb             ,
OUTPUT TABLE ttOrigComb         ,
OUTPUT TABLE ttCompra           ,
OUTPUT TABLE ttDest             ,
OUTPUT TABLE ttDet              ,
OUTPUT TABLE ttDetObsCont       ,
OUTPUT TABLE ttDetObsFisco      ,
OUTPUT TABLE ttDetExport        ,
OUTPUT TABLE ttDI               ,
OUTPUT TABLE ttDup              ,
OUTPUT TABLE ttEmit             ,
OUTPUT TABLE ttEntrega          ,
OUTPUT TABLE ttExporta          ,
OUTPUT TABLE ttICMS00           ,
OUTPUT TABLE ttICMS02            ,
OUTPUT TABLE ttICMS10           ,
OUTPUT TABLE ttICMS15            ,
OUTPUT TABLE ttICMS20            ,
OUTPUT TABLE ttICMS30            ,
OUTPUT TABLE ttICMS40            ,
OUTPUT TABLE ttICMS51            ,
OUTPUT TABLE ttICMS53             ,
OUTPUT TABLE ttICMS60             ,
OUTPUT TABLE ttICMS61             ,
OUTPUT TABLE ttICMS70             ,
OUTPUT TABLE ttICMS90             ,
OUTPUT TABLE ttICMSTot            ,
OUTPUT TABLE ttIde                ,
OUTPUT TABLE ttII                 ,
OUTPUT TABLE ttImpostoDevol        ,
OUTPUT TABLE ttInfAdic             ,
OUTPUT TABLE ttIPI                 ,
OUTPUT TABLE ttISSQN               ,
OUTPUT TABLE ttISSQNtot            ,
OUTPUT TABLE ttLacres               ,
OUTPUT TABLE ttMed                  ,
OUTPUT TABLE ttNFe                  ,
OUTPUT TABLE ttrefNF                ,
OUTPUT TABLE ttObsCont             ,
OUTPUT TABLE ttObsFisco            ,
OUTPUT TABLE ttPISAliq             ,
OUTPUT TABLE ttPISNT               ,
OUTPUT TABLE ttPISOutr             ,
OUTPUT TABLE ttPISQtde             ,
OUTPUT TABLE ttPISST               ,
OUTPUT TABLE ttProcRef             ,
OUTPUT TABLE ttReboque             ,
OUTPUT TABLE ttRetirada            ,
OUTPUT TABLE ttRetTrib             ,
OUTPUT TABLE ttTransp              ,
OUTPUT TABLE ttVeic                ,
OUTPUT TABLE ttVol                 ,
OUTPUT TABLE ttrefNFP               ,
OUTPUT TABLE ttrefCTe               ,
OUTPUT TABLE ttrefECF               ,
OUTPUT TABLE ttICMSPart             ,
OUTPUT TABLE ttICMSST               ,
OUTPUT TABLE ttICMSSN101            ,
OUTPUT TABLE ttICMSSN102            ,
OUTPUT TABLE ttICMSSN201            ,
OUTPUT TABLE ttICMSSN202            ,
OUTPUT TABLE ttICMSSN500            ,
OUTPUT TABLE ttICMSSN900            ,
OUTPUT TABLE ttCana                 ,
OUTPUT TABLE ttForDia               ,
OUTPUT TABLE ttDeduc                ,
OUTPUT TABLE ttRastro               ,
OUTPUT TABLE ttPag                  ,
OUTPUT TABLE ttInfIntermed          ,
OUTPUT TABLE ttDetPag               ,
OUTPUT TABLE ttDetPresumido         ,
OUTPUT TABLE ttAgropecuario          ,
OUTPUT TABLE ttgCompraGov            ,
OUTPUT TABLE ttgPagAntecipado        ,
OUTPUT TABLE ttIBSCBS                ,
OUTPUT TABLE ttTribRT                 ,
OUTPUT TABLE ttgTribRegular           ,
OUTPUT TABLE ttgCredPresOper          ,
OUTPUT TABLE ttgIBSCBSCredPres         ,
OUTPUT TABLE ttgTribCompraGov          ,
OUTPUT TABLE ttgIBSCBSMono             ,
OUTPUT TABLE ttgTransfCred             ,
OUTPUT TABLE ttgAjusteCompet           ,
OUTPUT TABLE ttgEstornoCred            ,
OUTPUT TABLE ttgCredPresIBSZFM        ,
OUTPUT TABLE ttVB                     ,
OUTPUT TABLE ttDFeReferenciado        ,
OUTPUT TABLE ttTotIBSCBSIS            )
.

DEF VAR iCont   AS INT NO-UNDO .

FOR EACH ttDet NO-LOCK
    :
    MESSAGE
        ttDet.xProd SKIP
        ttDet.infAdProd SKIP
        VIEW-AS ALERT-BOX . 

    DO iCont = 1 TO LENGTH(ttDet.xProd)
        :
        MESSAGE
            iCont SKIP
            SUBSTRING(ttDet.xProd, iCont, 1) SKIP
            ASC(SUBSTRING(ttDet.xProd, iCont, 1)) SKIP
            VIEW-AS ALERT-BOX .
    END.

END.
