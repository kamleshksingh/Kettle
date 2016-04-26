#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_cons_rev_sum_weekly.sh
#**
#** Job Name        :  CONREVSUM
#**
#** Original Author :  PANBALA
#**
#** Description     :  This weekly Job Pulls current month and 3 Month average revenue
#**                    from CONSUMER_REVENUE_DET to CONS_REV_SUM_WKLY_TEMP_YYYYMM
#**                    which will be used to populate CONSUMER_REVENUE_SUMM in CRDM
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 07/27/2006 panbala  Initial checkin.
#** 08/22/2006 panbala  Added loading process of CONSUMER_REVENUE_SUMM table.
#** 09/07/2006 urajend  Changes for creating CONSUMER_REVENUE_SUMM_CUR as a physical table.
#** 03/22/2007 rananto  Performance tuning - Usage of partitions at CRDM side
#** 05/17/2007 urajend  Changes for Revenue average calculation.
#** 09/27/2007 mmuruga  Changed tablespace name from CRDM_L_DATA to REVENUE_DATA
#*****************************************************************************

#test hook
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguments may be adjusted according to the needs of
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
get_mkdm_job_control CONREVSUM last_run_date
TEMP_ORA_CONNECT=$ORA_CONNECT

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


check_variables start_step ORA_CONNECT CONNECT_CRDM MKDM_DB_LINK
check_variables data_tablespace index_tablespace CRDM_DB_LINK last_run_date

#-----------------------------------------------------------------
step_number=1
#Description:   Create Temporary table cur_week_dtl_temp
#               from consumer_rev_dtl which contains Last week's data
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_cur_week_dtl_temp.sql $data_tablespace $last_run_date
   check_status
fi


#-----------------------------------------------------------------
step_number=2
#Description: Create index for cur_week_dtl_temp table
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_consumer_revenue_det.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:   Analyze cur_week_dtl_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  analyze_table MKDM CUR_WEEK_DTL_TEMP 5
  check_status
fi


#-----------------------------------------------------------------
step_number=4
#Description:   Create log table mkdm_data_months_log
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_data_months_log.sql
   check_status
fi

run_sql mkdm_spool_data_mo.sql $HOME/data_mo.txt
check_status

