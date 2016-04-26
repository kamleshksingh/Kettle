#!/bin/ksh
#*******************************************************************************
#** Program         :  video_qual.sh
#** 
#** Job Name        :  
#** 
#** Original Author : Sanjeev Chaudhary 
#**
#** Description     :  Script to load video qualifications from MKDM 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 06/21/2004 schaudh  Initial checkin.
#** 11/22/2006 jannama  Added SQL to create and analyze table STG_VIDEO_ACCOUNT_CRIS
#*****************************************************************************

##############################################################################
# Comment these test hooks before deilvery
##############################################################################
. ~/.mkdm_env
. $FPATH/common_funcs.sh

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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST CDW_DB_LINK

#-----------------------------------------------------------------
step_number=1
#  Description: To create a table stg_video_account_cris
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql mkdm_crt_stg_video_account_cris $CDW_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#  Description:Analyze the table stg_video_account_cris
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm stg_video_account_cris 50
   check_status
fi
 
#-----------------------------------------------------------------
step_number=3
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   run_sql  mkdm_video_qual_temp
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  video_qual_temp 50
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   run_sql  mkdm_vdsl_data_temp
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  video_cap_temp 50
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  video_data_temp 50
   check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Truncate the table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    truncate_table video_qual
    check_status
fi

#-----------------------------------------------------------------
step_number=9
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   nuke_all MKDM video_qual per
   check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Truncate the table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    truncate_table bus_video_qual
    check_status
fi

#-----------------------------------------------------------------
step_number=11
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   nuke_all MKDM bus_video_qual per
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   run_sql  mkdm_video_qual $ORA_CONNECT $RBS_LARGE
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm video_qual per
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#  Description: 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm bus_video_qual per
   check_status
fi

echo $(date) done
exit 0
