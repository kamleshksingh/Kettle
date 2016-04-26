#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_content_rev_sum_weekly.ksh
#**
#** Job Name        :  CTNEVTSUMM
#**
#** Original Author :  mmuruga
#**
#** Description     :  This weekly Job Pulls CONTENT summary details.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 01/24/2008 mmuruga  Initial checkin.
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
get_mkdm_job_control CTNEVTSUMM last_run_date
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


check_variables start_step ORA_CONNECT CONNECT_BDM CONNECT_CRDM MKDM_DB_LINK
check_variables data_tablespace index_tablespace last_run_date

#-----------------------------------------------------------------
step_number=1
#Description:   Create Temporary table CCD_WEEK_EVT_TEMP
#               from conrent_event_detail which contains Last week's data
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_content_cur_week_evt_tmp.sql $data_tablespace $last_run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Create index for CCD_WEEK_EVT_TEMP table
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_content_crt_idx_ccd_week_evt.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:   Analyze CCD_WEEK_EVT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  analyze_table MKDM CCD_WEEK_EVT_TEMP 5
  check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description:   Create log table content_datamo_log
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_content_crt_data_months_log.sql
   check_status
fi

export ORA_CONNECT=$TEMP_ORA_CONNECT

run_sql mkdm_content_spool_data_mo.sql $HOME/ctn_data_mo.txt
check_status

for DATA_MO in `cat $HOME/ctn_data_mo.txt`
do
    #-----------------------------------------------------------------
    step_number=5
    #Description:   Creates a temporary table to hold
    #               current week's roll up data.
    #
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ]; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_rev_sum_temp.sql $data_tablespace $DATA_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=6
    #Description:Create Index for ctn_bus_sum_tmp table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_content_idx_sum_tmp.sql $index_tablespace
        check_status
    fi
    #-----------------------------------------------------------------
    step_number=7
    #Description:   Analyze ctn_bus_sum_tmp Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_BUS_SUM_TMP 5
       check_status
    fi


    #-----------------------------------------------------------------
    step_number=8
    #Description:Create current month's roll up content information
    #            with additional icontent information present for the
    #            current month. 
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_cur_months_data.sql $DATA_MO $data_tablespace 
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=9
    #Description:Create Index for CTN_BUS_SUM_TMP1 table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_content_crt_idx_cur_sum_tmp.sql $index_tablespace
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=10
    #Description:   Analyze CTN_BUS_SUM_TMP1 Table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_BUS_SUM_TMP1 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=11
    #Description: Create a temporary table to hold three months revenue
    #            Current Info from CTN_BUS_SUM_TMP1 and Prior
    #            2 Months from content_event_detail 
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_three_mon_data.sql $DATA_MO $data_tablespace 
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=12
    #Description: Create Index for cont_bus_three_months_rev table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
        echo "*** Step Number $step_number"
        run_sql mkdm_content_crt_idx_three_mon_data.sql $index_tablespace
        check_status
    fi

    #-----------------------------------------------------------------
    step_number=13
    #Description: Create a table for 3 Months sum
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_sum_three_mon_data.sql $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=14
    #Description: Analyze ctn_bus_avg_temp table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_THREE_MON_SUM 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=15
    #Description: Create a table for 12 Months data
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_twelve_mon_data.sql $DATA_MO $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=16
    #Description: Analyze cont_bus_twelve_months_rev table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CONT_BUS_TWELVE_MONTHS_REV 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=17
    #Description: Create a table for 12 Months sum
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_sum_twelve_mon_data.sql $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=18
    #Description: Analyze cont_bus_twelve_months_rev table
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_TWELVE_MON_SUM 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=19
    #Description: Create a temporary table to hold current month as well as
    #             Three month average revenue for each account.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_crt_consol_data.sql $DATA_MO $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=20
    #Description: Analyze CTN_BUS_SUM_WKLY_TEMP table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_BUS_SUM_WKLY_TEMP 5
       check_status
    fi
    
    #-----------------------------------------------------------------
    step_number=21
    #Description: Load data from previous partition.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_load_prev_data.sql $data_tablespace $DATA_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=22
    #Description: Analyze ctn_bus_sum_full_temp table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_BUS_SUM_FULL_TEMP 5
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=23
    #Description: Insert the missing records from previous partition. 
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_ins_prev_data.sql
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=24
    #Description: Analyze CTN_BUS_SUM_WKLY_TEMP table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM CTN_BUS_SUM_WKLY_TEMP 5
       check_status
    fi

    export TBL=CTN_EVT_SUM_LOAD_$DATA_MO

    #-----------------------------------------------------------------
    step_number=25

    #Description: Creates temp table in MKDM for EXCHANGE PARTITION 
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_evt_sum_load.sql $TBL $data_tablespace
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=26
    #Description: Populates account_type from stg_Account_cris table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_acct_typ_data.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=27
    #Description: Analyze CTN_EVT_SUM_LOAD table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       analyze_table MKDM $TBL 5
       check_status
    fi
    
    #-----------------------------------------------------------------
    step_number=28
    #Description: Exchange data of revenue summary weekly temp table with
    #             the corresponding partition of CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_exch_part_rev_summary.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=29
    #Description: Rebuild unusable indexes of CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_rebuild_unusable_idx_sum.sql $TBL
       check_status
    fi

