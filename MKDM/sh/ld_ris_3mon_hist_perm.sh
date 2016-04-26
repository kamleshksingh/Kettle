#!/bin/ksh
#*******************************************************************************
#** Program Name    : ld_3mon_hist_perm.sh
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
#** 03/30/2006 dpannee  Added steps to load table ris_3mon_hist_perm_usage
#** 01/17/2006 sganapa  Dont exit the job if erros in dat file is less than
#**                     given max_err_count
#** 07/13/2004 jkading  Initial Checkin 
#*****************************************************************************

#test hook
#. ~/pcms/mkdm/common/.mkdm_env.tst
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

#----------------------------------------------------------------r
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
#Description:   Load table STG_RIS
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

truncate_table STG_RIS

max_err_count=100000
LOAD_LOG=${LOGDIR}/ld_stg_ris$$.log
print "Loading the RIS flat file to STG_RIS table"
sqlldr userid=${ORA_CONNECT} \
      control=${CTLDIR}/ld_stg_ris.ctl \
      data= ${STAGEDIR}/ris/ris.dat  \
      log=$LOAD_LOG \
      bad=${DATADIR}/ld_stg_ris$$.bad  \
      rows=100000 \
      errors=$max_err_count \
      DIRECT=TRUE

bad_rec_count=`grep "Total logical records rejected" $LOAD_LOG | cut -d':' -f2 | sed -e 's/ //g'`
check_status
if [ $bad_rec_count -gt $max_err_count ] ; then
    err_msg="Errors Exceeded:$bad_rec_count. Allowed:$max_err_count. Step: $step_number"
    echo "$err_msg"
    subject_msg="Job Error - $L_SCRIPTNAME"
    send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
    exit $step_number   
fi
fi

#-----------------------------------------------------------------
step_number=2
#Description:   Create WTN level table dist_wtm_tmp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_dist_wtn_tmp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:   Analyze table dist_wtm_tmp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm dist_wtn_tmp 5
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Create table ris_perm_usage_tmp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_ris_perm_usage_tmp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Loading table ris_3mon_hist_perm_usage
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_ris_3mon_perm_usage.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Delete records older than 3 months
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_ris_3mon_perm_usage_trim.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Analyze table ris_3mon_hist_perm_usage
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm ris_3mon_hist_perm_usage 5
   check_status
fi

#-----------------------------------------------------------------
#step_number=$
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
#success_msg="Completed successfully"
#subject_msg="Completed successfully"
#send_mail "$success_msg" "$subject_msg" "$MAIL_LIST"
#check_status

exit 0

