#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_bus_rev_sum_weekly.sh
#**
#** Job Name        :  BDMREVSUM
#**
#** Original Author :  mmuruga
#**
#** Description     :  This weekly Job Pulls current month and 3 Month average revenue
#**                    from BUSINESS_REVENUE_DET to BUS_REV_SUM_WKLY_TEMP_YYYYMM
#**                    which will be used to populate BUSINESS_REVENUE_SUMM in BDM
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 01/24/2007 mmuruga  Initial checkin.
#** 04/23/2007 rananto  Performance Tuning
#** 05/17/2007 urajend  Changes for Revenue average calculation.
#** 04/28/2009 sxlank2  added steps to crate BUSINESS_REVENUE_SUMM_LOCN view and
#**                     added CL_ID in BUSINESS_REVENUE_SUMM_CUR table
#*****************************************************************************

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
get_mkdm_job_control BUSREVSUM last_run_date
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


check_variables start_step ORA_CONNECT CONNECT_BDM MKDM_DB_LINK
check_variables data_tablespace index_tablespace BDM_DB_LINK last_run_date

#-----------------------------------------------------------------
step_number=1
#Description:   Create Temporary table bus_week_dtl_temp
#               from business_rev_dtl which contains Last week's data
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_cur_week_dtl_temp.sql $data_tablespace $last_run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Create temporary table bus_week_dtl_latis
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_bus_week_dtl_latis.sql $data_tablespace $last_run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Analyze BUS_WEEK_DTL_LATIS Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm BUS_WEEK_DTL_LATIS 5
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Insert into bus_week_dtl_temp table.
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_ins_cur_week_dtl_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Create index for bus_week_dtl_temp table
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_idx_business_revenue_det.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description:   Analyze bus_week_dtl_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  analyze_table MKDM BUS_WEEK_DTL_TEMP 5
  check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description:   Create log table bdm_data_months_log
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_data_months_log.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description:   Create a table to hold LD Bundle Products
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_tmp_blld_prod_cd_acct.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description:  Create a table to hold latis accounts.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_tmp_blld_prod_cd_latis.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description:   Analyze TMP_BLLD_PROD_CD_LATIS table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  analyze_table MKDM tmp_blld_prod_cd_latis 5
  check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description:   Create Index on bdm_crt_idx_temp_bundle_prod_cd_acct
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql bdm_ins_tmp_blld_prod_cd_acct.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description:   Create Index on bdm_crt_idx_temp_bundle_prod_cd_acct
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql bdm_crt_idx_tmp_blld_prod_cd_acct.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description:   Analyze TMP_BLLD_PROD_CD_ACCT table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  analyze_table MKDM tmp_blld_prod_cd_acct 5
  check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description:   Create a table to hold Bundle Products other than LD
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
  echo "*** Step Number $step_number"
  run_sql bdm_crt_tmp_blld_usoc_acct.sql $data_tablespace
  check_status
fi

#-----------------------------------------------------------------
step_number=15
#Description:   Create Index on TMP_BLLD_USOC_ACCT.
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
  echo "*** Step Number $step_number"
  run_sql bdm_crt_idx_tmp_blld_usoc_acct.sql $index_tablespace
  check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description:   Analyze TMP_BLLD_USOC_ACCT table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM TMP_BLLD_USOC_ACCT 5
   check_status
fi
#-----------------------------------------------------------------
step_number=17
#Description: Creates temp table to populate the blg_acct_id from
#             csban and csban_iabs.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_BDM
   run_sql bdm_crt_blg_acct_id_tmp.sql BREV_SUMM_CUR_TS prod_r_link
   check_status
fi

#-----------------------------------------------------------------
step_number=18
#Description: Analyze table blg_csban_btn_tmp.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   export ORA_CONNECT=$CONNECT_BDM
   analyze_table BDM BLG_CSBAN_BTN_TMP 5
   check_status
fi

export ORA_CONNECT=$TEMP_ORA_CONNECT

run_sql bdm_spool_data_mo.sql $HOME/bus_data_mo.txt
check_status

