#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=2G

read -r -d '' HELP << EOM
#########################################################################
#																		#
#	Wrapper script for PHIX filtering									#
#																		#
#	usage: filter.sh -p <program> [options]								#
#																		#
#	-p <bowtie|bbduk|sortmerna>
#																		#
#	filter.sh Forward Reverse Ref Output I X [options] <SE reads> 		#
#	 																	#
#	SE reads should follow the following format:						#
#	-U SE1,SE2,etc. --un-gz Output -S /dev/null [options]  				#
#	 																	#
#########################################################################
EOM

function print_help {
	echo;echo "$HELP" >&1;echo;
	exit 0
}

if [ $# -eq 2 ];
then
   print_help
fi

OPTIND=1

while getopts ":hsp:" options; do
	case "$options" in
	s)
	  SCRIPT_DIR=$OPTARG
	  ;;
	p)
	  program=$OPTARG
	  break
	  ;;
	h)  
	  print_help
	  exit 0
	  ;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [[ -z "$SCRIPT_DIR" ]]; then 
	SCRIPT_DIR=$(readlink -f ${0%/*})
fi

case $program in

bowtie|Bowtie|bowtie2|Bowtie2)
	# note bowtie will use the same file name for all output files -
	# will need to write to seperate directories if submitting multiple pairs
	qsub -l h=blacklace11 $SCRIPT_DIR/sub_bowtie.sh $SCRIPT_DIR $@
	exit 0
;;
bbduk|BBDuk)
	qsub -l h=blacklace11 $SCRIPT_DIR/sub_bbduk.sh $SCRIPT_DIR $@
	exit 0
;;
bbmap|BBMap)
	qsub -l h=blacklace01,h=blacklace11 $SCRIPT_DIR/sub_bbmap.sh $SCRIPT_DIR $@
	exit 0
;;
sortmerna|SortMeRNA)
	qsub -l h=blacklace01,h=blacklace11 $SCRIPT_DIR/sub_sortmerna.sh $SCRIPT_DIR $@
	exit 0
;;
*)
	echo "Invalid assembly program: $program" >&2
	exit 1
esac
