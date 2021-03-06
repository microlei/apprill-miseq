# Inputs: filt, derep, nochim, which are all tab delimited files that just need to be bound together
# Outputs: combined tab delimited file

sink(snakemake@log[[1]])
#library(dplyr)

a <- read.table(file=snakemake@input[['filt']], sep="\t")
b <- read.table(file=snakemake@input[['derep']], sep="\t")
c <- read.table(file=snakemake@input[['nochim']], sep="\t")

#save.image("track.RData")
cat("head(a)\n")
head(a)
cat("head(b)\n")
head(b)
cat("head(c)\n")
head(c)

#to do: use full join in the future in case some samples got dropped
#track <- full_join(a,b) %>% full_join(c)

track <- cbind(a,b,c)
write.table(track, file=snakemake@output[['track']], sep='\t')
