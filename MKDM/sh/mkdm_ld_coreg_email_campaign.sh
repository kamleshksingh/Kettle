#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_coreg_email_campaign.sh
#**
#** Original Author :  dxpanne
#**
#** Job Name        :  LDEMCOREG
#**
#** Description     :  To update email_campaign_cur with COREG records
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 01/17/2011 dxpanne  Initial Checkin
#** 06/15/2011 vsivaku  Modified SQLs for including 4 email pref ind and
#**                     Added step 9 for updating mktg_pref_ind CSTAKE237263
#** 09/09/2011 pchidam  Changed logic to update mktg_pref_ind
#**                     (mkdm_coreg_acx_upd_mktg_pref_ind.sql in this job should have
#**                      the same logic as mkdm_email_camp_upd_mktg_pref_ind.sql in EMAILCAMP)
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

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
     send_mail "$err_msg" "$subject_msg" "$MAIL_LIST"
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
check_variables CRDM_DB_LINK CONNECT_CRDM ORA_CONNECT 
check_variables data_tablespace ORA_CONNECT_MKDM

export ORA_CONNECT=$CONNECT_CRDM
#-----------------------------------------------------------------
step_number=1
#Description: Create COREG_EMAIL in CRDM from the geomkt schema
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_crdm_coreg_email.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Analyze CRDM COREG_EMAIL Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table CRDM COREG_EMAIL 5
   check_status
fi

export ORA_CONNECT=$ORA_CONNECT_MKDM
#-----------------------------------------------------------------
step_number=3
#Description: Move records from EMAIL_CAMPAIGN_CUR that have matching records in COREG_EMAIL
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_mv_match_email_camp_hist.sql $CRDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Create a temp table with records in COREG_EMAIL that have match in EMAIL_CAMPAIGN_CUR and optouts
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_email_coreg_match.sql $data_tablespace $CRDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Delete the records that were moved to hist from CUR table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_hist_from_cur.sql $CRDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Insert the COREG matched records into EMAIL_CAMPAIGN_CUR
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_matched_records_cur.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Insert the COREG unmacthed records into EMAIL_CAMPAIGN_CUR
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_new_records_cur.sql $data_tablespace $CRDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Update mktg_pref_ind for all records in email_campaign_cur 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_coreg_acx_upd_mktg_pref_ind.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description: Analyze table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM EMAIL_CAMPAIGN_CUR 5
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: Drop Temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drop_coreg_temp_tables.sql
   check_status
fi

exit 0
