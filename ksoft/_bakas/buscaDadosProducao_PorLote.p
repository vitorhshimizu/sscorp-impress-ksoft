/*
*/

DEF BUFFER cst-prod     FOR cst_embalagem_producao .

FIND cst-prod NO-LOCK
    WHERE cst-prod.nr-ord-produ = 25040056
    AND   cst-prod.num-seq-rep = 1
    .




