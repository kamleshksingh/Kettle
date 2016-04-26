#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_rib_rev_det.sh
#**
#** Job Name        :  LDRIBREV
#**
#** Original Author :  mmuruga
#**
#** Description     :  Loads RIB details into revenue table
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 08/24/2006 mmuruga  Initial Checkin
#** 08/18/2006 vxragun  Acct_id patch added to populate acct_id/acct_seq_no
#** 22/02/2007 mmuruga  Added to load RIB data into Business_revenue_dtl table.
#** 11/06/2007 ddamoda	Added steps to load data into history table. 
#** 05/29/2008 ssagili  Added steps to load data into mkdm_revenue_det table.
#** 06/20/2011 jbansal  Modify the grep command , in order to handle binary files
#*****************************************************************************

#test hook
#. ~/.setup_env
#$FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

function sql_ld_score
{
   sqlldr userid=$ORA_CONNECT \
   errors=0 \
   control=$TEMP_CTLFILE \
   log=$LOGDIR/$1_sqlld.$$.log \
   DIRECT=TRUE  \
   ROWS=100000 \
   bad=${LOGDIR}/$1_sqlld.$$.bad \
   discard=${LOGDIR}/$1_sqlld.$$.dis \
   data=${FINEDW_IN_STG_DIR}/$1 \
   skip_index_maintenance=false

   ROWS_LOADED=`grep 'Rows successfully loaded' $LOGDIR/$1_sqlld.$$.log | awk 'NR==1 {print $1}'`
   check_status
   ROWS_FOUND=`grep -a $rec_id ${FINEDW_IN_STG_DIR}/$1|wc -l`
   check_status

   print " Rows Found = $ROWS_FOUND \n Rows Loaded = $ROWS_LOADED"
   check_status

   if [ $ROWS_LOADED -ne $ROWS_FOUND ]; then
   exit 1
   fi

   check_status
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
CTLFILE=$CTLDIR/mkdm_ld_rib_rev.ctl
export TEMP_CTLFILE=$OUTDIR/mkdm_ld_rib_rev_tmp.ctl

echo "creating a temp ctl file for the loading .."
export rec_id=495101
CMD1=`print "sed s/&1/$rec_id/g"`
cat $CTLFILE | $CMD1 > $TEMP_CTLFILE
echo "created temp ctl file"

#-----------------------------------------------------------------
# Function to check the return status and set the appropriate
# message
#-----------------------------------------------------------------

function check_status
{
  if [ $? -ne 0 ]; then
     if [ $# -eq 2 ]; then
        if [ "$2" = "2" ]; then
           print $1
           err_msg="$1"
           subject_msg="Job Error - $L_SCRIPTNAME"
           echo "Process failed at the Step:  $step_number"
           send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
           exit $step_number
        fi
     else
     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     subject_msg="Job Error - $L_SCRIPTNAME"
     echo "Process failed at the Step:  $step_number"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
     exit $step_number
  fi
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

check_variables start_step ORA_CONNECT MKDM_ERR_LIST FINEDW_IN_STG_DIR
check_variables FINEDW_RIB_DIR FINEDW_IN_ARC_DIR
#-----------------------------------------------------------------
step_number=1
#Description:  MV RIB files into $FINEDW_IN_STG_DIR
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $FINEDW_RIB_DIR
   check_status
   RIB_LIST=`ls RIB_DTV_*`
   check_status 'No RIB_DTV_* files in FTP Directory' "$?"
   for RIBFILE in $RIB_LIST
   do
   mv $RIBFILE $FINEDW_IN_STG_DIR/$RIBFILE.dat
   check_status
   done
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: DROP & Create the table finedw_rib_stg.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_tbl_finedw_nq_stg.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Load multiple RIB files in to stg table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $FINEDW_IN_STG_DIR
   check_status
   RIB_LIST=`ls RIB_DTV_*`
   check_status 'No RIB_DTV_* files' "$?"
   for RIBFILE in $RIB_LIST
   do
     sql_ld_score ${RIBFILE}
     check_status

     #Move the RIB file to Archive Directory
     mv -f $FINEDW_IN_STG_DIR/${RIBFILE} ${FINEDW_IN_ARC_DIR}/${RIBFILE}.$$
     check_status

   done
   check_status

   rm -f $TEMP_CTLFILE
fi

#-----------------------------------------------------------------
step_number=4
#Description: Create index for FINEDW_RIB_STG table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_finedw_rib_stg.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Analyze FINEDW_RIB_STG table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM FINEDW_RIB_STG 5
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Loads the data into history table RIB_DTV_VIDEO_REV
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_rib_dtv_video_rev.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Analyze RIB_DTV_VIDEO_REV table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM RIB_DTV_VIDEO_REV 5
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Extract acct_id,acct_seq_no and btn into ACCT_BTN_REF_CURRENT_TEMP
#             table from ACCOUNT_KEY_REF table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_btn_ref_current_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Create index for ACCT_BTN_REF_CURRENT_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_btn_ref_current_temp.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Analyze ACCT_BTN_REF_CURRENT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM ACCT_BTN_REF_CURRENT_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Loads data into CONSUMER_REVENUE_DET from stg table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rib_rev_sum_ins.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description: Analyze table CONSUMER_REVENUE_DET.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM CONSUMER_REVENUE_DET 5
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description: Extract acct_id,acct_seq_no and btn into BLG_BTN_REF_CURRENT_TEMP
#             table from ACCOUNT_KEY_REF table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_blg_btn_ref_current_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=14
# Description: Create index for BLG_BTN_REF_CURRENT_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_blg_btn_ref_current_temp.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=15
# Description: Analyze BLG_BTN_REF_CURRENT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM BLG_BTN_REF_CURRENT_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description: Loads data into BUSINESS_REVENUE_DET from stg table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_bus_rib_rev_sum_ins.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=17
#Description: Analyze table BUSINESS_REVENUE_DET.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM BUSINESS_REVENUE_DET 5
   check_status
fi

#-----------------------------------------------------------------
step_number=18
#Description: Loads data into MKDM_REVENUE_DET from stg table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_rib_rev_det.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=19
#Description: rebuilds unusable indexes on MKDM_REVENUE_DET table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rebuild_unusable_indexes_rev_det.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=20
#Description: Analyze table MKDM_REVENUE_DET.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MKDM_REVENUE_DET 1
   check_status
fi


#-----------------------------------------------------------------
step_number=21
#Description: Remove files older than 60 days.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   find ${FINEDW_IN_ARC_DIR}/RIB_DTV_* -mtime +61 -exec rm -f {}    \;
   check_status
fi

#-----------------------------------------------------------------
step_number=22
#Description: Drop temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rib_drop_temp_tbl.sql
   check_status
fi

exit 0
