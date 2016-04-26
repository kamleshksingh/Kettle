#!/bin/ksh
#*******************************************************************************
#** Program Name    : ld_usage_tn.sh.sh
#** Job Name        :  
#** 
#** Original Author :  
#**
#** Description     :   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 07/13/2004 jkading  Initial Checkin
#** 02/25/2005 bsyptak  Added new steps 5 & 6 to get canada & mex avgs and new count_recs step 
#** 06/25/2007 jannama  Added steps to include Common function check_dedup
#*****************************************************************************

#test hook
#. mkdm_env 
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of 
#this script. d for Debug is always the default
#-----------------------------------------------------------------

while getopts "s:t:i:d" option
do
   case $option in
     s) start_step=$OPTARG;;
     t) data_tablespace=$OPTARG;;
     i) index_tablespace=$OPTARG;;
     d) debug=1;;
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

#-----------------------------------------------------------------
step_number=1
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_ris_3mon_sum_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm ris_3mon_sum_temp 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_ris_3mon_avg_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_idx_ris_3mon_avg_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm ris_3mon_avg_temp 5
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_ris_3mon_dom_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_idx_ris_3mon_dom_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm ris_3mon_dom_temp 5
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_usage_tn.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: Run Common function to check for duplicates on 
#             ld_usage_tn table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   check_dedup DUP_COUNT_VAR ldusgtn101
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_usage_tn_dedup.sql 
   check_status
fi


#-----------------------------------------------------------------
step_number=12
#Description: Run common function to check for duplicates on
#             ld_usage_tn table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   check_dedup DUP_REC_CNT ldusgtn101
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm ld_usage_tn 5
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description: Count records in table to insure there are > 0 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   typeset -i cnt=`count_recs ld_usage_tn` || check_status
   echo "*** Record Count is:  $cnt"
   [ $cnt -gt 0 ]
   check_status
fi

#-----------------------------------------------------------------
#step_number=$
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="$L_SCRIPTNAME Completed successfully"
subject_msg="$L_SCRIPTNAME Completed successfully"
send_mail "$success_msg" "$subject_msg" "$MKDM_LIST"
check_status

exit 0
