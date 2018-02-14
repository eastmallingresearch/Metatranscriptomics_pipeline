#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=2G

read -r -d '' HELP << EOM
#################################################################################
#																				#
#	Wrapper script for removing truseq adapters/quality trimming				#
#																				#
#	usage: trim.sh -p <trimprog> [options]										#
#																				#
#	-p <trimmomatic|bbduk>                                                      #																				#
#	trim.sh Forward Reverse Output_dir adapter_file [other options]				#	
#																				#	
#	options : -threads <num_threads>											#
#																				#
#################################################################################
EOM

function print_help {
	echo;echo "$HELP" >&1;echo;
	
	java -jar trimmomatic-0.33.jar;
	exit 1
}

if [ $# -eq 0 ];
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
	  exit 1
	  ;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [[ -z "$SCRIPT_DIR" ]]; then 
	SCRIPT_DIR=$(readlink -f ${0%/*})
fi

case $program in

trimmomatic)
	qsub -l h=!blacklace11 $SCRIPT_DIR/sub_trim.sh $SCRIPT_DIR $@
	exit 0
;;
bbduk|BBDuk)
	qsub -l h=blacklace11 $SCRIPT_DIR/sub_bbduk.sh $SCRIPT_DIR $@
	exit 0
;;
*)
	echo "Invalid assembly program: $program" >&2
	exit 1
esac