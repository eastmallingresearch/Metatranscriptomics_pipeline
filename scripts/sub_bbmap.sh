#!/bin/bash
#bbduk
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=4G
#$ -pe smp 8

SCRIPT_DIR=$1; shift
REF=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=${1:-NOTHING}; shift

# change to session temp folder
cd $TMP

F=$(sed 's/.*\///' <<<$FORWARD)
R=$(sed 's/.*\///' <<<$REVERSE)

bbmap.sh \
 in1=$FORWARD \
 in2=$REVERSE \
 outu1=$F.cleaned.fq.gz \
 outu2=$R.cleaned.fq.gz \
 outm1=$F.unclean.fq.gz \
 outm2=$R.uncleaned.fq.gz \
 path=$REF/ \
 $@

mkdir -p $OUTDIR/unclean

cp *.cleaned.fq.gz $OUTDIR/.
cp *.unclean.fq.gz $OUTDIR/unclean/.
