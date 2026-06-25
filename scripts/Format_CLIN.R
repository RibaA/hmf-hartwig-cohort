library(stringr)
library(tibble)

args <- commandArgs(trailingOnly = TRUE)
#input_dir <- args[1]
#output_dir <- args[2]
#annot_dir <- args[3]

input_dir <- "data/input"
output_dir <- "data/output"
annot_dir <- "data/annot"

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R")
#source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/annotate_tissue.R")
#source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/annotate_drug.R")

clin = read.csv( file.path(input_dir, "CLIN.txt"), stringsAsFactors=FALSE , sep="\t" , header=TRUE )
  
cols <- c('sampleId', "gender", 'primaryTumorLocation', "primaryTumorType", "consolidatedTreatmentType", 'firstResponse')

sub.clin <- cbind(clin[, cols], NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA)
colnames(sub.clin ) <- c("patient", "sex", "primary", "histo", "drug_type", "response.other.info", "stage", "response", 
                         "recist", "os", "t.os", "pfs", "t.pfs", "rna", "rna_info", "dna", "dna_info", 'age')

clin <- cbind(sub.clin , clin[, colnames(clin)[!colnames(clin) %in% colnames(sub.clin)]])

clin$sex <- ifelse(clin$sex == 'male', 'M', 'F')
clin$rna <- 'rnaseq'
clin$rna_info <- 'tpm'

## age
clin$birthYear[clin$birthYear %in% c("null", "", "NULL")] <- NA
clin$birthYear <- as.numeric(clin$birthYear)
clin$biopsyDate <- as.Date(clin$biopsyDate)
clin$age <- ifelse(
  !is.na(clin$birthYear) &
  !is.na(clin$biopsyDate),
  as.numeric(format(clin$biopsyDate, "%Y")) -
    clin$birthYear,
  NA
)

# response
clin$response.other.info[clin$response.other.info == "null"] <- NA
clin$response.other.info <- dplyr::recode(
  clin$response.other.info,
  "iCR" = "CR",
  "iPR" = "PR",
  "iSD" = "SD",
  "iUPD" = "UPD",
  "Clinical progression" = "PD",
  "STOP_TREATMENT;DEATH" = "PD",
  "Non-CR/Non-PD" = "NON_CR_NON_PD",
  "non CR/non PD" = "NON_CR_NON_PD",
  "non iCR/non iPD" = "NON_CR_NON_PD"
)

# Define "response" based on values in "response.other.info"
clin$response <- NA
clin$response[
    clin$response.other.info %in% c("CR", "PR")
] <- "R"

clin$response[
    clin$response.other.info %in% c("SD", "PD")
] <- "NR"

clin$response[
    clin$response.other.info %in% c(
        "UPD",
        "NON_CR_NON_PD",
        "CLINICAL_BENEFIT",
        "ND"
    )
] <- NA

# pretreatment
clin$systemic_pre <- toupper(trimws(clin$hasSystemicPreTreatment))
clin$systemic_pre[clin$systemic_pre %in% c("NULL", "")] <- NA

# Treatment status
clin$treatment_status <- NA
clin$treatment_status[clin$systemic_pre == "NO"]  <- "Treatment-naive"
clin$treatment_status[clin$systemic_pre == "YES"] <- "Previously-treated"

## drug type
clin$drug_type <- trimws(clin$drug_type)
clin$drug_type[clin$drug_type %in% c("null", "NULL", "Unknown", "")] <- NA
clin$drug_type <- dplyr::recode(
  clin$drug_type,
  "targeted therapy" = "Targeted therapy",
  "Androgen/estrogen deprivation therapy" = "Hormonal therapy"
)

rownames(clin) <- clin$patient
write.table( clin , file=file.path(output_dir, "CLIN.csv") , quote=FALSE , sep=";" , col.names=TRUE , row.names=FALSE )

