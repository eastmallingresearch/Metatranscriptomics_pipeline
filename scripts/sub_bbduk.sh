#!/bin/bash
#bbduk
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=2G
#$ -pe smp 4

SCRIPT_DIR=$1; shift
REF=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=${1:-NOTHING}; shift

# change to session temp folder
cd $TMP

F=$(sed 's/.*\///' <<<$FORWARD)
R=$(sed 's/.*\///' <<<$REVERSE)

bbduk.sh \
 in1=$FORWARD \
 in2=$REVERSE \
 out1=$F.filtered.fq.gz \
 out2=$R.filtered.fq.gz \
 ref=$REF \
 stats=$F.stats.txt \
 $@

mkdir -p $OUTDIR/stats

cp *.fq.gz $OUTDIR/.
cp $F.stats.txt $OUTDIR/stats/.