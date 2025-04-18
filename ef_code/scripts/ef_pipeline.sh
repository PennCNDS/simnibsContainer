#!/bin/bash
#Input 
#bids_dir, sub, ses, rerun 

#Output 
#EF at the FS ROI values


#NEED BIDS Directory always
    #If no session or subect are specified then run all subect sessions
    #if subject is specified but not session than run all sessions for that subject
    #If session is specified but not subect run all subects for that particular session

PRINT_HELP() {
#LIST ALL THAT YOU WANT THE USER TO KNOW
  echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  echo 'Uses bash scripting to check if all files the T1w,T2w and if freesurfer is run and make sure it is 7.4.2

USAGE (depending on options):
  check_bids_dir [options]  

OPTIONS:
 -h, --help     Print this help.
 -b, --bids_dir Bids directory, can be the local or the full path to it
 -s, --sub      The subject name 
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
#LINK TO THE SCRIPT SO FIND DIRECTORY
script_dir="$( dirname "$tmp_link" )"
source $script_dir/bash_util.sh

args=$@

SHORT=hs:v:b:f:
LONG=bids_dir:,sub:,ses:,version,fs_lic:
options=$(getopt --options $SHORT --longoptions $LONG --name "$(basename 0)" -- "$@")
eval set -- "$options"

#DEFAULTS 
#######EDIT HERE##########################################


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
	--) 
		shift 
		break;;
	*)	
		echo "Unknown parameter $KEY! Exiting";exit 1;; 
        esac
done

if [[ -z $sub  ||  -z $ses  ||  -z $bids_dir ]];then
   if  [[ -z $bids_dir ]];then
	   error_echo "Bids Directory 'bids_dir' is not initialized"
           exit
   fi

   if  [[ -z $sub ]];then
	   warning_echo "Subject 'sub' is not initialized. All subjects in bids dir $bids_dir will be run"
   fi
   if  [[ -z $ses ]];then
	   warning_echo "Session 'ses' is not initialized. All sessions for the subjects specified will be run"
   fi
fi

if [[ ! $bids_dir = /* ]];then
	bids_dir=`pwd`/$bids_dir
fi
subj=$sub
session=$ses

for sub_dir in $bids_dir/rawdata/sub-$subj*;do
    for ses_dir in $sub_dir/ses-$session*;do
         sub=${sub_dir:${#bids_dir}+13}
         ses=${ses_dir:${#sub_dir}+5}
         #Check for bids directory 
	 qa_deriv=$bids_dir/derivatives/qa/sub-${sub}_ses-$ses
	 mkdir -p $qa_deriv
         # Check if subect has raw data T1 and T2
         
         #Check if freesurfer for subect is already in directory
         #If yes check the version of it 
          pretty_echo "Check the bids dir $bid_dir for sub-$sub ses-$ses" |& tee $qa_deriv/EF_pipeline.log
        
         check_bids_dir --bids_dir $bids_dir --sub $sub --ses $ses --fs_lic $fs_lic |& tee $qa_deriv/Bids_Dir_Checking_and_FreeSurfer.log
	   cat $qa_deriv/Bids_Dir_Checking_and_FreeSurfer.log >> $qa_deriv/EF_pipeline.log

           pretty_echo "FINISHED checking the bids dir $bid_dir for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log

        
         ################################
         #Flirt/AFNI of the template to the T1 and get the 12 parameter 
         
         #Charm of the init atlas of the rerun
         
         #Next create charm in the derivatives folder
         pretty_echo "Creating the headmodel for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log

         if [ ! -z $rerun ];then
	         create_headmodel --bids_dir $bids_dir --sub $sub --ses $ses --rerun  |& tee $qa_deriv/create_headmodel.log

         else
        	 create_headmodel --bids_dir $bids_dir --sub $sub --ses $ses |& tee $qa_deriv/create_headmodel.log

         fi
	   cat $qa_deriv/create_headmodel.log >> $qa_deriv/EF_pipeline.log

          pretty_echo "FINISHED creating the headmodel for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log


         ################################
         #Run simulations of the RUL and BT settings
           pretty_echo "Run ECT simulations for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log

       
          run_simulations --bids_dir $bids_dir --sub $sub --ses $ses |& tee $qa_deriv/EF_simulations.log
           cat $qa_deriv/EF_simulations.log >> $qa_deriv/EF_pipeline.log
           pretty_echo "FINISHED running ECT simulations for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log


         ################################
         #Register the freesurfer regions to the efield T1 
         
         #Gather the Efield values in aparc aseg
         
         #Collapse subect values into group values
          pretty_echo "Gather Efield Values for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log

      
         gather_ef_over_simulation --bids_dir $bids_dir --sub $sub --ses $ses |& tee $qa_deriv/Gather_EF_Output.log
	 
           cat $qa_deriv/Gather_EF_Output.log >> $qa_deriv/EF_pipeline.log

          pretty_echo "FINISHED gathering Efield Values for sub-$sub ses-$ses" |& tee -a $qa_deriv/EF_pipeline.log


    done
done
