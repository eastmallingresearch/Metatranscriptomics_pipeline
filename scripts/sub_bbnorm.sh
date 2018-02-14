#!/bin/bash
#bbduk
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=4G
#$ -pe smp 14

SCRIPT_DIR=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=${1:-NOTHING}; shift

# change to session temp folder
cd $TMP

F=$(sed 's/.*\///' <<<$FORWARD)
R=$(sed 's/.*\///' <<<$REVERSE)

bbnorm.sh \
 in1=$FORWARD \
 in2=$REVERSE \
 out1=$F.corrected.fq.gz \
 out2=$R.corrected.fq.gz \
 $@

cp *.corrected.fq.gz $OUTDIR/.

