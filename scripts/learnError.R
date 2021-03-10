# Input: R1 (filtered forward reads)
# Output: errR1 = "stats/errorRate_R1.rds", plotErrR1 = "figures/errorRate_R1.pdf"

sink(snakemake@log[[1]])

cat("Beginning learning error rates \n")
library(dada2)
library(ggplot2)

#for the default option
errF <- learnErrors(snakemake@input[['R1']], nbases = snakemake@config[['nbases']], multithread=TRUE, randomize=TRUE, verbose=2)
errR <- learnErrors(snakemake@input[['R2']], nbases = snakemake@config[['nbases']], multithread=TRUE, randomize=TRUE, verbose=2)

saveRDS(errF, file=snakemake@output[['errR1']])
plotErrors(errF, nominalQ=TRUE)
ggsave(snakemake@output[['plotErrR1']])

saveRDS(errR, file=snakemake@output[["errR2"]])
plotErrors(errR, nominalQ=TRUE)
ggsave(snakemake@output[['plotErrR2']])
