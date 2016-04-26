#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_account_question_hist.sh
#** 
#** Job Name        :  
#** 
#** Original Author : Sanjeev Chaudhary 
#**
#** Description     :  Script to load account_question_hist data from PVG 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 06/21/2004 schaudh  Initial checkin.
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


#----------------------------------------------------------------
# Get the last run date for this pull. If job is running first
# time then default the run time to back date.
#----------------------------------------------------------------
export last_run_date=`get_last_run_date $L_SCRIPTNAME C`

export last_run_date=${last_run_date:='12:31:1900:00:00:00'}
print "Last Run Date: $last_run_date"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables RBS_LARGE start_step L_SCRIPTNAME ORA_CONNECT MKDM_ERR_LIST last_run_date

#-----------------------------------------------------------------
step_number=1
#  Description: Check if this job has already run today. If Yes,
#               bail out.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   check_job_status  $L_SCRIPTNAME C SYSDATE
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#  Description: Delete all the indexes 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   nuke_all MKDM account_question_hist per
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Move account_question  data from PVG
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql  mkdm_account_question_hist_delta  $RBS_LARGE $PVG_DB_LINK $last_run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#  Description: Create indexes on table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm account_question_hist per
   check_status
fi

echo $(date) done
exit 0
