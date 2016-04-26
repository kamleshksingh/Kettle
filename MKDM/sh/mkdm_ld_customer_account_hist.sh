#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_customer_account_hist.sh
#**
#** Job Name        :  LDCUSTHIST
#**
#** Original Author :  kpilla
#**
#** Description     :  Driver script to create history for STG_CUSTOMER_ACCOUNT table.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/16/2008 kpilla  Initial checkin.
#*****************************************************************************

#test hook
#. ~/.setup_env
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

start_step=0
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
get_db_value HIST_YR_MON "DATA_MO FROM STG_CUSTOMER_ACCOUNT" "WHERE ROWNUM <2"

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
check_variables start_step ORA_CONNECT HIST_YR_MON 

#-----------------------------------------------------------------
step_number=1
#Description: To check if current month data is already loaded
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   SQL1="count(1) from CUSTOMER_ACCOUNT_HIST";
   SQL2="partition(P${HIST_YR_MON})";
   get_db_value count "$SQL1" "$SQL2"
   echo "Number of records in partition: $count"
   if [ $count != 0 ] ; then
     echo "Data is already loaded in CUSTOMER_ACCOUNT_HIST for the partition P${HIST_YR_MON}";
     exit 0
   fi
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Creates table CUSTOMER_ACCT_HIST_TEMP table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_stg_customer_acct_hist.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Exchange the partition of CUSTOMER_ACCOUNT_HIST with
#             that of the CUSTOMER_ACCT_HIST_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_exch_part_cust_acct_hist.sql P${HIST_YR_MON}
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Rebuild local index of the new partition
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_local_idx_build_cust_acct_hist.sql P${HIST_YR_MON}
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Analyze latest partition of CUSTOMER_ACCOUNT_HIST table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_partition_table MKDM CUSTOMER_ACCOUNT_HIST P${HIST_YR_MON} 5
    check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Drop the temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_cust_acct_tmp_tbls.sql
   check_status
fi

echo $(date) done
exit 0
