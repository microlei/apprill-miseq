# inputs: seqtab (seqtab with no chimeras.rds)
# outputs: alignment (alignment.fasta)

sink(snakemake@log[[1]])
library(dada2)
library(DECIPHER)

seqtab <- readRDS(file=snakemake@input[['seqtab']])
seqs <- getSequences(seqtab)
names(seqs) <- paste0("ASV", seq(from=1, to=dim(seqtab)[2], by=1))

dna <- DNAStringSet(seqs)
cat("Unaligned sequences \n")
dna
cat("Beginning alignment: \n")
alignment <- AlignSeqs(dna, anchor=NA,verbose=TRUE)
cat("Alignment finished, peek at alignment \n")
head(alignment)

writeXStringSet(alignment, file=snakemake@output[['alignment']])
