#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_stg_video_data.sh
#**
#** Job Name        :  STGVIDDATA
#**
#** Original Author :  Sanjeev Chaudhary
#**
#** Description     :  Script to load video data from VDSL data mart.
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
#** 08/10/2006 vxragun  Adding VMDU column to video tables
#** 06/26/2007 jannama  Added steps to include common function check_dedup
#** 06/11/2015 Nirmal   Modified for CR5327 for CSG #**Replacement at Step # 3 & 5
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

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT MKDM_ERR_LIST
check_variables data_tablespace index_tablespace

#-----------------------------------------------------------------
step_number=1
# Description: Truncate the table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    truncate_table stg_video_data
    check_status
fi

#-----------------------------------------------------------------
step_number=2
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   nuke_all MKDM stg_video_data per
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
#  run_sql  #mkdm_stg_video_data $RBS_LARGE  $VDSL_DB_LINK
   run_sql  mkdm_stg_video_data $RBS_LARGE  $DWPRD_DB_LINK  $EDWDH_DB_LINK  $VDSL_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm stg_video_data per
   check_status
fi

#------------------------------------------------------------------
step_number=5
#  Description: Create MKDM_SUB_ACCT_NTWK_ADDR_KEY table with sub_acct_no
# 		and ntwk_addr_key
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
#  run_sql #mkdm_crt_sub_acct_ntwk_addr_key $data_tablespace $VDSL_DB_LINK

   run_sql mkdm_crt_sub_acct_ntwk_addr_key $data_tablespace $DWPRD_DB_LINK $EDWDH_DB_LINK  $VDSL_DB_LINK 
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#  Description: Create index on MKDM_SUB_ACCT_NTWK_ADDR_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_sub_acct_ntwk_addr_key $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#  Description: Analyze MKDM_SUB_ACCT_NTWK_ADDR_KEY table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_SUB_ACCT_NTWK_ADDR_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#  Description: Create MKDM_WORK_NTWK_KEY table with ntwk_addr_key
#  		vmdu_cd and load_dat
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_work_ntwk_key $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#  Description: Create index on MKDM_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_work_ntwk_key $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#  Description: Analyze MKDM_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_WORK_NTWK_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#  Description: Create MKDM_SUB_ACCT_WORK_NTWK_KEY table with sub_acct_no,
#	        vmdu_cd and load_dat
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_sub_acct_work_ntwk_key $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#  Description: Analyze MKDM_SUB_ACCT_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_SUB_ACCT_WORK_NTWK_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#  Description: Run Common function to check for duplicates on
#               MKDM_SUB_ACCT_WORK_NTWK_KEY table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   check_dedup DUP_COUNT_VAR stgvdta101
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#  Description: Dedup MKDM_SUB_ACCT_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_dedup_sub_acct_work_ntwk_key
   check_status
fi

#-----------------------------------------------------------------
step_number=15
#  Description: Run common function to check for duplicates on
#               MKDM_SUB_ACCT_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   check_dedup DUP_COUNT_VAR stgvdta101
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#  Description: Create index on MKDM_SUB_ACCT_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_idx_sub_acct_work_ntwk_key $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=17
#  Description: Analyze MKDM_SUB_ACCT_WORK_NTWK_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table MKDM MKDM_SUB_ACCT_WORK_NTWK_KEY 5
   check_status
fi

#------------------------------------------------------------------
step_number=18
#  Description: Create STG_VIDEO_DATA_TEMP table to populate vmdu
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_stg_video_data_temp $data_tablespace
   check_status
fi

#------------------------------------------------------------------
step_number=19
#  Description: Drop stg_video_data and other temp tables
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_drop_stg_video_data
   check_status
fi

#------------------------------------------------------------------
step_number=19
#  Description: Rename stg_video_data_temp to stg_video_data table
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_rename_stg_video_data
   check_status
fi

#------------------------------------------------------------------
step_number=20
#  Description: Build index and analyze STG_VIDEO_DATA table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm stg_video_data per
   check_status
fi

echo $(date) done
exit 0
