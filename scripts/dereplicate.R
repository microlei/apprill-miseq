# Inputs: R1 (filtered R1), errR1 (error model for R1), same for R2 and errR2
# Outputs: seqtab ("output/seqtab_withchimeras.rds")

sink(snakemake@log[[1]])
library(dada2)

cat("Beginning output for dereplicating \n")

#errR1 and errR2 is an .rds file so it must be actually loaded into a variable

errR1 <- readRDS(file=snakemake@input[['errR1']])
errR2 <- readRDS(file=snakemake@input[['errR2']])
filtFs <- snakemake@input[['R1']]
filtRs <- snakemake@input[['R2']]

dadaFs <- dada(filtFs, errR1, multithread=TRUE)
dadaRs <- dada(filtRs, errR2, multithread=TRUE)

mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)

head(mergers[[1]])

cat("Constructing sequence table \n")

seqtab <- makeSequenceTable(mergers)
cat("Dimensions of sequence table: \n")
dim(seqtab)
cat("Sequences are of length:\n")
table(nchar(getSequences(seqtab)))

range <- snakemake@config[['derepRange']]
mode <- as.numeric(names(sort(table(nchar(getSequences(seqtab))), TRUE))[1])
cat("Remove sequences that are not more than ", range, " bp away from the mode, which is ",mode, " \n")

seqtab <- seqtab[,nchar(colnames(seqtab)) %in% seq(mode-range, mode+range)]
table(nchar(getSequences(seqtab)))

saveRDS(seqtab, file=snakemake@output[['seqtab']])
