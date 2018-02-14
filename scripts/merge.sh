#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=1G

read -r -d '' HELP << EOM
#########################################################################
#																		#
#	Wrapper script for merging PE										#
#																		#
#	usage: merge.sh -p <program> [options]								#
#																		#
#	-p <bbmerge|bbmergeauto>										    #
#																		#
#	merge.sh Forward Reverse Outdir		 						 		#
#	 																	#
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

bbmerge-auto|BBmerge-auto)
	qsub -l h=blacklace11 $SCRIPT_DIR/sub_bbmerge_auto.sh $SCRIPT_DIR $@
	exit 0
;;
*)
	echo "Invalid merge program: $program" >&2
	exit 1
esac
