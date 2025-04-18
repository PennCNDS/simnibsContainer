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
sub_ses_simnibs=$bids_dir/derivatives/Simnibs4.1/sub-${sub}_ses-${ses}
ef_out_dir=$bids_dir/derivatives/Efield_Output/sub-${sub}_ses-${ses}
fs_ef_file=$ef_out_dir/fs_ef.csv
ef_summ_file=$ef_out_dir/ef_summary.csv
mkdir -p $ef_out_dir



export SUBJECTS_DIR=$bids_dir/derivatives/freesurfer
if [ -d $sub_ses_fs_dir/mri ];then
cd $sub_ses_fs_dir/mri
fs_mask=aparc.a2009s+aseg.nii.gz
subj_fs_mask=$sub_ses_fs_dir/mri/$fs_mask
if [ ! -f $subj_fs_mask ];then
mri_label2vol --seg $sub_ses_fs_dir/mri/${fs_mask::-7}.mgz --temp $sub_ses_fs_dir/mri/rawavg.mgz --o $sub_ses_fs_dir/mri/$fs_mask --regheader $sub_ses_fs_dir/mri/${fs_mask::-7}.mgz
fi
echo "Subject,Session,Simulation,Current(A),FS_Key,FS_Value(V/m)" > $fs_ef_file
fi

cd -


echo "Subject,Session,Simulation,Current(A),Ebrain/I(V/(m*mA))" > $ef_summ_file

for sim_dir in $sub_ses_simnibs/simnibs_sim_*;do
    magnE_file=$sim_dir/subject_volumes/${sub}_TDCS_1_scalar_magnE.nii.gz
    Simulation=${sim_dir:${#sub_ses_simnibs}+13}

    Current=($(awk -F ":" '/Currents/{print $5}' $sim_dir/*.log |cut -d, -f2))
    Current=${Current::-1}

    if [ -f $subj_fs_mask ]; then
    3dROIstats -quiet -nomeanout -key -nzmean -mask $subj_fs_mask $magnE_file > tmp
    1dtranspose tmp'[0..$(2)]' > val_tmp
    1dtranspose tmp'[1..$(2)]' > keys_tmp
    paste keys_tmp val_tmp > subj_fs_ef
    awk '{OFS=",";print "'sub-${sub}'","'ses-${ses}'","'$Simulation'","'$Current'",$1,$2}' subj_fs_ef >> $fs_ef_file
    rm tmp val_tmp keys_tmp subj_fs_ef
    fi

    mask_file=$sub_ses_simnibs/m2m_$sub/final_tissues.nii.gz
    ebrain=($(3dBrickStat -mask $mask_file -mrange 1 2 -percentile 90 1 90 -non-zero $magnE_file))
    #w_e_file=$efield_dir/w${subj}_TDCS_1_scalar_normE_brain_MNI.nii.gz
    #e_motor=($(3dBrickStat -mask $r_mni_motor_mask -percentile 95 1 95 -non-zero $w_e_file))
    #e_hippo=($(3dBrickStat -mask $r_mni_hippo_mask -percentile 95 1 95 -non-zero $w_e_file))
    #e_thal=($(3dBrickStat -mask $r_mni_thal_mask -percentile 95 1 95 -non-zero $w_e_file))
    #awk 'BEGIN{OFS=",";print "'sub-${sub}'","'ses-${ses}'","'$Simulation'","'$Current'",'${ebrain[1]}'/(1000*'$Current')}' >> $ef_summ_file
#    awk 'BEGIN{OFS=",";print "'sub-${sub}'","'ses-${ses}'","'$Simulation'","'$Current'",'${ebrain[1]}'}' >> $ef_summ_file
    awk 'BEGIN{OFS=",";print "sub-'${sub}'","'ses-${ses}'","'$Simulation'","'$Current'",'${ebrain[1]}'/(1000*'$Current')}' >> $ef_summ_file


    #echo ${subj},${ebrain[1]},${e_motor[1]},${e_hippo[1]},${e_thal[1]} >> ../results/efield_vals_$(date +%F).csv

done



    

