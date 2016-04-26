#!/bin/ksh
#*******************************************************************************
#** Program         :  	mkdm_cons_rev_details_weekly.sh
#** 
#** Job Name        :  	CONREVDTL
#**
#** Original Author :  	panbala
#**
#** Description     :  	This script pulls revenue information weekly into 
#**			CONSUMER_REVENUE_DET from STG_MKDM_BKD_BLG_DTL and
#**                     MKDM_LOAD_CONTROL tables in FINEDW and ACCOUNT_KEY_REF
#**		       	table in MKDM.This table will be used for populating
#**			CONSUMER_REVENUE_SUMMARY table in CRDM.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 07/13/2006 panbala	Initial checkin.
#** 08/04/2006 dxkumar  added table ACCT_BTN_REF_CURRENT_TEMP for population
#*****************************************************************************

#test hook
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
check_variables start_step ORA_CONNECT data_tablespace index_tablespace EDW_DB_LINK

#-----------------------------------------------------------------
step_number=1
# Description: 	Create Partition for all missed out partitions of
#	       	CONSUMER_REVENUE_DET table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    echo "*** Step Number $step_number"
    create_partition CONSUMER_REVENUE_DET
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description:  Pull account/btn cross referencer information into
#		ACCT_BTN_XREF_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_acct_btn_xref_temp.sql $data_tablespace $EDW_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Create index for ACCT_BTN_XREF_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_acct_btn_xref_temp.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Analyze ACCT_BTN_XREF_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM ACCT_BTN_XREF_TEMP 5
    check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Extract acct_id,acct_seq_no and btn into
# ACCT_BTN_REF_CURRENT_TEMP table from ACCOUNT_KEY_REF table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_btn_ref_current_temp.sql
   check_status
fi 



#-----------------------------------------------------------------
step_number=6
# Description: Create index for ACCT_BTN_REF_CURRENT_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_btn_ref_current_temp.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Analyze ACCT_BTN_REF_CURRENT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM ACCT_BTN_REF_CURRENT_TEMP 5
   check_status
fi


#-----------------------------------------------------------------
step_number=8
# Description:	Insert records into CONSUMER_REVENUE_DET table from
#		STG_MKDM_BKD_BLG_DTL and MKDM_LOAD_CONTROL tables in
#		FINEDW and ACCT_BTN_XREF table in MKDM
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_cons_rev_dtl.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Analyze CONSUMER_REVENUE_DET Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    echo "*** Step Number $step_number"
    analyze_table mkdm CONSUMER_REVENUE_DET 5
    check_status
fi
#-----------------------------------------------------------------
step_number=10
# Description: Drop temp tables.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drop_rev_dtl_temp_tbl.sql
    check_status
fi

echo $(date) done
exit 0
