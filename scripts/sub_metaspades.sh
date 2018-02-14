#!/bin/bash
# spades
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=4G
#$ -pe smp 12

OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=$1; shift
PREFIX=$1;shift

# change to session temp folder
cd $TMP

metaspades.py \
 --meta \
 --only-assembler \
 -o $TMP \
 -1 $FORWARD \
 -2 $REVERSE \
 -t 12 \
 $@ 

mkdir -p $OUTDIR/$PREFIX

pigz -9 -p 12 -r *

cp * -r  $OUTDIR/$PREFIX/