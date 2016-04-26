#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_email_campaign_cur.sh
#**
#** Job Name        : EMAILCAMP
#**
#** Original Author : czeisse
#**
#** Description     : Process to load the weekly email_campaign_cur table and
#**                   move the old records to history.
#**
#**
#** Revision History:   Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/28/2006 czeisse  initial checkin
#** 01/17/2006 jannama  Modified to send out mail if RCR files are missing
#** 02/22/2007 urajend  Modified for Generating Email Audit and notification.
#** 06/26/2007 jannama  Added Steps to include common function check_dedup
#** 02/12/2008 dxpanne  Added Steps to update account information
#** 02/24/2009 bzachar  Changed report structure to show new eamil address count
#** 04/02/2009 dxpanne  Added steps to update domain_nm and wrls_domain_indr
#** 09/01/2009 pchidam  Modified script to process ACXIOM email files
#** 10/26/2009 mxlaks2  Changed the file format of the ACXIOM email files
#** 02/17/2011 vsivaku  Added step to process PREFERENCES file from Acxiom
#**                     Added mktg_pref_ind-If this is Y records will be pushed to BDM/CRDM
#** 03/11/2011 pchidam  Modified to pull RCR data from basecamp instead of emdb flat files
#**                     Modified History table to hold only 2 years data
#** 05/05/2011 pchidam  Modified Date Format to reflect DD-MOM-YYYY
#** 06/21/2011 txmx     Added the logic to handle PREFERENCES_ACXIOM_BTNCC file 
#** 08/29/2011 pchidam  Changes to mktg_pref_ind logic and fixing metadata in SQLs
#** 11/18/2011 pchidam	Removed OPTOUT_ACXIOM_*,INVALID_ACXIOM_* and RES_OPTIN_* files from processing
#** 06/06/2013 arpatel  Replacing EDWP_DB_LINK by BASE2_DB_LINK -- HD00006272547
#*****************************************************************************

