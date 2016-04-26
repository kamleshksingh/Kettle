#!/bin/ksh
#*******************************************************************************
#** Program         :   mkdm_con_event_detail_weekly.sh
#**
#** Job Name        :   MKDMCCSTG
#**
#** Original Author :   Beneven Noble
#**
#** Description     :   This script pulls Connected content information weekly into
#**                     CONTENT_EVENT_DETAIL from CCC_CDR_Y
#**                     in PANS and ACCOUNT_KEY_REF
#**                     table in MKDM.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- -----------------------------------------------------
#** 11/21/2007 nbeneve  Initial checkin.
#*****************************************************************************

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
# Function to check the return status and set the appropriate # message
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
check_variables start_step ORA_CONNECT data_tablespace index_tablespace EDW_DB_LINK PANS_DB_LINK
#-----------------------------------------------------------------
#-----------------------------------------------------------------
step_number=1
# Description: Create CONTENT_EVENT_DETAIL_STG table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_con_evt_det_stg.sql $data_tablespace $PANS_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Delete records from content_event_detail_log after 45 days 
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_con_evt_det_log.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Insert unmatched records into CONTENT_EVENT_DETAIL_STG table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_ins_con_evt_det_stg.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Create index on CONTENT_EVENT_DETAIL_STG table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_con_evt_det_stg.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Analyze CONTENT_EVENT_DETAIL_STG table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM CONTENT_EVENT_DETAIL_STG 5
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Create ACCT_KEY_BTN_XREF_TMP from ACCOUNT_KEY_REF table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_acct_key_btn_xref_tmp.sql $data_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Create index on ACCT_KEY_BTN_XREF_TMP table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_acct_key_btn_xref_tmp.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Create CONTENT_EVENT_DETAIL_TMP table with blg_to_cust_acct_id
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_con_evt_det_tmp.sql $data_tablespace $EDW_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Create CONTENT_EVENT_DETAIL_TMP2 table with accout information 
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_con_evt_det_tmp2.sql $data_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Inserts records into CONTENT_EVENT_DETAIL table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_ins_con_evt_det.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=11
# Description: Analyze CONTENT_EVENT_DETAIL table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM CONTENT_EVENT_DETAIL 5
    check_status
fi

#-----------------------------------------------------------------
step_number=12
# Description: Inserts records into content_event_detail_log table
#               
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_ins_con_evt_det_log.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=13
# Description: Drop temp tables 
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drp_ced_tmp_tbls.sql
    check_status
fi

exit 0