export ORA_CONNECT=$CONNECT_BDM
    #-----------------------------------------------------------------
    step_number=30
    #Description: CREATE temp table in BDM database
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_evt_sum_load.sql $TBL BDM_CONS 
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=31 
    #Description: Prepares temp table for EXCHANGE PARTITION
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       MKDM_DB_LINK=to_mkdm
       run_sql mkdm_content_bdm_crt_event_sum_tbl.sql $TBL $MKDM_DB_LINK $DATA_MO
       check_status
    fi
    
    #-----------------------------------------------------------------
    step_number=32
    #Description: Exchange data of revenue summary weekly temp table with
    #             the corresponding partition of CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_exch_part_rev_summary.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=33
    #Description: Rebuild unusable indexes of CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_rebuild_unusable_idx_sum.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=34
    #Description: Drop the temp table in BDM.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_drp_temp_tbl.sql $TBL
       check_status
    fi

export ORA_CONNECT=$CONNECT_CRDM
     #-----------------------------------------------------------------
    step_number=35
    #Description: CREATE temp table in CRDM database
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_evt_sum_load.sql $TBL CRDM_L_DATA 
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=36
    #Description: Prepare TEMP table for EXCHANGE PARTITION
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       MKDM_DB_LINK=mkdm
       run_sql mkdm_content_crdm_crt_event_sum_tbl.sql $TBL $MKDM_DB_LINK $DATA_MO
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=37
    #Description: Exchange data of summary temp table with the corresponding
    #             partition of CONSUMER_CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_exch_part_rev_summary.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=38
    #Description:Rebuild indexes in CONSUMER_CONTENT_EVENT_SUMM table.
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_rebuild_unusable_idx_sum.sql $TBL
       check_status
    fi
  
    #-----------------------------------------------------------------
    step_number=39
    #Description: Drop the temp table in CRDM
    #-----------------------------------------------------------------
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_drp_temp_tbl.sql $TBL
       check_status
    fi

    #-----------------------------------------------------------------
    step_number=40
    #Description: Drop revenue summary weekly temp table in MKDM.
    #-----------------------------------------------------------------
    export ORA_CONNECT=$TEMP_ORA_CONNECT
    if [ $start_step -le $step_number ] ; then
       echo "*** Step Number $step_number"
       run_sql mkdm_content_drop_sum_temp_tbl.sql $DATA_MO
       check_status
    fi

    done

export ORA_CONNECT=$TEMP_ORA_CONNECT

#-----------------------------------------------------------------
step_number=41
#Description:   Drop temporary tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_content_drp_temp_tbl.sql CCD_WEEK_EVT_TEMP
   check_status
fi

#-----------------------------------------------------------------
step_number=42
#Description:   Update last_run_date in mkdm_job_control.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   upd_mkdm_job_control CTNEVTSUMM
   check_status
fi

#-----------------------------------------------------------------
step_number=43
#Description:   Delete the temporary file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rm -f $HOME/ctn_data_mo.txt
   check_status
fi

#-----------------------------------------------------------------
step_number=44
#Description:  Send Mail When the Job completes successfully
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   success_msg="CONTENT_EVENT_SUMM table loaded successfully"
   subject_msg="CONTENT_EVENT_SUMM table loaded successfully"
   send_mail "$success_msg" "$subject_msg" "$BDM_WKLY_MAIL_LIST"
   check_status
fi

exit 0
