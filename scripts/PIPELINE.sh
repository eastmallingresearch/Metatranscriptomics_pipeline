#!/bin/bash
#$ -S /bin/bash
#$ -cwd

SCRIPT_DIR=$(readlink -f ${0%/*})

#==========================================================
#	Set Help (add message between EOM blocks
#==========================================================	
read -r -d '' HELP << EOM
#############################################################
#                                                           #
#	Metagenomics pipeline	for Illumina data               #
#                                                           #
#	usage: PIPELINE.sh -c <program> [options]               #
#                                                           #
#############################################################

 -c <program>	Program can be any of the defined programs
 -h		display this help and exit	
EOM


function print_help {
	echo;echo "$HELP" >&1;echo;
	exit 1
}

if [ $# -eq 0 ];
then
   print_help
fi

#==========================================================
#	Set command line switch options
#==========================================================

OPTIND=1 

while getopts ":hs:c:" options; do
	case "$options" in
	s)
	    SCRIPT_DIR=$OPTARG
	    ;;
	c)  
 	    program=$OPTARG
	    break
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
      	    ;;
	h)  
	    print_help
	    exit 0
 	    ;;
	?) 
	    echo "Invalid option: -$OPTARG" >&2
	    echo "Call PIPELINE with -h switch to display usage instructions"
	    exit 1
	    ;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#==========================================================
#	Set (-c) programs
#==========================================================

case $program in

wibble)	
	echo $SCRIPT_DIR 
	echo "Wibbling..."
	exit 1
;;
split|splitfq|splitfq.sh)
	$SCRIPT_DIR/splitfq.sh $@
	exit 0
;;
trim|trim.sh)
	$SCRIPT_DIR/trim.sh $@
	exit 0
;;
clean|clean.sh)
	$SCRIPT_DIR/clean.sh $SCRIPT_DIR $@
	exit 0
;;
filter|filter.sh)
	$SCRIPT_DIR/filter.sh $@
	exit 0
;;
concat|concatonate|cat|concat.sh)
	qsub $SCRIPT_DIR/submit_concat.sh $@
	exit 0
;;
normalise|normalise.sh)
	$SCRIPT_DIR/normalise.sh $@
	exit 0
;;
align|align.sh|star)
	$SCRIPT_DIR/star.sh $@
	exit 0
;;
dereplicate|dereplicate.sh)
	$SCRIPT_DIR/dereplicate.sh $@
	exit 0
;;
correct)
	qsub $SCRIPT_DIR/submit_correct.sh $SCRIPT_DIR $@
	exit 0
;;
interleave|inter)
	qsub $SCRIPT_DIR/submit_interleave.sh $@
	exit 0
;;
assemble|assemble.sh)
	$SCRIPT_DIR/assemble.sh $@
	exit 0
;;
post|post.sh)
	qsub $SCRIPT_DIR/submit_post.sh $SCRIPT_DIR $@
	exit 0
;;
merge|merge.sh)
	$SCRIPT_DIR/merge.sh $@
	exit 0
;;

megafilt|MEGAFILT)
    qsub -l h=balcklace01,h=blacklace11 $SCRIPT_DIR/mega_duk.sh $SCRIPT_DIR $@
   #$SCRIPT_DIR/mega_duk.sh $SCRIPT_DIR $@
	exit 0
;;

assembly|assembly.sh)
	echo $SCRIPT_DIR/assembly.sh $@
	exit 0
;;
TEST)
	echo "test program run with options:" $@
	exit 0
;;

*)
	echo "Invalid program: $program" >&2
	exit 1
esac
