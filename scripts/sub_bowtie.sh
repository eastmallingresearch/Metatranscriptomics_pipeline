#!/bin/bash
#Assemble contigs using Bowtie
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=2G
#$ -pe smp 4


# get command line variables
SCRIPT_DIR=$1; shift
REF=$1; shift
OUTDIR=$1; shift
FORWARD=$1; shift
REVERSE=${1:-NOTHING}; shift

# change to session temp folder
cd $TMP

# create a random variable for naming output files
TEMPF=FILTERED_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n1)

# search for PHiX matches in the forward read and save none matching reads to $TEMPF.fq
bowtie2 -p 4 --no-unal -x $REF -q -U $FORWARD -S /dev/null --un $TEMPF.fq


if [ $REVERSE == "NOTHING" ]; then 
	# If single-end reads copy unmatched reads to output directory and exit
	F=$(echo $FORWARD|awk -F"/" '{print $NF}')
	mv $TEMPF.fq ${F}.f.filtered.fq
	cp ${F}.f.filtered.fq $OUTDIR/.
else
	
	# random variable for reverse reads	
	TEMPR=FILTERED_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n1)

	# search for PHiX matches in the reverse read and save none matching reads to $TEMPR.fq
	bowtie2 -p 4 --no-unal -x $REF -q -U $REVERSE -S /dev/null --un $TEMPR.fq 

	# the clever bit (finds reads which have no phix in either forward or reverse)
	grep -h "^@" $TEMPF.fq $TEMPR.fq| \
	sed -e "s/ 2:/ 1:/"| \
	sed -e 's/^@//'| \
	sort|uniq -d > $TEMPF.fq.l2

	# get the forward and reverse file filenames (excluding the path)
	F=$(echo $FORWARD|awk -F"/" '{print $NF}')
	R=$(echo $REVERSE|awk -F"/" '{print $NF}')

	# finds forward reads which don't contain phix in either forward or reverse read, writes them to a file and copies to the output directory
	cat $TEMPF.fq.l2|$SCRIPT_DIR/slowx_getseqs.pl $TEMPF.fq > ${F}.f.filtered.fq
	cp ${F}.f.filtered.fq $OUTDIR/.
	
	# this line is superfluous (files will be deleted automatically on exit - if jobs submitted to gridengine)
	rm $TEMPF.fq ${F}.f.filtered.fq

	# changes read names to match reverse name syntax in the list of unique phix-free reads
	sed -i -e 's/ 1:/ 2:/' $TEMPF.fq.l2
	
	# finds reverse reads which don't contain phix in either forward or reverse read, writes them to a file and copies to the output directory
	cat $TEMPF.fq.l2|$SCRIPT_DIR/slowx_getseqs.pl $TEMPR.fq > ${R}.r.filtered.fq
	cp ${R}.r.filtered.fq $OUTDIR/.

fi