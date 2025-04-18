#!/bin/bash
# $Id: create_headmodel 1.0 03-06-2025  jupston $

PRINT_USAGE() {
#WHAT IS THE USAGE OF THE PROGRAM
echo 'USAGES:Creates a simnibs4.1 headmodel from charm' 
}

PRINT_HELP() {
#LIST ALL THAT YOU WANT THE USER TO KNOW
  echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  echo 'Uses SIMNIBS4.1 to create headmodel. Due to the possible misregistrations a flirt is run during it, in case needs to be rerun.

USAGE (depending on options):
  create_heamodel [options]  

OPTIONS:
 -h, --help     Print this help.
 -b, --bids_dir Bids directory, can be the local or the full path to it
 -s, --sub     The subject name 
 -v, --ses      The session(visit) number
 --rerun        Reruns the headmodel charm using the Flirt registration or the registration matrix set in the corresponding subject folder
 



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



SHORT=hs:v:b:
LONG=bids_dir:,sub:,ses:,version,rerun
options=$(getopt --options $SHORT --longoptions $LONG --name "$(basename 0)" -- "$@")
eval set -- "$options"

#DEFAULTS 
#######EDIT HERE##########################################

fs_ver=7.4.2
rerun="N"

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
        --rerun)
                rerun="Y"
                shift ;;
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

#Initialize_Folders
sub_ses_fs_dir=$bids_dir/derivatives/freesurfer/sub-${sub}_ses-${ses}
anat_dir=$bids_dir/rawdata/sub-${sub}/ses-${ses}/anat
T1=$anat_dir/sub-${sub}_ses-${ses}_T1w.nii.gz
T2=$anat_dir/sub-${sub}_ses-${ses}_T2w.nii.gz
sub_ses_simnibs=$bids_dir/derivatives/Simnibs4.1/sub-${sub}_ses-${ses}
anat_deriv=$bids_dir/derivatives/anat/sub-${sub}_ses-${ses}/AFNI_MNI_Warp
qa_deriv=$bids_dir/derivatives/qa/sub-${sub}_ses-${ses}

mkdir -p $anat_deriv
mkdir -p $sub_ses_simnibs
mkdir -p $qa_deriv
if [[ -z "$SIMNIBS_BIN" ]];then

SIMNIBS_BIN=`which charm`
SIMNIBS_BIN="$( dirname "$SIMNIBS_BIN" )"
fi
#Find the afni registration 
#If the transform is there dont rerun 
if [ ! -f $anat_deriv/MNI2Conform12.txt ];then
   MNI_template=$SIMNIBS_BIN/../lib/python3.9/site-packages/simnibs/resources/templates/MNI152_T1_1mm.nii.gz
   cd $anat_deriv
   cp $T1 ./sub-${sub}_ses-${ses}_T1w.nii.gz
   3dWarp -deoblique -prefix sub-${sub}_ses-${ses}_T1w_deobq.nii.gz sub-${sub}_ses-${ses}_T1w.nii.gz
   3dAllineate -base $MNI_template -input sub-${sub}_ses-${ses}_T1w_deobq.nii.gz -1Dmatrix_save 12param
   echo "-1 0 0 0 0 -1 0 0 0 0 1 0" > AFNI_to_SPM.txt
   cat_matvec -ONELINE AFNI_to_SPM.txt 12param.aff12.1D AFNI_to_SPM.txt -4x4 > MNI2Conform12.txt
   charm AFNI_rerun $T1 --initatlas --forceqform --usetransform MNI2Conform12.txt 
   cp m2m_AFNI_rerun/charm_report.html $qa_deriv/AFNI_rerun_registration_check.html    
   cd -
fi

#Start the charm 
cd $sub_ses_simnibs
if [ $rerun == "Y" ]; then
  rm -r simnibs_sim_*
 if [ ! -f MNI2Conform12.txt ];then
    warning_echo "MNI2Conform12.txt not found in $sub_ses_simnibs. Using AFNI $anat_deriv/MNI2Conform12.txt"
    cp $anat_deriv/MNI2Conform12.txt MNI2Conform12.txt
 fi
  
 charm $sub $T1 $T2 --fs-dir $sub_ses_fs_dir --forceqform --usetransform MNI2Conform12.txt --forcerun
 cp m2m_$sub/charm_report.html $qa_deriv/charm_report.html

else 
    charm $sub $T1 $T2 --fs-dir $sub_ses_fs_dir --forceqform
    cp m2m_$sub/charm_report.html $qa_deriv/charm_report.html

fi