. ~/.mkdm_env
. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`
today=`date +%Y%m%d`

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
# Set $ parameters here.
#-----------------------------------------------------------------

export ORA_CONNECT=$CONNECT_CRDM
get_crdm_flex_env MKDMEMAIL_RUN_DATE mkdmemail_run_date
check_status

export ORA_CONNECT=$ORA_CONNECT_MKDM

OPTIN_ctl=${CTLDIR}/email_ext_OPTIN.ctl
OPTIN_log=${LOGDIR}/email_ext_OPTIN_${today}.log
OPTIN_bad=${LOGDIR}/email_ext_OPTIN_${today}.bad
OPTIN_dis=${LOGDIR}/email_ext_OPTIN_${today}.dis

OPTOUT_ctl=${CTLDIR}/email_ext_OPTOUT.ctl
OPTOUT_log=${LOGDIR}/email_ext_OPTOUT_${today}.log
OPTOUT_bad=${LOGDIR}/email_ext_OPTOUT_${today}.bad
OPTOUT_dis=${LOGDIR}/email_ext_OPTOUT_${today}.dis

RES_OPTOUT_ctl=${CTLDIR}/email_ext_RESOPTOUT.ctl
RES_OPTOUT_log=${LOGDIR}/email_ext_RESOPTOUT_${today}.log
RES_OPTOUT_bad=${LOGDIR}/email_ext_RESOPTOUT_${today}.bad
RES_OPTOUT_dis=${LOGDIR}/email_ext_RESOPTOUT_${today}.dis

PREFERENCES_ACXIOM_ctl=${CTLDIR}/email_PREFERENCES_ACXIOM.ctl
PREFERENCES_ACXIOM_log=${LOGDIR}/email_PREFERENCES_ACXIOM_${today}.log
PREFERENCES_ACXIOM_bad=${LOGDIR}/email_PREFERENCES_ACXIOM_${today}.bad
PREFERENCES_ACXIOM_dis=${LOGDIR}/email_PREFERENCES_ACXIOM_${today}.dis

PREFERENCES_ACXIOM_BTNCC_ctl=${CTLDIR}/email_PREFERENCES_ACXIOM_BTNCC.ctl
PREFERENCES_ACXIOM_BTNCC_log=${LOGDIR}/email_PREFERENCES_ACXIOM_BTNCC_${today}.log
PREFERENCES_ACXIOM_BTNCC_bad=${LOGDIR}/email_PREFERENCES_ACXIOM_BTNCC_${today}.bad
PREFERENCES_ACXIOM_BTNCC_dis=${LOGDIR}/email_PREFERENCES_ACXIOM_BTNCC_${today}.dis


#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
start_step=${start_step:=1}

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables data_tablespace mkdmemail_run_date BASECAMP_DB_LINK
check_variables ORA_CONNECT BASE2_DB_LINK 

#-----------------------------------------------------------------
step_number=1
#Description: Move the external & ACXIOM
#             files from /opt/stage02 to /opt/stage01/mkdm/email
#-----------------------------------------------------------------
echo "Executing Step: $step_number"
if [ $start_step -le  $step_number ] ; then
    cd ${STAGE02DIR}

       if [ `ls *ACXIOM*.dat *ACXIOM*.txt | wc -l` -gt 0 ]; then
       ACX_FILES=`ls PREFERENCES_ACXIOM_????????.dat PREFERENCES_ACXIOM_BTNCC_????????.dat`
        for ACXFILE1 in $ACX_FILES
         do
           mv ${STAGE02DIR}/$ACXFILE1 ${EMAIL_DATADIR}
           check_status
         done      
       else
        send_mail "No ACXIOM email files found in ${STAGE02DIR}" "MKDM EMAILCAMP ACXIOM files missing" "$EMAILREP_MAIL_LIST"
        check_status
       fi

      EXT_LIST=`ls OPTIN*.dat RES_OPTOUT*.dat OPTOUT*????-??-??*.dat`
        for DATAFILE1 in $EXT_LIST
         do
           mv ${STAGE02DIR}/$DATAFILE1 ${EMAIL_DATADIR}
           check_status
         done
       check_status

  rcr_record_cnt=`sqlplus -s $ORA_CONNECT << END_OF_SQL
          SET HEAD OFF
          SET PAGESIZE 0
          SET FEEDBACK OFF
          SET TRIMOUT ON
          SELECT COUNT(1) FROM STAGE.RCR_CUSTOMER_EMAIL@$BASECAMP_DB_LINK \
          WHERE  meta_curr_ind='Y' \
          AND TRUNC(meta_load_tmstmp) > TO_DATE('$mkdmemail_run_date','DD-MON-YYYY');
          EXIT
          END_OF_SQL`
  check_status
  echo "Basecamp table delta count=$rcr_record_cnt"

  cd $EMAIL_DATADIR 
  file_count=`ls *.dat  *.txt | wc -l`
  echo "No. of files present=$file_count"

  if [ $file_count -eq 0 ] && [ $rcr_record_cnt = 0 ]; then
    echo "*************************"
    echo "No email files & No new records in basecamp to process"
    echo "*************************"
    exit 0;
    else
       OPTIN_data=`ls $EMAIL_DATADIR/OPTIN*.dat`
       OPTOUT_data=`ls $EMAIL_DATADIR/OPTOUT*????-??-??.dat`
       RES_OPTOUT_data=`ls $EMAIL_DATADIR/RES_OPTOUT*.dat`
       PREFERENCES_ACXIOM_data=`ls $EMAIL_DATADIR/PREFERENCES_ACXIOM_????????.dat`
       PREFERENCES_ACXIOM_BTNCC_data=`ls $EMAIL_DATADIR/PREFERENCES_ACXIOM_BTNCC_????????.dat`
  fi
fi

#-----------------------------------------------------------------
step_number=2
#Description: Truncates the staging tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_trunc_email_load_stg_tbls.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Sqlload files to the staging tables
#-----------------------------------------------------------------
echo "Executing Step: $step_number"
if [ $start_step -le  $step_number ] ; then

      tot_email_ids_loaded=0
      data_rej_rows=0
      tot_empty_btn=0
      tot_empty_emailid=0

      for OPTDATA1 in ${OPTIN_data}
       do
         echo "OPTIN_data in OPTDATA1= $OPTDATA1"

         strings -a $OPTDATA1 > temp.txt
         check_status
         mv temp.txt $OPTDATA1
         check_status

         sqlldr ${ORA_CONNECT_MKDM} control=${OPTIN_ctl} log=${OPTIN_log} \
         bad=${OPTIN_bad} data=$OPTDATA1 discard=${OPTIN_dis} errors=100 DIRECT=TRUE

         typeset -i err=`grep 'due to data errors.' ${OPTIN_log} | awk -F' ' '{ print $1 }'`
         [ $err -lt 100 ] || check_status

         suc_rows=`grep 'successfully loaded.' $OPTIN_log | awk -F' ' '{ print $1 }'`
         rej_rows=`grep 'not loaded due to data errors.' $OPTIN_log | awk -F' ' '{ print $1 }'`
         tot_email_ids_loaded=`expr ${tot_email_ids_loaded} + ${suc_rows}`
         data_rej_rows=`expr ${data_rej_rows} + ${rej_rows}`

         emp_btn=`grep 'not loaded because all WHEN clauses were failed.' $OPTIN_log | awk -F' ' '{ print $1 }'`
         tot_empty_btn=`expr ${tot_empty_btn} + ${emp_btn}`
       done

      for OPTDATA2 in ${OPTOUT_data}
       do
         echo "OPTOUT_data in OPTDATA2= $OPTDATA2"

         strings -a $OPTDATA2 > temp.txt
         check_status
         mv temp.txt $OPTDATA2
         check_status

         sqlldr ${ORA_CONNECT_MKDM} control=${OPTOUT_ctl} log=${OPTOUT_log} \
         bad=${OPTOUT_bad} data=$OPTDATA2 discard=${OPTOUT_dis} errors=100 DIRECT=TRUE 

         typeset -i err=`grep 'due to data errors.' ${OPTOUT_log} | awk -F' ' '{ print $1 }'`
         [ $err -lt 100 ] || check_status

         suc_rows=`grep 'successfully loaded.' $OPTOUT_log | awk -F' ' '{ print $1 }'`
         rej_rows=`grep 'not loaded due to data errors.' $OPTOUT_log | awk -F' ' '{ print $1 }'`
         tot_email_ids_loaded=`expr ${tot_email_ids_loaded} + ${suc_rows}`
         data_rej_rows=`expr ${data_rej_rows} + ${rej_rows}`

         emp_email=`grep 'not loaded because all WHEN clauses were failed.' $OPTOUT_log | awk -F' ' '{ print $1 }'`
         tot_empty_emailid=`expr ${tot_empty_emailid} + ${emp_email}`
      done

      for OPTDATA4 in ${RES_OPTOUT_data}
       do
         echo "RES_OPTOUT_data in OPTDATA4 = $OPTDATA4"

         strings -a $OPTDATA4 > temp.txt
         check_status
         mv temp.txt $OPTDATA4
         check_status

         sqlldr ${ORA_CONNECT_MKDM} control=${RES_OPTOUT_ctl} log=${RES_OPTOUT_log} \
         bad=${RES_OPTOUT_bad} data=${OPTDATA4} discard=${RES_OPTOUT_dis} errors=100 DIRECT=TRUE

         typeset -i err=`grep 'due to data errors.' ${RES_OPTOUT_log} | awk -F' ' '{ print $1 }'`
         [ $err -lt 100 ] || check_status

         suc_rows=`grep 'successfully loaded.' $RES_OPTOUT_log | awk -F' ' '{ print $1 }'`
         rej_rows=`grep 'not loaded due to data errors.' $RES_OPTOUT_log | awk -F' ' '{ print $1 }'`
         tot_email_ids_loaded=`expr ${tot_email_ids_loaded} + ${suc_rows}`
         data_rej_rows=`expr ${data_rej_rows} + ${rej_rows}`

         emp_email=`grep 'not loaded because all WHEN clauses were failed.' $RES_OPTOUT_log | awk -F' ' '{ print $1 }'`
         tot_empty_emailid=`expr ${tot_empty_emailid} + ${emp_email}`
       done

      for OPTDATA8 in ${PREFERENCES_ACXIOM_data}
       do
         echo "PREFERENCES_ACXIOM_data in OPTDATA8= $OPTDATA8"

         strings -a $OPTDATA8 > temp.txt
         check_status
         mv temp.txt $OPTDATA8
         check_status

         sqlldr ${ORA_CONNECT_MKDM} control=${PREFERENCES_ACXIOM_ctl} log=${PREFERENCES_ACXIOM_log} \
         bad=${PREFERENCES_ACXIOM_bad} data=${OPTDATA8} discard=${PREFERENCES_ACXIOM_dis} errors=100 DIRECT=TRUE SKIP=0

         typeset -i err=`grep 'due to data errors.' ${PREFERENCES_ACXIOM_log} | awk -F' ' '{ print $1 }'`
         [ $err -lt 100 ] || check_status

         suc_rows=`grep 'successfully loaded.' $PREFERENCES_ACXIOM_log | awk -F' ' '{ print $1 }'`
         rej_rows=`grep 'not loaded due to data errors.' $PREFERENCES_ACXIOM_log | awk -F' ' '{ print $1 }'`
         tot_email_ids_loaded=`expr ${tot_email_ids_loaded} + ${suc_rows}`
         data_rej_rows=`expr ${data_rej_rows} + ${rej_rows}`

         emp_email=`grep 'not loaded because all WHEN clauses were failed.' $PREFERENCES_ACXIOM_log | awk -F' ' '{ print $1 }'`
         tot_empty_emailid=`expr ${tot_empty_emailid} + ${emp_email}`
       done

       for OPTDATA9 in ${PREFERENCES_ACXIOM_BTNCC_data}
       do
         echo "PREFERENCES_ACXIOM_BTNCC_data in OPTDATA9= $OPTDATA9"

         strings -a $OPTDATA9 > temp.txt
         check_status
         mv temp.txt $OPTDATA9
         check_status

         sqlldr ${ORA_CONNECT_MKDM} control=${PREFERENCES_ACXIOM_BTNCC_ctl} log=${PREFERENCES_ACXIOM_BTNCC_log} \
         bad=${PREFERENCES_ACXIOM_BTNCC_bad} data=${OPTDATA9} discard=${PREFERENCES_ACXIOM_BTNCC_dis} errors=100 DIRECT=TRUE SKIP=0

         typeset -i err=`grep 'due to data errors.' ${PREFERENCES_ACXIOM_BTNCC_log} | awk -F' ' '{ print $1 }'`
         [ $err -lt 100 ] || check_status

         suc_rows=`grep 'successfully loaded.' $PREFERENCES_ACXIOM_BTNCC_log | awk -F' ' '{ print $1 }'`
         rej_rows=`grep 'not loaded due to data errors.' $PREFERENCES_ACXIOM_BTNCC_log | awk -F' ' '{ print $1 }'`
         tot_email_ids_loaded=`expr ${tot_email_ids_loaded} + ${suc_rows}`
         data_rej_rows=`expr ${data_rej_rows} + ${rej_rows}`

         emp_email=`grep 'not loaded because all WHEN clauses were failed.' $PREFERENCES_ACXIOM_BTNCC_log | awk -F' ' '{ print $1 }'`
         tot_empty_emailid=`expr ${tot_empty_emailid} + ${emp_email}`
       done

       echo $tot_email_ids_loaded > ${LOGDIR}/tot_email_ids_loaded.log
       echo $data_rej_rows        > ${LOGDIR}/data_rej_rows.log
       echo $tot_empty_btn        > ${LOGDIR}/tot_empty_btn.log
       echo $tot_empty_emailid    > ${LOGDIR}/tot_empty_emailid.log

fi

#-----------------------------------------------------------------
step_number=4
#Description: Load email_load_rcr_stg from STAGE.RCR_CUSTOMER_EMAIL table in Basecamp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_load_rcr_stg.sql $BASECAMP_DB_LINK $mkdmemail_run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Create email_campaign_stg with data from RCR and EXT stage tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_campaign_stg.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Create EMAIL_CAMP_TEMP with BTN, CUST_CD, Domain details & pref indrs
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_camp_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Create temp table EMAIL_CAMP_TEMP2 with only valid email addr
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_camp_temp1_valid.sql
   check_status
fi


#-----------------------------------------------------------------
step_number=8
#Description: Run common function to check for duplicates on
#              email_camp_temp2 before dedupe process
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   check_dedup DUP_COUNT_VAR emlcamp101
   check_status
fi

#-----------------------------------------------------------------
step_number=9 
#Description: Dedup on EMAIL_CAMP_TEMP2
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_dedup_email_camp_temp2.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: Run common functionto check for duplicates on
#              email_camp_temp2 after dedupe process
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   check_dedup DUP_COUNT_VAR emlcamp101
   check_status
fi

#-----------------------------------------------------------------
step_number=11
##Description: Create table EMAIL_CAMPAIGN_TEMP with unique email_addr_id
#              deduping based on source_file_cd and opt_out_flag
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_camp_temp2_dedup.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description: Create CSBAN_TEMP table to populate ACCT_ID based on BTN
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_camp_csban_temp.sql ${BASE2_DB_LINK}
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description: Update account info in Email table from CSBAN
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_upd_acct_id.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description: Create table with records present only in Last week's CUR table 
#             and not present in the data that flowed in this week
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_email_camp_only_in_cur.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=15
#Description: Create table email_campaign_final_tmp with data in
#             email_campaign_temp (Data that we received this week) AND
#             email_camp_only_in_cur(Data received last week but not this week)
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_email_campaign_final_tmp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description: To create index on email_campaign_final_tmp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_email_campaign_final_tmp.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=17
#Description: Move the data that changed between last week and now to HIST
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_campaign_hist.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=18
#Description: Update mktg_pref_ind for this weeks email records 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_camp_upd_mktg_pref_ind.sql
   check_status
fi

#-----------------------------------------------------------------
#step_number=19
#Description: Update invalid_flag and date as received from INVALID files
# INVALID ACXIOM files are being decommissioned
#-----------------------------------------------------------------
#if [ $start_step -le $step_number ] ; then
#   echo "*** Step Number $step_number"
#   run_sql mkdm_email_camp_upd_invalid_records.sql
#   check_status
#fi

#-----------------------------------------------------------------
step_number=20
#Description: Rename email_campaign_final_tmp to email_campaign_cur
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_email_campaign_cur.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=21
#Description: To analyze table email_campaign_cur
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM EMAIL_CAMPAIGN_CUR 5
   check_status
fi

#-----------------------------------------------------------------
step_number=22
#Description: To Create temp table with latest email_campaign_cur records
#             for generating email campaign report.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql email_campaign_cur_optout_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=23
#Description: To create temp table with latest email_campaign_hist records
#             for generating email campaign report.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql email_campaign_hist_optout_temp.sql $data_tablespace
   check_status
fi
#-----------------------------------------------------------------
step_number=24
#Description: Generate the email campaign report.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $LOGDIR
   tot_email_ids_loaded=`cat tot_email_ids_loaded.log`
   tot_empty_btn=`cat tot_empty_btn.log`
   tot_empty_emailid=`cat tot_empty_emailid.log`
   data_rej_rows=`cat data_rej_rows.log`
   
   run_sql mkdm_gen_email_campaign_report.sql $tot_email_ids_loaded $tot_empty_btn $tot_empty_emailid $data_rej_rows
   check_status
fi

#-----------------------------------------------------------------
step_number=25
#Description: Drop temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_email_campaign_temp_tbls.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=26
#Description: Cleanup the email file directories and logs
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

   cd $EMAIL_DATADIR
   tar cvf EMAIL_CAMP_$today.tar *.*
   mv  EMAIL_CAMP_$today.tar archive/
   rm -f RES*
   rm -f OPT*
   rm -f *ACXIOM*
   check_status
   
   cd $LOGDIR
   rm -f tot_email_ids_loaded.log
   check_status
   rm -f tot_empty_btn.log
   check_status
   rm -f tot_empty_emailid.log
   check_status
   rm -f data_rej_rows.log
   check_status
fi

#----------------------------------------------------------------
step_number=27
# Description: Update the MKDMEMAIL_RUN_DATE flex_env variable
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"

     mkdmemail_run_date=`sqlplus -s $ORA_CONNECT << END_OF_SQL
          SET HEAD OFF
          SET PAGESIZE 0
          SET FEEDBACK OFF
          SET TRIMOUT ON
          SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY') FROM DUAL;
          EXIT
          END_OF_SQL`
    check_status
  export ORA_CONNECT=$CONNECT_CRDM
  upd_crdm_flex_env MKDMEMAIL_RUN_DATE $mkdmemail_run_date
  check_status
  export ORA_CONNECT=$ORA_CONNECT_MKDM
fi

#-----------------------------------------------------------------
step_number=28
# Description: send_mail common function is called for successfull
# completion and email notification.
#-----------------------------------------------------------------
success_msg=`cat $OUTDIR/email_campaign_report.txt`
subject_msg="email_campaign_cur loaded successfully"
send_mail "$success_msg" "$subject_msg" "$EMAILREP_MAIL_LIST"
check_status

exit 0
