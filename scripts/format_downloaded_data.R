library(data.table)
library(readxl)
library(stringr)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
#work_dir <- args[1]
work_dir <- "data"

# CLIN.txt
# load clinical metadata from https://precog.stanford.edu/
clin <- read.csv(file.path(work_dir, 'metadata.csv'), quote = '', sep = "\t")

# EXP_TPM.tsv
rna <- data.table::fread(
  text = readLines(
    gzfile(file.path(work_dir, "rna_gene_matrix_genename.csv.gz")),
    n = 1000000
  )
)

expr <- as.data.frame(rna)
gene_col <- "GeneName"
expr_mat <- as.matrix(expr[, -1])
rownames(expr_mat) <- expr[[gene_col]]
storage.mode(expr_mat) <- "numeric"

## match clinical metadata
expr_samples <- colnames(expr_mat)
clin_rna <- clin[
  match(expr_samples, clin$sampleId),
]

stopifnot(
  all(clin_rna$sampleId == expr_samples)
)

write.table(clin_rna, file=file.path(work_dir, 'CLIN.txt'), sep = "\t" , quote = FALSE , row.names = FALSE)

expr <- expr[
  !duplicated(expr$GeneName),
]

fwrite(expr, file = file.path(work_dir, "EXP_TPM.tsv"), sep = "\t", quote = FALSE)