for DATA_MO in `cat $HOME/data_mo.txt`
do
    #-----------------------------------------------------------------
    step_number=5
    #Description: Create table to hold monthly data for accounts 
    #             received this week in cur_week_dtl_temp
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_con_rev_dtl_temp.sql $data_tablespace $DATA_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=6
    #Description: Create index on con_rev_monthly_dtl_temp
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_con_rev_dtl_temp_idx.sql $index_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=7
    #Description: Analyze con_rev_monthly_dtl_temp table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
      echo "*** Step Number $step_number"
      analyze_table MKDM CON_REV_MONTHLY_DTL_TEMP 5
      check_status
    fi

    #-----------------------------------------------------------------
    step_number=8
    #Description:   Create a table to hold LD Bundle Products
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_temp_bundle_prod_cd_acct.sql $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=9
    #Description:   Create Index on mkdm_crt_idx_temp_bundle_prod_cd_acct
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_idx_temp_bundle_prod_cd_acct.sql $index_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=10
    #Description:   Analyze TEMP_BUNDLE_PROD_CD_ACCT table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM temp_bundle_prod_cd_acct 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=11
    #Description:   Create a table to hold Bundle Products other than LD
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_temp_bundle_usoc_acct.sql $data_tablespace
       check_status
    fi
   
    #-----------------------------------------------------------------
    step_number=12
    #Description:   Create Index on temp_bundle_usoc_acct
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_idx_temp_bundle_usoc_acct.sql $index_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=13
    #Description:   Analyze TEMP_BUNDLE_USOC_ACCT table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM TEMP_BUNDLE_USOC_ACCT 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=14
    #Description:   Creates histogram pool table which loads data
    #               like no of jobs and intervals between
    #               which we take the records for Processing
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql histogram_pool_for_hjobs_temp.sql 10
       check_status
       run_sql mkdm_spool_no_jobs.sql $HOME/job_no.txt
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=15
    #Description:   Creates a temporary table to hold
    #               current week's roll up data.
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_consumer_rev_sum_temp.sql $data_tablespace $DATA_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=16
    #Description:   Creates 10 temp tables, to avoid Temp space problems.
    #               And inserts into temp table to have current week's
    #               Roll Up revenue
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       num_of_hjobs=`cat $HOME/job_no.txt`
       job_id=1

       while [ $job_id -le $num_of_hjobs ]
       do
         cd $DATADIR
         run_sql mkdm_crt_current_month_data.sql $data_tablespace $DATA_MO $job_id
         check_status
         run_sql mkdm_ins_current_month_data.sql $job_id
         check_status
         job_id=`expr ${job_id} + 1`
         check_status
       done

    fi

    #-----------------------------------------------------------------
    step_number=17
    #Description:Create Index for consumer_rev_sum_temp1 table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_crt_idx_consumer_rev_sum_temp1.sql $index_tablespace
        check_status
    fi
    #-----------------------------------------------------------------
    step_number=18
    #Description:   Analyze consumer_rev_sum_temp1 Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CONSUMER_REV_SUM_TEMP1 5
       check_status
    fi


    export ORA_CONNECT=$CONNECT_CRDM
    TBL=CONS_REV_SUM_WKLY_TEMP_${DATA_MO}

    #-----------------------------------------------------------------
    step_number=19
    #Description:Create table in crdm with current month's revenue information
    #           
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_crt_rev_sum_temp.sql P${DATA_MO} REVENUE_DATA $MKDM_DB_LINK
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=20
    #Description: Create REV_SUM_WKLY_TEMP with the existing records not
    #             existing in the current week pull.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_crt_rev_sum_wkly_temp.sql $TBL REVENUE_DATA
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=21
    #Description: Insert the existing records not existing in the current
    #             week pull into CONSUMER_REV_SUM_TEMP2.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_ins_con_rev_sum_temp2.sql
       check_status
    fi    

    #-----------------------------------------------------------------
    step_number=22
    #Description:Create Index for consumer_rev_sum_temp2 table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_crt_idx_consumer_rev_sum_temp2.sql CRDM_L_IDX
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=23
    #Description:   Analyze consumer_rev_sum_temp2 Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table CRDM CONSUMER_REV_SUM_TEMP2 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=24
    #Description: Create a temporary table to hold three months revenue
    #            Current Info from consumer_rev_sum_temp2 and Prior
    #            2 Months from consumer_revenue_summ
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_three_months_data.sql $DATA_MO REVENUE_DATA
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=25
    #Description: Create Index for consumer_three_months_rev table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_crt_idx_consumer_three_months_rev.sql CRDM_L_IDX
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=26
    #Description: Create a table for 3 Months average revenue
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_three_month_avg.sql REVENUE_DATA
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=27
    #Description: Analyze cons_rev_avg_temp table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table CRDM CONS_REV_AVG_TEMP 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=28
    #Description: Create a temporary table to hold current month as well as
    #             Three month average revenue for each account.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crt_consol_data.sql ${TBL}1 REVENUE_DATA
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=29
    #Description: Analyze cons_rev_sum_wkly_temp_yyyymm table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table CRDM ${TBL}1 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=30
    #Description: Drop temporary tables created monthly
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_drop_monthly_temp_tbls.sql
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=31
    #Description: Create the revenue summary weekly temp table structure
    #             from CONSUMER_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_crt_cons_rev_sum_wkly_summ.sql $TBL REVENUE_DATA
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=32
    #Description: Insert records into revenue summary weekly temp table
    #             from revenue summary weekly temp table in MKDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_insert_cons_rev_sum_wkly_temp.sql $TBL ${TBL}1
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=33
    #Description: Exchange data of revenue summary weekly temp table with
    #             the corresponding partition of CONSUMER_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_exch_part_rev_summary.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=34
    #Description: Rebuild unusable indexes of CONSUMER_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_rebuild_unusable_idx_con_rev_sum.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=35
    #Description: Drop revenue summary weekly temp tables in CRDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_crdm_mkdm_drop_rev_sum_temp_tbl.sql $TBL ${TBL}1
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=36
    #Description: Drop revenue summary weekly temp table in MKDM.
    #-----------------------------------------------------------------
    export ORA_CONNECT=$TEMP_ORA_CONNECT
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_drop_rev_sum_temp_tbl.sql $DATA_MO
       check_status
    fi

    start_step=5
done

export ORA_CONNECT=$CONNECT_CRDM

#-----------------------------------------------------------------
step_number=37
#Description: Create consumer_revenue_summ_temp table in CRDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql crdm_crt_con_rev_sum_temp.sql
       check_status
fi

#-----------------------------------------------------------------
step_number=38
#Description: Drop the table consumer_revenue_summ_cur in CRDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql crdm_drp_con_rev_sum_cur.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=39
#Description: Rename the table consumer_revenue_summ_temp to consumer_revenue_summ_cur CRDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql crdm_rename_con_rev_sum_temp_cur.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=40
#Description: Create the index on consumer_revenue_summ_cur in CRDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql crdm_crt_idx_con_rev_sum_cur.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=41
#Description: Analyze the table consumer_revenue_summ_cur in CRDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table CRDM CONSUMER_REVENUE_SUMM_CUR 5
   check_status
fi

export ORA_CONNECT=$TEMP_ORA_CONNECT

#-----------------------------------------------------------------
step_number=42
#Description:   Drop temporary tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drop_temp_tbls.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=43
#Description:   Update last_run_date in mkdm_job_control.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   upd_mkdm_job_control CONREVSUM
   check_status
fi
#-----------------------------------------------------------------
step_number=44
#Description:   Delete the temporary file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rm -f $HOME/data_mo.txt
   rm -f $HOME/job_no.txt
   check_status
fi

#-----------------------------------------------------------------
step_number=45
#Description:  Send Mail When the Job completes successfully
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   success_msg="CONSUMER_REVENUE_SUMM table loaded successfully"
   subject_msg="CONSUMER_REVENUE_SUMM table loaded successfully"
   send_mail "$success_msg" "$subject_msg" "$CRDM_WKLY_MAIL_LIST"
   check_status
fi

exit 0
