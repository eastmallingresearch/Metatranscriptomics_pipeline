#!/bin/bash
#bbduk
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=4G
#$ -pe smp 12

SCRIPT_DIR=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=$1; shift

# change to session temp folder
cd $TMP

F=$(sed 's/.*\///' <<<$FORWARD)
R=$(sed 's/.*\///' <<<$REVERSE)

bbmerge-auto.sh \
 in1=$FORWARD \
 in2=$REVERSE \
 out=$F.merged.fq.gz \
 outu1=$F.unmerged.fq.gz \
 outu2=$R.unmerged.fq.gz \
 $@

cp *.fq.gz $OUTDIR/.

