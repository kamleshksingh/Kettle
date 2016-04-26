#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_rcr_repair_ticket_info.sh
#**
#** Original Author :  dxpanne
#**
#** Job Name        : LDRCREPAIR 
#**
#** Description     :  To load the repair ticket information from RCR 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 02/09/2011 dxpanne  Initial Checkin
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

#---------------------------------------------------------------------------
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
export ORA_CONNECT=$CONNECT_CRDM
get_crdm_flex_env RCR_TBL_TKT_NO_OF_RUNS  tbl_tkt_no_of_runs
check_status

export ORA_CONNECT=$ORA_CONNECT_MKDM
cur_date=`date +%Y%m%d`

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------
print "$L_SCRIPTNAME started at `date` \n"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables MKDM_DB_LINK CONNECT_CRDM ORA_CONNECT CONNECT_BDM LINK_TO_RCR 
check_variables ORA_CONNECT_MKDM tbl_tkt_no_of_runs data_tablespace cur_date
#-----------------------------------------------------------------
step_number=1
#Description: TO Check if CONSUMER_REPAIR_TKT_STAGE is loaded 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

   table_load_date=`sqlplus -s $ORA_CONNECT   <<EOT
          SET FEEDBACK OFF VERIFY OFF HEAD OFF ECHO OFF
          SET SERVEROUTPUT OFF TIMING OFF
          SET PAGES 0
          WHENEVER OSERROR EXIT  1
          WHENEVER SQLERROR EXIT 1
          SELECT TO_CHAR(MAX(load_dt),'YYYYMMDD') FROM rcr_repair_ticket_status;
          EXIT;
   EOT`
   check_status
   echo "table load date is $table_load_date"

   table_load_status=`sqlplus -s $ORA_CONNECT   <<EOT
          SET FEEDBACK OFF VERIFY OFF HEAD OFF ECHO OFF
          SET SERVEROUTPUT OFF TIMING OFF
          SET PAGES 0
          WHENEVER OSERROR EXIT  1
          WHENEVER SQLERROR EXIT 1
          SELECT COUNT(1) FROM rcr_stage_audit@$LINK_TO_RCR
			WHERE job_name='DAILY_REPAIR_TICKETS_TO_CRDM'
			AND trunc(load_end_date)=TRUNC(SYSDATE)
			AND processed='Y';
          EXIT;
   EOT` 
   check_status

   echo "table load status is $table_load_status"
   echo "Number of runs $tbl_tkt_no_of_runs"
  if [ $table_load_date -ne  $cur_date ] ; then
     if [ $tbl_tkt_no_of_runs -le 3 ] ; then 
        if  [ $table_load_status -ne 1 ] ; then
              tbl_tkt_no_of_runs_upd=`expr $tbl_tkt_no_of_runs + 1`
              export ORA_CONNECT=$CONNECT_CRDM
              upd_crdm_flex_env RCR_TBL_TKT_NO_OF_RUNS $tbl_tkt_no_of_runs_upd
              check_status    	
              exit 0
        else
           echo "RCR staging table is loaded" 
        fi
     else
          echo "CONSUMER_REPAIR_TKT_STAGE not loaded for `date`" 
          mail_msg="CONSUMER_REPAIR_TKT_STAGE  not loaded"
          sub_msg="The table CONSUMER_REPAIR_TKT_STAGE not loaded for `date`" 
          send_mail "$mail_msg" "$sub_msg" "$RCR_MAIL_LIST"
          check_status
          export ORA_CONNECT=$CONNECT_CRDM
          upd_crdm_flex_env RCR_TBL_TKT_NO_OF_RUNS 1
          check_status 
          exit 1
     fi 
   else 
        echo "Job has been processed already"
        mail_msg="Job already processed"
        sub_msg="The table RCR_REPAIR_TICKET_STATUS loaded for `date`"
        send_mail "$mail_msg" "$sub_msg" "$MKDM_ERR_LIST"
        check_status 
        exit 0
  fi

check_status
fi 

export ORA_CONNECT=$ORA_CONNECT_MKDM

#-----------------------------------------------------------------
step_number=2
#Description: To delete the closed tickets older than 30 days 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_close_ticket_status.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:To create a temp table RCR_REPAIR_TICKET_STAGE 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_rcr_stage_table.sql $data_tablespace $LINK_TO_RCR 
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Analyze the table RCR_REPAIR_TICKET_STAGE 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM RCR_REPAIR_TICKET_STAGE 5 
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Create a temp table for already existing ticket in STATUS table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_tkt_exist.sql $data_tablespace  
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Delete the already existing tickets RCR_REPAIR_TICKET_STATUS 
#            Which is in STAGE table also   
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_tkt_status_exist.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Insert the existing  records into RCR_REPAIR_TICKET_STATUS 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_tkt_status_exist.sql 
   check_status
fi


#-----------------------------------------------------------------
step_number=8
#Description:Create the temp table for new records in staging table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_tkt_new.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description: Insert the new tickets into RCR_REPAIR_TICKET_STATUS
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_new_tkt_status.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description:Create temp table for tickets whose acct information
#            is null
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_null_acct.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Update the account information in RCR_REPAIR_TICKET_STATUS
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_acct_tkt_status.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description: Analyze the table RCR_REPAIR_TICKET_STATUS 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM RCR_REPAIR_TICKET_STATUS 5
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description: Truncate and load the CRDM.RCR_REPAIR_TICKET_STATUS
#------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_CRDM
   run_sql mkdm_ins_crdm_tkt_status.sql $MKDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description: Truncate and load the BDM.RCR_REPAIR_TICKET_STATUS
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_BDM
   run_sql mkdm_ins_bdm_tkt_status.sql $MKDM_BDM_LINK
   check_status
fi

export ORA_CONNECT=$ORA_CONNECT_MKDM

#-----------------------------------------------------------------
step_number=15
#Description: Drop the temp tables 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_temp_tkt_tables.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description: To udpate crdm_flex_env RCR_TBL_TKT_NO_OF_RUNS
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_CRDM
   upd_crdm_flex_env RCR_TBL_TKT_NO_OF_RUNS 1
   check_status
fi

exit 0
