library(data.table)
library(R.utils)

#args <- commandArgs(trailingOnly = TRUE)
#input_dir <- args[1]
#output_dir <- args[2]

input_dir <- "data/input"
output_dir <- "data/output"

expr <- fread(
    file.path(input_dir, "EXP_TPM.tsv"),
    sep = "\t",
    data.table = FALSE
)

tpm <- expr

#############################################################################
#############################################################################
case = read.csv( file.path(output_dir, "cased_sequenced.csv"), stringsAsFactors=FALSE , sep=";" )
tpm = tpm[ , colnames(tpm) %in% case[ case$expr %in% 1 , ]$patient ] 
tpm = log2(tpm+1)
tpm <- data.frame(
    GeneName = expr[,1],
    tpm,
    check.names = FALSE
)

fwrite(
    tpm ,
    file = file.path(output_dir, "EXPR.csv"),
    sep = ";"
)
