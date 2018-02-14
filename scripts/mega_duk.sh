#!/bin/bash
#bbduk
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=4G
#$ -pe smp 12

SCRIPT_DIR=$1; shift
TRUSEQ=$1; shift
PHIXREF=$1; shift
RIBOKMERS=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=$1; shift
TRIML=( ktrim=l k=23 mink=11 hdist=1 tpe tbo t=10 )
TRIMR=( ktrim=r k=23 mink=11 hdist=1 tpe tbo t=10 )
PHIX=( k=31 hdist=1 t=10 )
RRNA=( k=31 t=10 )


# change to session temp folder
cd $TMP

F=$(sed 's/.*\///' <<<$FORWARD)
R=$(sed 's/.*\///' <<<$REVERSE)

# remove forward adapters
bbduk.sh in1=$FORWARD in2=$REVERSE out1=O1F out2=O1R ref=$TRUSEQ ${TRIML[@]}

# remove reverse adapters
bbduk.sh in1=O1F in2=O1R out1=O2F out2=O2R ref=$TRUSEQ ${TRIMR[@]}

# remove phix
bbduk.sh in1=O2F in2=O2R out1=O3F out2=O3R ref=$PHIXREF ${PHIX[@]}

# remove rRNA
bbduk.sh in1=O3F in2=O3R out1=$F.filtered.fq.gz out2=$R.filtered.fq.gz outm1=$F.rRNA.fq.gz outm2=$R.rRNA.fq.gz ref=$RIBOKMERS ${RRNA[@]} stats=$F.stats.txt


mkdir -p $OUTDIR/stats

cp *.fq.gz $OUTDIR/.
cp $F.stats.txt $OUTDIR/stats/.