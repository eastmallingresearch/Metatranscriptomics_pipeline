# Metatranscriptomics_pipeline

The preprocessing steps are similar to shotgun-metagenomics, with the addition of rRNA depletion...

Slight change of plan, I'm going to implement a combined metatranscriptomic (MT) and metagenomic (MG) pipeline as per:
https://genomebiology.biomedcentral.com/articles/10.1186/s13059-016-1116-8#MOESM1

they've produced a docker image containing the pipeline:
http://r3lab.uni.lu/web/imp/

I'm not going to use docker (not certain our verion of Linux is up to running it correctly), but will follow their pipeline.  
Fortunantly it is almost identical to what I've already done, with the exception of making a de-novo MT transcriptome first and using this to scaffold the MG assembly (though I do have slight reservations about doing the assembly this way). 

Details at the bottom of this and the MG pipeline  

## Preprocessing
The workflow should include at the least adapter trimming and filtering for phix/contamination. Normalisation, error correction and merging are dependent on the data and/or the assebley pipeline. Trimmomatic can also trim for quality if the data is of poor quality.

The bbtools preprocessing pipeline has a number of good options for many of these tasks.

```shell
# add project folders
PROJECT_FOLDER=~/projects/myproject
ln -s ~/pipelines/metatranscriptomics $PROJECT_FOLDER/metatranscriptomics_pipeline

mkdir $PROJECT_FOLDER/data
mkdir $PROJECT_FOLDER/data/cluster
mkdir $PROJECT_FOLDER/data/fastq
mkdir $PROJECT_FOLDER/data/trimmed
mkdir $PROJECT_FOLDER/data/filtered
mkdir $PROJECT_FOLDER/data/normalised
mkdir $PROJECT_FOLDER/data/cleaned
mkdir $PROJECT_FOLDER/data/corrected
mkdir $PROJECT_FOLDER/data/merged
```

### Adapter removal/quality filtering and contaminant filtering
BBTools has good options for going all of this
Adapter removal, removal of phix and rrna could be merged using the PIPELINE, but the below is more adaptable (BBDuk)
Then, removal of human (or anything else) in a second step (BBMap)

#### Adapter removal/phix/rRNA removal
Runs all three of the options in "Filtering full options" shown at bottom
```shell
for FR in $PROJECT_FOLDER/data/trimmed/*_1.fq.gz.trimmed.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c MEGAFILT \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/adapters/truseq.fa \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/contaminants/phix.fa \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/contaminants/ribokmers.fa.gz \
  $PROJECT_FOLDER/data/filtered \
  $FR \
  $RR \
  TRIML="ktrim=l k=23 mink=11 hdist=1 tpe tbo t=4" \
  TRIMR="ktrim=l k=23 mink=11 hdist=1 tpe tbo t=4" \
  PHIX="k=31 hdist=1 t=4"
  RRNA="k=31 t=4"
done  
```

#### Human contaminant removal (BBMap)
```shell
for FR in $PROJECT_FOLDER/data/filtered/*_1.fq.gz.trimmed.fq.gz.filtered.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c filter -p bbmap \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/contaminants/bbmap_human \
  $PROJECT_FOLDER/data/cleaned \
  $FR \
  $RR \
  minid=0.95 \
  maxindel=3 \
  bwr=0.16 \
  bw=12 \
  quickmatch \
  fast \
  minhits=2 \
  t=8
done
```
#### Normalization and error correction (BBNorm)
```shell
for FR in $PROJECT_FOLDER/data/cleaned/*_1.fq.gz.trimmed.fq.gz.filtered.fq.gz.cleaned.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c normalise -p bbnorm \
  $PROJECT_FOLDER/data/corrected \
  $FR \
  $RR  \
  target=100 \
  min=5 \
  ecc=t \
  passes=1 \
  bits=16 prefilter
done
```
#### Paired read merge (BBMerge)
```shell
for FR in $PROJECT_FOLDER/data/corrected/*_1.fq.gz.trimmed.fq.gz.filtered.fq.gz.cleaned.fq.gz.corrected.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c merge -p bbmerge-auto \
  $PROJECT_FOLDER/data/merged \
  $FR \
  $RR  \
  rem k=62 \
  extend2=50 \
  t=12 \
  vstrict
done
```

