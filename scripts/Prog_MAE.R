library(Biobase)
library(SummarizedExperiment)
library(MultiAssayExperiment)
library(stringr)
library(data.table)

dir <- "data/output"

annot <- fread(file.path(dir, "Human.GRCh38.p13.annot.tsv"))
annot <- annot[!duplicated(annot$Symbol), ]
annot <- annot[!duplicated(annot$EnsemblGeneID), ]

tpm <- fread(file.path(dir, "EXPR.csv"),  sep = ";")
expr <- as.data.frame(tpm)
rownames(expr) <- expr[,1]
expr <- expr[, -1]

clin <- read.table(file.path(dir, "CLIN.csv") ,  
    sep = ";",
    header = TRUE,
    quote = "",
    fill = TRUE,
    stringsAsFactors = FALSE)

clin <- clin[clin$sex != '', ]
rownames(clin) <- clin$patient

int <- intersect(rownames(expr), annot$Symbol) # 25503
expr <- expr[rownames(expr) %in% int, ]
idx <- match(rownames(expr), annot$Symbol)
annot <- annot[idx, ]
rownames(annot) <- annot$Symbol

se_rna <- SummarizedExperiment(
    assays = list(
        tpm = as.matrix(expr)
    ),
    rowData = annot,
    colData = clin
)

mae <- MultiAssayExperiment(
    experiments = list(
        rna = se_rna
    )
)

saveRDS(mae, file=file.path(dir, "ICB_Hartwig.rds"))
