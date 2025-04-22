#!/bin/bash
# $Id: check_bids_dir 1.0 03-06-2025  jupston $

PRINT_USAGE() {
#WHAT IS THE USAGE OF THE PROGRAM
echo 'USAGES:Checks the bids dir else it errors out'
}

PRINT_HELP() {
#LIST ALL THAT YOU WANT THE USER TO KNOW
  echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  echo 'Uses bash scripting to check if all files the T1w,T2w and if freesurfer is run and make sure it is 7.4.2

USAGE (depending on options):
  check_bids_dir [options]

OPTIONS:
 -h, --help     Print this help.
 -b, --bids_dir Bids directory, can be the local or the full path to it
 -s, --sub     The subject name
 -v, --ses      The session(visit) number
 -f, --fs_lic   The freesurfer license file



DESCRIPTION:

KNOWN ISSUES:

AUTHORS:
	Joel Upston'
echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}
SOURCE="$0"
tmp_link="$( readlink "$SOURCE" )"
SOURCE="$( dirname "$SOURCE" )"
if [[ ! $tmp_link = /* ]];then
	tmp_link=$SOURCE/$tmp_link
fi

#source j_bash_util
#LINK TO THE SCRIPT SO FIND DIRECTORY
script_dir="$( dirname "$tmp_link" )"

args=$@

#if [[ -z "${OPTIONS[@:1]}" ]];then
#	PRINT_USAGE;exit
#fi

nthreads=1

SHORT=hs:v:b:f:t:
LONG=bids_dir:,sub:,ses:,version,fs_lic:,threads:
options=$(getopt --options $SHORT --longoptions $LONG --name "$(basename 0)" -- "$@")
eval set -- "$options"

#DEFAULTS
#######EDIT HERE##########################################

fs_ver=8.0

while true ; do
    case "$1" in
	-h | --help)
		PRINT_HELP; exit;;
	--version)
		echo "$Id";exit;;
	######EDIT HERE
	--bids_dir)
		bids_dir="$2"
		shift 2;;
	-s | --sub)
                sub="$2"
                shift 2;;
        -v | --ses)
                ses=$2
		shift 2;;
        -f | --fs_lic)
		fs_lic=$2
		shift 2;;
    -t | --threads)
        nthreads=$2
        shift 2;;
	--)
		shift
		break;;
	*)
		echo "Unknown parameter $KEY! Exiting";exit 1;;
        esac
done

if [[ -z $sub  ||  -z $ses  ||  -z $bids_dir ]];then
   if  [[ -z $sub ]];then
	   echo Subject "sub" is not initialized
   fi
   if  [[ -z $ses ]];then
	   echo Session "ses" is not initialized
   fi
   if  [[ -z $bids_dir ]];then
	   echo Bids Directory "bids_dir" is not initialized
   fi

   exit
fi

if [[ ! $bids_dir = /* ]];then
	bids_dir=`pwd`/$bids_dir
fi


#Check for T1 and T2
anat_dir=$bids_dir/rawdata/sub-${sub}/ses-${ses}/anat
if [ -f $anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz ];then
	echo T1 is found. Using $anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz
else
	echo "T1 was not found, looking under name $anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz"
	exit
fi
if [ -f $anat_dir/sub-${sub}_ses-${ses}_T2w.nii.gz ];then
	echo T2 is found. Using $anat_dir/sub-${sub}_ses-${ses}_T2w.nii.gz
else
	echo "T2 was not found, looking under name $anat_dir/sub-${sub}_ses-${ses}_T2w.nii.gz"
	exit
fi

#Check for Freesurfer
#Copy license file
if [ ! -f $FREESURFER_HOME/license.txt ];then
	cp $fs_lic $FREESURFER_HOME/license.txt
fi
 #Check for version


fs_dir=$bids_dir/derivatives/freesurfer
vz_file=$fs_dir/sub-${sub}_ses-${ses}/scripts/build-stamp.txt
vz=($(cat $vz_file))
#Run freesurfer if needed
mkdir -p $fs_dir
export SUBJECTS_DIR=$fs_dir
if echo "$vz" | grep -q "$fs_ver"; then
  echo "Freesurfer built on $fs_ver, found for sub-${sub}_ses-${ses}"
  #Make sure it has the final aparc+aseg
  if [ ! -f $fs_dir/sub-${sub}_ses-${ses}/mri/aparc+aseg.mgz ];then
   echo "Freesurfer didnt seem to finish so rerunning"
   rm -r $fs_dir/sub-${sub}_ses-${ses}
   recon-all -s sub-${sub}_ses-${ses} -sd $fs_dir -i $anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz \
       -i $anat_dir/sub-${sub}_ses-${ses}_T2w.nii.gz -all -threads $nthreads
  fi

else
  echo "Not found freesurfer $fs_ver run for sub-${sub}_ses-${ses} "
  echo "Therefore running a new run of freesurfer"
  recon-all -s sub-${sub}_ses-${ses} -sd $fs_dir -i $anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz -all -threads $nthreads
fi
