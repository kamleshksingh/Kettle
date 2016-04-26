#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_stg_video_cap.sh
#**
#** Job Name        :
#**
#** Original Author : Sanjeev Chaudhary
#**
#** Description     :  Script to load video capabilities  from VDSL data mart.
#**                    This Job will be Forced from VDSL once the source has been Populated
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/21/2004 schaudh  Initial checkin.
#** 06/06/2006 fxmoham  Control M changes, Job to be Forced from VDSL
#** 08/10/2006 urajend  Changes for getting vmdu column into stg_video_cap
#** 06/26/2007 jannama  Added step to include common function check_dedup
#*****************************************************************************

##############################################################################
# Comment these test hooks before deilvery
##############################################################################
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_string=$(date '+%Y%m%d')
start_step=0

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------


#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of
#this script. d for Debug is always the default
#-----------------------------------------------------------------

while getopts "s:t:i:d:f" option
do
   case $option in
     s) start_step=$OPTARG;;
     t) data_tablespace=$OPTARG;;
     i) index_tablespace=$OPTARG;;
     d) debug=1;;
     f) date_string=$OPTARG;;
   esac
done
shift $(($OPTIND - 1))

#-----------------------------------------------------------------
# Set the default values for all options.  This will only set the
# variables which were NOT previously set in the getopts section.
#-----------------------------------------------------------------
debug=${debug:=0}


#-----------------------------------------------------------------
#Check for debug mode [-d]
#-----------------------------------------------------------------
if [ $debug -eq 1 ]; then
   set -x
fi

#-----------------------------------------------------------------
# Set $ parameters here.
#-----------------------------------------------------------------


#-----------------------------------------------------------------
# Function to check the return status and set the appropriate
# message
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then
     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     echo "$err_msg"

     subject_msg="Job Error - $L_SCRIPTNAME"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
     exit $step_number
  fi
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
date

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT MKDM_ERR_LIST

#-----------------------------------------------------------------
step_number=1
# Description: Truncate the table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    truncate_table stg_video_cap
    check_status
fi

#-----------------------------------------------------------------
step_number=2
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   nuke_all MKDM stg_video_cap per
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql  mkdm_stg_video_cap $RBS_LARGE  $VDSL_DB_LINK
   check_status
fi


#-----------------------------------------------------------------
step_number=4
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm stg_video_cap per
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#  Description: Create a temp table with hse_key and ntwk_addr_key
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_hse_ntwk_addr_key $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#  Description: Create index on the mkdm_hse_ntwk_addr_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_hse_ntwk_addr_key $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#  Description: Analyze mkdm_hse_ntwk_addr_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_HSE_NTWK_ADDR_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#  Description: Create a temp table with distinct ntwk_addr_keys from work_network
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_work_ntwk_cap_key $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#  Description: Create index on mkdm_work_ntwk_cap_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_work_ntwk_cap_key $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#  Description: Analyze mkdm_work_ntwk_cap_key
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_WORK_NTWK_CAP_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#  Description: Create a temp table with hse_key,vmdu and load_dat
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_hse_work_ntwk_key $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#  Description: Analyze mkdm_hse_work_ntwk_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_HSE_WORK_NTWK_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#  Description: Run Common function to check for duplicates on
#               mkdm_hse_work_ntwk_key table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   check_dedup DUP_COUNT_VAR stgvcap101
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#  Description: Delete duplicates from mkdm_hse_work_ntwk_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_dedup_hse_work_ntwk_key
   check_status
fi

#-----------------------------------------------------------------
step_number=15
#  Description: Run common function to check for duplicates on
#               mkdm_hse_work_ntwk_key table.
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   check_dedup DUP_COUNT_VAR stgvcap101
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#  Description: Create index on mkdm_hse_work_ntwk_key table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_hse_work_ntwk_key $index_tablespace
   check_status
fi

#------------------------------------------------------------------
step_number=17
#  Description: Create stg_video_cap_temp table to populate vmdu
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_stg_video_cap_temp $data_tablespace
   check_status
fi

#------------------------------------------------------------------
step_number=18
#  Description: Drop stg_video_cap and the other temp tables
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_drop_stg_video_cap
   check_status
fi

#------------------------------------------------------------------
step_number=19
#  Description: Rename stg_video_cap_temp to stg_video_cap table
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_rename_stg_video_cap
   check_status
fi

#------------------------------------------------------------------
step_number=20
#  Description: Analyze stg_video_cap table
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm stg_video_cap per
   check_status
fi

echo $(date) done
exit 0