for BILL_MO in `cat $HOME/bus_data_mo.txt`
do
    #-----------------------------------------------------------------
    step_number=19
    #Description:   Creates histogram pool table which loads data
    #               like no of jobs and intervals between
    #               which we take the records for Processing
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql bdm_hist_pool_for_hjobs_temp.sql 10
       check_status
       run_sql bdm_spool_no_jobs.sql $HOME/bus_job_no.txt
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=20
    #Description:   Creates a temporary table to hold
    #               current week's roll up data.
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_business_rev_sum_temp.sql $data_tablespace $BILL_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=21
    #Description:   Creates 10 temp tables, to avoid Temp space problems.
    #               And inserts into temp table to have current week's
    #               Roll Up revenue
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       num_of_hjobs=`cat $HOME/bus_job_no.txt`
       job_id=1

       while [ $job_id -le $num_of_hjobs ]
       do
         cd $DATADIR
         run_sql bdm_crt_current_month_data.sql $data_tablespace $BILL_MO $job_id
         check_status
         run_sql bdm_ins_current_month_data.sql $job_id
         check_status
         job_id=`expr ${job_id} + 1`
         check_status
       done

    fi

    #-----------------------------------------------------------------
    step_number=22
    #Description:Create Index for business_rev_sum_temp1 table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql bdm_crt_idx_business_rev_sum_temp1.sql $index_tablespace
        check_status
    fi
    #-----------------------------------------------------------------
    step_number=23
    #Description:   Analyze business_rev_sum_temp1 Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM BUSINESS_REV_SUM_TEMP1 5
       check_status
    fi

    export ORA_CONNECT=$CONNECT_BDM
    TBL=BUS_REV_SUM_WKLY_TEMP_${BILL_MO}
    export MKDM_DB_LINK=to_mkdm

    #-----------------------------------------------------------------
    step_number=24
    #Description:Create current month's roll up revenue information
    #            with additional revenue information present for the
    #            current month from business_revenue_summ
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_cur_months_data.sql P${BILL_MO} BDM_CONS $MKDM_DB_LINK
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=25
    #Description: Insert the existing records not existing in the current
    #             week pull into REV_SUM_WKLY_TEMP table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_crt_rev_sum_wkly_temp.sql $TBL BDM_CONS
       check_status
    fi    

    #-----------------------------------------------------------------
    step_number=26
    #Description: Insert the existing records not existing in the current
    #             week pull into consumer_three_months_rev.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_ins_bus_rev_sum_temp2.sql
       check_status
    fi
    
    #-----------------------------------------------------------------
    step_number=27
    #Description:Create Index for business_rev_sum_temp2 table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql bdm_crt_idx_business_rev_sum_temp2.sql BDM_CONS
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=28
    #Description:   Analyze business_rev_sum_temp2 Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table BDM BUSINESS_REV_SUM_TEMP2 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=29
    #Description: Create a temporary table to hold three months revenue
    #            Current Info from business_rev_sum_temp2 and Prior
    #            2 Months from business_revenue_summ
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_three_months_data.sql $BILL_MO BDM_CONS
       check_status
    fi
    
    #-----------------------------------------------------------------
    step_number=30
    #Description: Create Index for business_three_months_rev table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql bdm_crt_idx_business_three_months_rev.sql BDM_CONS
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=31
    #Description: Create a table for 3 Months average revenue
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_three_month_avg.sql BDM_CONS
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=32
    #Description: Analyze bus_rev_avg_temp table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table BDM BUS_REV_AVG_TEMP 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=33
    #Description: Create a temporary table to hold current month as well as
    #             Three month average revenue for each account.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_consol_data.sql ${TBL}1 BDM_CONS
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=34
    #Description: Analyze bus_rev_sum_wkly_temp_yyyymm table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table BDM ${TBL}1 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=35
    #Description: Drop temporary tables created monthly
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_drop_monthly_temp_tbls.sql
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=36
    #Description: Create the revenue summary weekly temp table structure
    #             from BUSINESS_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_crt_cons_rev_sum_wkly_summ.sql $TBL BREV_SUMM_CUR_TS
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=37
    #Description: Insert records into revenue summary weekly temp table
    #             from revenue summary weekly temp table in MKDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_insert_cons_rev_sum_wkly_temp.sql $TBL ${TBL}1
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=38
    #Description: Exchange data of revenue summary weekly temp table with
    #             the corresponding partition of BUSINESS_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_exch_part_rev_summary.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=39
    #Description: Rebuild unusable indexes of BUSINESS_REVENUE_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_rebuild_unusable_idx_con_rev_sum.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=40
    #Description: Drop revenue summary weekly temp tables in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_bus_mkdm_drop_rev_sum_temp_tbl.sql $TBL ${TBL}1
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=41
    #Description: Drop revenue summary weekly temp table in MKDM.
    #-----------------------------------------------------------------
    export ORA_CONNECT=$TEMP_ORA_CONNECT
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_drop_rev_sum_temp_tbl.sql $TBL $BILL_MO
       check_status
    fi

    start_step=19
done

export ORA_CONNECT=$CONNECT_BDM

    #-----------------------------------------------------------------
    step_number=42
    #Description: Create business_revenue_summ_temp table in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_bus_rev_sum_temp.sql
       check_status
    fi
    #-----------------------------------------------------------------
    step_number=43
    #Description: Create business_revenue_summ_temp2 table in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_bus_rev_sum_temp2.sql
       check_status
    fi
    #-----------------------------------------------------------------
    step_number=44
    #Description: Drop the table business_revenue_summ_cur in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_drp_bus_rev_sum_cur.sql
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=45
    #Description: Rename the table business_revenue_summ_temp2 to business_revenue_summ_cur BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_rename_bus_rev_sum_temp_cur.sql
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=46
    #Description: Create the index on business_revenue_summ_cur in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_idx_con_rev_sum_cur.sql
       check_status
    fi
    #-----------------------------------------------------------------
    step_number=47
    #Description: Analyze the table business_revenue_summ_cur in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table BDM BUSINESS_REVENUE_SUMM_CUR 5
       check_status
    fi
    #-----------------------------------------------------------------
    step_number=48
    #Description: Create the view on  business_revenue_summ_cur in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql bdm_crt_bus_rev_summ_locn_view.sql
       check_status
    fi
export ORA_CONNECT=$TEMP_ORA_CONNECT

#-----------------------------------------------------------------
step_number=49
#Description: Deletes 10 days older records .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_del_bus_rev_dtl_latis.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=50
#Description:   Drop temporary tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql bdm_drop_temp_tbls.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=51
# Description: Analyze BUSINESS_REV_DET_LATIS Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm BUSINESS_REV_DET_LATIS 5
   check_status
fi

#-----------------------------------------------------------------
step_number=52
#Description:   Update last_run_date in mkdm_job_control.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   upd_mkdm_job_control BUSREVSUM
   check_status
fi
#-----------------------------------------------------------------
step_number=53
#Description:   Delete the temporary file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rm -f $HOME/bus_data_mo.txt
   rm -f $HOME/bus_job_no.txt
   check_status
fi

#-----------------------------------------------------------------
step_number=54
#Description:  Send Mail When the Job completes successfully
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   success_msg="BUSINESS_REVENUE_SUMM table loaded successfully"
   subject_msg="BUSINESS_REVENUE_SUMM table loaded successfully"
   send_mail "$success_msg" "$subject_msg" "$BDM_WKLY_MAIL_LIST"
   check_status
fi

exit 0
