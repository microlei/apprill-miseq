#configurations for running the code
#Anything you would normally "hardcode" like paths, variables for the dada2 pipeline, etc go here
configfile: "config.yaml" 

#Gets sample names of forward reads

WC = glob_wildcards(config['path']+"{names}_{dir}.fastq.gz")
SAMPLES = WC.names
R1 = expand(config['path']+'{names}_1.fastq.gz', names=WC.names)
R2 = expand(config['path']+'{names}_2.fastq.gz', names=WC.names)

#local rules marks a rule as local and does not need to be submitted as a job to the cluster
localrules: all, plotQP, learnError

#this rule specifies all things you want generated
rule all:
	input:
		"output/filtered.rds",
		"output/errorRates_R1.rds",
		"output/seqtab_nochimeras.rds",
		#"output/track_reads.csv",
		"output/ASVs.txt",
		"output/taxonomy.txt",
		"output/ASVseqs.txt",
		"output/tree.nwk"

#clears all outputs (except for plotted quality profiles)
rule clean:
    shell:
        '''
        rm output/*.rds
        rm output/*.txt
        rm output/*.csv
	rm logs/*
        '''

#plots quality profiles
rule plotQP:
	input: R1, R2
	output: 
		R1 = expand('output/figures/qualityProfiles/R1/{sample}_R1_qual.jpg',sample=SAMPLES),
		R2 = expand('output/figures/qualityProfiles/R2/{sample}_R2_qual.jpg',sample=SAMPLES)
	script: 'scripts/plotQP.R'

#quality filters R1 and R2 (forward and reverse reads)
rule filter:
	input:
		R1=R1,
		R2=R2
	output:
		R1 = expand(config['path']+"filtered/{sample}_R1.fastq.gz", sample=SAMPLES), 
		R2 = expand(config['path']+"filtered/{sample}_R2.fastq.gz", sample=SAMPLES),
		filtered = "output/filtered.rds"
	params:
		samples = SAMPLES
	log:
		"logs/filter.txt" #I always have the logs go to one place so I can easily see what went wrong
	script:
		"scripts/filter.R"

#error modeling and plotting the errors
rule learnError:
	input:
		R1 = rules.filter.output.R1,
		R2 = rules.filter.output.R2 #note you can declare the output of another rule as a dependency
	output:
		errR1 = "output/errorRates_R1.rds",
		errR2 = "output/errorRates_R2.rds",
		plotErrR1 = "output/figures/errorRates_R1.pdf",
		plotErrR2 = "output/figures/errorRates_R2.pdf"
	log:
		"logs/learnError.txt"
	script:
		"scripts/learnError.R"

rule dereplicate:
	input:
		R1 = rules.filter.output.R1,
		R2 = rules.filter.output.R2,
		errR1 = rules.learnError.output.errR1,
		errR2 = rules.learnError.output.errR2
	output:
		seqtab = "output/seqtab_withchimeras.rds"
	log:
		"logs/dereplicate.txt"
	script:
		"scripts/dereplicate.R"

#this is where the chimeras get removed
rule removeChimeras:
	input:
		seqtab = rules.dereplicate.output.seqtab,
	output:
		seqtab = "output/seqtab_nochimeras.rds",
	log:
		"logs/removeChimeras.txt"
	script:
		"scripts/removeChimeras.R"

#this is where the results are tracked
#I moved it into its own script in case I wanted to format it differently
rule taxonomy:
	input:
		seqtab = rules.removeChimeras.output.seqtab,
	output:
		otus = "output/ASVs.txt",
		taxonomy = "output/taxonomy.txt",
		ASVseqs = "output/ASVseqs.txt"
	params:
		samples = SAMPLES
	log:
		"logs/taxonomy.txt"
	script:
		"scripts/taxonomy.R"

#Generate de novo phylogenetic trees
rule alignment:
	input:
		seqtab = rules.removeChimeras.output.seqtab
	output:
		alignment = "output/alignment.fasta",
	log:
		"logs/alignment.txt"
	script:
		"scripts/alignment.R"

rule tree:
	input:
		alignment = rules.alignment.output.alignment
	output:
		tree = "output/tree.nwk"
	log:
		"logs/tree.txt"
	shell:
		"""
		set +u
		module load anaconda/5.1
		source activate snakemakedada
		set -u
		FastTreeMP -gamma -nt -log {log} < {input} > {output}
		"""
