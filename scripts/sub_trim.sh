#!/bin/bash
#$ -S /bin/bash
#$ -pe smp 4
#$ -cwd
#$ -l virtual_free=1G

SCRIPT_DIR=$1
shift
FORWARD=$1
shift
REVERSE=$1
shift
OUTDIR=$1
shift
ADAPTERS=$1
shift
THREADS=${1:-4}
shift

mkdir -p $OUTDIR

FO=$( echo $FORWARD|awk -F"/" '{print $NF}' )
RO=$( echo $REVERSE|awk -F"/" '{print $NF}' )

cd $TMP

java -jar $SCRIPT_DIR/trimmomatic-0.33.jar PE -threads $THREADS -phred33 $FORWARD $REVERSE $FO.trimmed.fq.gz /dev/null $RO.trimmed.fq.gz /dev/null ILLUMINACLIP:$ADAPTERS:2:20:7 $@

cp *.trimmed.fq.gz $OUTDIR/.