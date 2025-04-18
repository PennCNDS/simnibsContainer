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
simulation_simnibs(){
#simulation setting file
sub=$1
m2m_folder=$2
outfolder=$3
elec1=$4
elec2=$5
echo "from simnibs import sim_struct, run_simnibs

''' General Settings '''
# Initalize a session
s = sim_struct.SESSION()
s.map_to_MNI=True
s.map_to_fsavg=True
s.map_to_vol=True
s.open_in_gmsh=False
s.subpath='$m2m_folder'
s.tissues_in_niftis=[1,2]
# Name of head mesh
s.fnamehead = '$m2m_folder/$sub.msh'
# Output folder
s.pathfem = '$outfolder'

''' ECT Simulation '''
tdcslist = s.add_tdcslist()
# Set currents
tdcslist.currents = [-0.8, 0.8]

''' Define cathode '''
# Initialize the cathode
cathode = tdcslist.add_electrode()
# Connect electrode to first channel (-1 mA, cathode)
cathode.channelnr = 1
# Electrode dimension
cathode.dimensions = [50, 50]
# Rectangular shape
cathode.shape = 'ellipse'
# 5mm thickness
cathode.thickness = 5
# Electrode Position
cathode.centre = '$elec1'
# Electrode direction,Doesnt matter for ellipse
#cathode.pos_ydir = 'Cz'

''' Define anode '''
# Add another electrode
anode = tdcslist.add_electrode()
# Assign it to the second channel
anode.channelnr = 2
# Electrode diameter
anode.dimensions = [50, 50]
# Electrode shape
anode.shape = 'ellipse'
# 5mm thickness
anode.thickness = 5
# Electrode position
anode.centre = '$elec2'

''' Run Simulations '''
run_simnibs(s)" > tmp_simnibs.py
python tmp_simnibs.py
rm tmp_simnibs.py
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
echo $sub
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



m2m_folder=$sub_ses_simnibs/m2m_$sub

#RUL simulation 
elec1='FT8'
elec2='C2'
outfolder=$sub_ses_simnibs/simnibs_sim_RUL
simulation_simnibs $sub $m2m_folder $outfolder $elec1 $elec2 


#BT simulation 
elec1='FT8'
elec2='FT7'
outfolder=$sub_ses_simnibs/simnibs_sim_BT
simulation_simnibs $sub $m2m_folder $outfolder $elec1 $elec2 

