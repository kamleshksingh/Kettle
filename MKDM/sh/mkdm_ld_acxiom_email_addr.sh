#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_ld_acxiom_email_addr.sh
#**
#** Job Name        : LDAXMEMAIL
#**
#** Original Author : rxsank2
#**
#** Description     : Job to extract email addresses from geomkt/acxiom to email_campaign_cur
#**                   to support optimal email marketing capability
#**
#** Revision History: Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/29/2010 rxsank2  Initial Checkin [US 790232]
#** 07/14/2010 rxsank2  Change in design - Donot update source data from email_campaign_cur 
#** 04/01/2011 vsivaku  Change in design - Changed source from dbeckma to geomkt CSTAKE160493
#** 06/15/2011 vsivaku  Modified SQLs for including 4 email pref ind and 
#**                     Added step 23 for updating mktg_pref_ind CSTAKE237263
#** 09/09/2011 pchidam  Changed logic to update mktg_pref_ind
#**                     (mkdm_coreg_acx_upd_mktg_pref_ind.sql in this job should have 
#**                      the same logic as mkdm_email_camp_upd_mktg_pref_ind.sql in EMAILCAMP)
#** 02/06/2012 pchidam  Modified source for consumer data from GEOMKT to CRDM table CONS_EMAIL_APPEND
#**                     The business data will still be sourced from GEOMKT
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
check_variables start_step MKDM_ERR_LIST data_tablespace
check_variables CONNECT_CRDM CRDM_USERS CRDM_DB_LINK

export MKDM_ORA_CONNECT=$ORA_CONNECT
#These variables will be used to connect to MKDM and CRDM databases alternatively