## Assembly
There are less assemblers dedicated to MT than MG data - megahit can be used with a small tweek to prevent bubble merger

#### metaspades
Metaspades can only run on paired reads (no option to use single and/or merged pairs, or multiple libraries)
```shell
for FR in $PROJECT_FOLDER/data/corrected/*_1.fq.gz.trimmed.fq.gz.filtered.fq.gz.cleaned.fq.gz.corrected.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  PREFIX=$(grep -Po 'N[0-9]+.' <<<$FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c assemble -p metaspades \
  $PROJECT_FOLDER/data/assembled \
  $FR \
  $RR  \
  $PREFIX \
  -k 21,33,55,77
done
```

#### megahit

Several options are recommended for soil samples  
--k-min=27 (or higher)  
--kmin-1pass  
--k-min 27 --k-step 10 --k-max 87 (127)  
--bubble-level 0 # metatranscriptomic setting

```shell
# using pre-merged reads
for FR in $PROJECT_FOLDER/data/merged/*_1.unmerged.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  MR=$(sed 's/_1\.un/\./' <<< $FR)
  PREFIX=$(grep -Po 'N[0-9]+.' <<<$FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c assemble -p megahit \
  $PROJECT_FOLDER/data/assembled \
  $PREFIX \
  -r $MR,$FR,$RR\
  -k-min=27 --k-step 10 --k-max 127
  --bubble-level 0
done
```

```shell
# using unmerged reads
for FR in $PROJECT_FOLDER/data/corrected/*_1.fq.gz.trimmed.fq.gz.filtered.fq.gz.cleaned.fq.gz.corrected.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  MR=$(sed 's/_1\.un/\./' <<< $FR)
  PREFIX=$(grep -Po 'N[0-9]+.' <<<$FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c assemble -p megahit \
  $PROJECT_FOLDER/data/assembled \
  $PREFIX \
 -1 $FR -2 $RR -r $MR \
 -k-min=27 --k-step 10 --k-max 127
 --bubble-level 0
done
```   

## Taxonomy assignment
Metakallisto/kracken/centrifuge?

### Binning
#### metakallisto


## 


### Filtering full options
Remove 3' adapters
```shell
for FR in $PROJECT_FOLDER/data/trimmed/*_1.fq.gz.trimmed.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c filter -p bbduk \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/adapters/truseq.fa \
  $PROJECT_FOLDER/data/filtered \
  $FR \
  $RR \
  ktrim=r \
  k=23 \
  mink=11 \
  hdist=1 \
  tpe \
  tbo \
  t=4
done
```
Remove 5' adapters
```shell
for FR in $PROJECT_FOLDER/data/trimmed/*_1.fq.gz.trimmed.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c filter -p bbduk \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/adapters/truseq.fa \
  $PROJECT_FOLDER/data/filtered \
  $FR \
  $RR \
  ktrim=l \
  k=23 \
  mink=11 \
  hdist=1 \
  tpe \
  tbo \
  t=4
done
```

phix removal
```shell
cd $PROJECT_FOLDER/data/filtered
rename 

for FR in $PROJECT_FOLDER/data/trimmed/*_1.fq.gz.trimmed.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c filter -p bbduk \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/contaminants/phix.fa \
  $PROJECT_FOLDER/data/filtered \
  $FR \
  $RR \
  k=31 \
  hdist=1 \
  t=4
done
```

rRNA removal 
The author of BBTools has produced a kmer file from the full silva database (https://drive.google.com/file/d/0B3llHR93L14wS2NqRXpXakhFaEk/view)
I've tested this against SortMeRNA performance; 500,000 interleaved (uncompressed) PE fastq file

SortMeRNA runtime 7 - 9 minutes 32.79% rRNA
BBDUK runtime 7 - 9 *seconds* 31.42% rRNA
```shell
for FR in $PROJECT_FOLDER/data/trimmed/*_1.fq.gz.trimmed.fq.gz; do
  RR=$(sed 's/_1/_2/' <<< $FR)
  $PROJECT_FOLDER/metatranscriptomics_pipeline/scripts/PIPELINE.sh -c filter -p bbduk \
  $PROJECT_FOLDER/metatranscriptomics_pipeline/common/resources/contaminants/ribokmers.fa.gz \
  $PROJECT_FOLDER/data/filtered \
  $FR \
  $RR \
  k=31 \
  t=4
done
```
