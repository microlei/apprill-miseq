# Snakemake workflow for processing Illumina MiSeq 16S V4 sequences through dada2
This workflow takes as input Illumina MiSeq files in fastq.gz format and puts it through the dada2 pipeline to generate merged, clean reads. It also uses DECIPHER and FastTree to generate a phylogenetic tree.

## Step 0 create your environment or clone the one in this repo
### Create your own environment using conda
On our Poseidon servers this looks like:
```
module load anaconda/5.1
conda create -c conda-forge -c bioconda -n snakemakedada snakemake
```
Feel free to replace snakemakedada with whatever you want to name it.
Activate your environment and check the version numbers of the software you're using.
```
source activate snakemakedada
R --version
snakemake --version
python --version
```
You may need to update to the latest versions (I did for R and snakemake when I first made the environment)
```
conda update R
conda update snakemake
```
### Install dada2 and DECIPHER in R.
Enter R and install dada2 and DECIPHER. This will take a while and you will be prompted to update other R packages so you can't just walk away.
```
$ R
>> if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

>> BiocManager::install("dada2")
>> BiocManager::install("DECIPHER")
```
*Alternatively* you can use the environment.yml file in this repo to directly clone the environment I used.
```
conda env create -f environment.yml -n snakemakedada
```
### Download FastTreeMP
Regardless if you manually created your environment or cloned mine, you still have to download [FastTreeMP](http://www.microbesonline.org/fasttree/#Install), the link called "Multi-threaded executable (+SSE +OpenMP)" and put it in your bin folder or add it to your `$PATH`
### Entering the environment
Then, any time you start up poseidon (WHOI's HPC), you must use the following commands to enter the snakemake environment:
```
module load anaconda/5.1
source activate snakemakedada
```

## Step 1 Configure workflow
1. Edit the config.yaml to point to the path of your fastq files. They should all be in the same directory. Also edit the paths of your taxadb and speciesdb (end of the file) to point to the training sets you'll be using.
2. Edit the Snakefile glob_wildcards so that it matched your filenames. This can be the hardest part as you may need to experiment with regex to get it right. A typical Illumina MiSeq fastq file has the format "SAMPLENAME_S#_L001_R1.fastq.gz" for the forward read and "SAMPLENAME_S#_L001_R2.fastq.gz". If your files are formatted such, then the current header should already work for you. Otherwise, I would suggest you start python in the directory of your fastq files and mess with wildcards directly in python
```
python
from snakemake.io import *
##mess with wildcards here##
```
If regular expressions are difficult, I like using a regex checker such as https://regexr.com/ with a representative list of my filenames to see what I'm doing in real time.

## Step 2 Run plotQP to view your quality quality profiles and edit your filtering parameters
This step is run locally and will plot all the quality profiles of both the forward and reverse reads so that you can make an informed decision for your filter and trim parameters. It's also a good way to check that snakemake is finding your files correctly.
```
snakemake plotQP --cores 1
```
Once you've looked at your quality profiles, go to config.yaml and edit the parameters for filterAndTrim. The first number will be for the forward reads and the second number will be for the reverse reads.

## Step 3 Run the pipeline on the cluster
To run snakemake on the cluster, I used the following command:
```
snakemake -j 100 --cluster-config cluster.json --cluster "sbatch --mem={cluster.mem} -t {cluster.time} -n {cluster.ntasks} -J {cluster.job-name} -o {cluster.output}"
```
-j: specifies number of jobs (max) that snakemake will submit to the cluster
--cluster: calls slurm with sbatch and names all the parameters you would normally put in your bash header. These parameters can be edited and added to in the file `cluster.json`