#----------------------------------------------------------------------------------------
step_number=1
#Description: Populate mkdm_acxiom_email_append_cons from CRDM.cons_email_append
#             Run the job only if new data is available in this table 
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_CRDM
   tab_rec_cnt=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT count(1) FROM cons_email_append;
   QUIT;
   END_OF_SQL`
       if [ $tab_rec_cnt = 0 ]; then
              echo "No new consumer data found. The LDAXMEMAIL will not run this month."
              err_msg="LDAXMEMAIL - The consumer table does not contain any new records"
              subject_msg="LDAXMEMAIL - No new consumer data"
              send_mail "$err_msg" "$subject_msg" "$CRDM_USERS"               
              check_status
              exit 0
        else
              export ORA_CONNECT=$MKDM_ORA_CONNECT
              echo "New consumer data found will be processed for the LDAXMEMAIL run this month."
              run_sql mkdm_ins_mkdm_acxiom_email_append_cons.sql $CRDM_DB_LINK
              check_status
        fi
   check_status
fi

#----------------------------------------------------------------------------------------
step_number=2
#Description: Populate mkdm_acxiom_email_append_bus from geomkt
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_mkdm_acxiom_email_append_bus.sql
   check_status
fi

#----------------------------------------------------------------------------------------
step_number=3
#Description: Delete duplicates from mkdm_acxiom_email_append_cons
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_dedup_acxiom_addr_cons.sql  
   check_status
fi

#----------------------------------------------------------------------------------------
step_number=4
#Description: Delete duplicates from mkdm_acxiom_email_append_bus
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_dedup_acxiom_addr_bus.sql
   check_status
fi

#-------------------------------------------------------------------------------------- 
step_number=5
#Description: Create a temp table acxiom_email_bus_cons_tmp1  
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acxiom_email_bus_cons_tmp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------------------------------------
step_number=6
#Description: Delete email addresses from mkdm_acxiom_email_append_cons (res_bus address)
#-----------------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_append_cons.sql 
   check_status
fi

#-----------------------------------------------------------------------------------------------
step_number=7
#Description: Delete email addresses from mkdm_acxiom_email_append_bus (res_bus address)
#-----------------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_append_bus.sql
   check_status
fi

#-----------------------------------------------------------------------------------------------
step_number=8
#Description: Delete from acxiom_email_bus_cons_tmp
#-----------------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_bus_cons_tmp.sql 
   check_status
fi

#----------------------------------------------------------------
step_number=9
#Description: Analyze the table acxiom_email_bus_cons_tmp
#----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM ACXIOM_EMAIL_BUS_CONS_TMP 5
   check_status
fi

#----------------------------------------------------------------------------------------
step_number=10
#Description: Populate email_campaign_hist from email_campaign_cur (business_residential)
#----------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_acxiom_addr_bus_cons_email_camp_hist.sql 
   check_status
fi

#-----------------------------------------------------------------------------------------------
step_number=11
#Description: Delete email address from email_campaign_cur (business_residential email address)
#-----------------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_addr_bus_cons_email_camp_cur.sql 
   check_status
fi

#---------------------------------------------------------------------------
step_number=12
#Description: Insert into email_campaign_cur from acxiom_email_bus_cons_tmp
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_acxiom_addr_bus_cons_email_camp_cur.sql 
   check_status
fi

#---------------------------------------------------------------------------
step_number=13
#Description: Delete from mkdm_acxiom_email_append_cons (opt_out=Y and acct_type=B) 
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_append_cons_opt_Y_acct_B.sql 
   check_status
fi

#---------------------------------------------------------------------------
step_number=14
#Description: Analyze table mkdm_acxiom_email_append_cons 
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MKDM_ACXIOM_EMAIL_APPEND_CONS 5
   check_status
fi

#---------------------------------------------------------------------------
step_number=15
#Description: Delete from mkdm_acxiom_email_append_bus (opt_out =Y and acct_type=C)
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_append_bus_opt_Y_acct_C.sql
   check_status
fi

#---------------------------------------------------------------------------
step_number=16
#Description: Analyze table mkdm_acxiom_email_append_bus 
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MKDM_ACXIOM_EMAIL_APPEND_BUS 5
   check_status
fi

#---------------------------------------------------------------------------
step_number=17
#Description: create table acxiom_email_append_addr_tmp from cons and bus temp tables 
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acxiom_email_append_addr_tmp.sql $data_tablespace
   check_status
fi

#---------------------------------------------------------------------------
step_number=18
#Description: Analyze table acxiom_email_append_addr_tmp
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM ACXIOM_EMAIL_APPEND_ADDR_TMP 5
   check_status
fi

#---------------------------------------------------------------------------------------
step_number=19
#Description: Insert into email_campaign_hist from email_campaign_cur 
#---------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_acxiom_email_addr_email_camp_hist.sql
   check_status
fi

#-------------------------------------------------------------------------------------------
step_number=20
#Description: Delete from email_campaign_cur for addresses in acxiom_email_append_addr_tmp
#-------------------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_acxiom_email_addr_email_camp_cur.sql
   check_status
fi

#--------------------------------------------------------------------------------
step_number=21
#Description: Insert into email_campaign_cur from acxiom_email_append_addr_tmp
#--------------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_acxiom_email_addr_email_camp_cur.sql
   check_status
fi

#----------------------------------------------------------------
step_number=22
#Description: Update mktg_pref_ind for all records in email_campaign_cur 
#----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_coreg_acx_upd_mktg_pref_ind.sql
   check_status
fi

#----------------------------------------------------------------
step_number=23
#Description: Analyze the table email_campaign_cur
#----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM EMAIL_CAMPAIGN_CUR 5
   check_status
fi

#----------------------------------------------------------------
step_number=24
#Description: Analyze the table email_campaign_hist
#----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM EMAIL_CAMPAIGN_HIST 5
   check_status
fi

#----------------------------------------------------------------
step_number=25
#Description: Drop the temp tables created during the job 
#----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_acxiom_email_addr_tmp_tbls.sql
   check_status
fi

#----------------------------------------------------------------
step_number=26
#Description: Truncate the source table CONS_EMAIL_APPEND in CRDM
#----------------------------------------------------------------
export ORA_CONNECT=$CONNECT_CRDM
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_trunc_cons_email_append_tbl.sql
   check_status
fi

export ORA_CONNECT=$MKDM_ORA_CONNECT

#-----------------------------------------------------------------
#step_number=$
# Description: send_mail common function is called for successful
# completion and email notification.
#-----------------------------------------------------------------
success_msg="LDAXMEMAIL job completed sucessfully on `date` ."
subject_msg="LDAXMEMAIL job completed"
send_mail "$success_msg" "$subject_msg" "$MKDM_ERR_LIST"

exit 0
