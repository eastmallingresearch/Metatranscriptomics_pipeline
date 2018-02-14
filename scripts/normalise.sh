#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l virtual_free=1G

read -r -d '' HELP << EOM
#########################################################################
#																		#
#	Wrapper script for normalising data									#
#																		#
#	usage: filter.sh -p <program> [options]								#
#																		#
#	-p <bbnorm>															#
#																		#
#	normalise.sh Forward Reverse Output 						 		#
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

bbnorm|BBNorm)
	qsub $SCRIPT_DIR/sub_bbnorm.sh $SCRIPT_DIR $@
	exit 0
;;
*)
	echo "Invalid assembly program: $program" >&2
	exit 1
esac
