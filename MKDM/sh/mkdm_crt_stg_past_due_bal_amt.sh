#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_crt_stg_past_due_bal_amt.sh
#**
#** Job Name        :  STGPASTAMT
#**
#** Original Author :  dxpanne
#**
#** Description     :  To create a staging table to pull data from EDW
#**                    to populate past due balance amount in consumer_account_inact
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/13/2008 dxpanne  Initial checkin.
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
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
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT data_tablespace 
check_variables EDW_DB_LINK index_tablespace

#-----------------------------------------------------------------
step_number=1
#Description: To get the max date from the table stg_past_due_bal_amt
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
rm -f ${DATADIR}/stg_past_due_bal_amt_date.dat
export cmp_date=`sqlplus -s $ORA_CONNECT <<EOT
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT MAX(jnl_year_no) FROM stg_past_due_bal_amt;
   QUIT;
EOT`

echo $cmp_date >> ${DATADIR}/stg_past_due_bal_amt_date.dat
check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: To drop and create the staging table stg_past_due_bal_amt
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    compare_date=`cat ${DATADIR}/stg_past_due_bal_amt_date.dat`
    run_sql mkdm_crt_stg_past_due_bal_amt.sql $data_tablespace $EDW_DB_LINK $compare_date
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: To create index on the table stg_past_due_bal_amt
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_stg_past_due_bal_amt.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Analyze STG_PAST_DUE_BAL_AMT table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM STG_PAST_DUE_BAL_AMT 5
    check_status
fi

echo $(date) done
exit 0
