#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_qta_revenue_reports_rerun.sh
#**
#** Job Name        : QTAREVLDRR
#**
#** Original Author : Thrinadh Vamsikrishna.M
#**
#** Description     : Loads Revenue data weekly for QTA 
#**                   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 11/15/2010 txmx  Initial Checkin
#** 04/04/2012 vbeatty  Modified normal job for rerun job
#**                     removed Step 1 crt partition & step 4 drop partitions
#**                       Analyze was modified.
#** 07/05/2013 sxmural  Commented out step 3, as it contains a dblink that does not
#**			exists in production. Further the step need not be automated
#**			for rerun.
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

check_variables start_step ORA_CONNECT data_tablespace index_tablespace

step_number=1
#  NOTE:  Not needed since QTA_REVENUE_DET should already have an
#          existing partition for this data, else will need to create one.
# Description: Add new partition for QTA_REVENUE_DET
#----------------------------------------------------------------
#if [ $start_step -le $step_number ]; then
#   echo "*** Step Number $step_number"
#   run_sql mkdm_add_part_qta_rev_det.sql $data_tablespace
#   check_status
#fi
#----------------------------------------------------------------
step_number=2
# Description:  Insert records into QTA_REVENUE_DET table from
#               MKDM_REVENUE_DET_TEMP_RERUN
#----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_qta_rev_det_rerun.sql
   check_status
fi
#-----------------------------------------------------------------
step_number=3
# Description: Analyze QTA_REVENUE_DET Table
#-----------------------------------------------------------------
##if [ $start_step -le $step_number ] ; then
##    echo "*** Step Number $step_number"
##
##max_part_name=`sqlplus -s $ORA_CONNECT <<EOT
##        WHENEVER OSERROR EXIT FAILURE
##        WHENEVER SQLERROR EXIT FAILURE
##        SET HEADING OFF
##        SET LINESIZE 500
##        SELECT MAX (partition_name)
##          FROM user_tab_partitions
##         WHERE table_name = 'QTA_REVENUE_DET'
##           --and to_date('20120118','yyyymmdd')   test stmt
##           AND (SELECT MAX(jrnl_detl_feeder_v.meta_load_tmstmp) AS max_meta_load_tmstmp
##                  FROM jrnl_detl_feeder_v@to_ccdw_exadata
##                    -- *** META_LOAD_TMSTMP  SQL ***
##                 WHERE  (   (    jrnl_detl_feeder_v.meta_load_tmstmp
##                           BETWEEN (SELECT TO_DATE (lookup_value, 'yyyymmdd')
##                                      FROM mktgcorp_flex_env@to_ccdw_exadata
##                                     WHERE lookup_code = 'REVENUE_RERUN_METALOAD_BEG_DT')
##                               AND (SELECT TO_DATE (lookup_value, 'yyyymmdd')
##                                      FROM mktgcorp_flex_env@to_ccdw_exadata
##                                     WHERE lookup_code = 'REVENUE_RERUN_METALOAD_END_DT')
##                          AND (SELECT lookup_value
##                                 FROM mktgcorp_flex_env@to_ccdw_exadata
##                                WHERE lookup_code = 'REVENUE_RERUN_TYPE_CD') = 'METALOAD'
##                         )
##                          -- *** JRNLDTTM SQL ***
##                      OR (    jrnl_detl_feeder_v.jrnl_dttm
##                                 BETWEEN (SELECT TO_DATE (lookup_value, 'yyyymmdd')
##                                            FROM mktgcorp_flex_env@to_ccdw_exadata
##                                           WHERE lookup_code = 'REVENUE_RERUN_JRNLDTTM_BEG_DT')
##                                     AND (SELECT TO_DATE (lookup_value, 'yyyymmdd')
##                                            FROM mktgcorp_flex_env@to_ccdw_exadata
##                                           WHERE lookup_code = 'REVENUE_RERUN_JRNLDTTM_END_DT')
##                          AND (SELECT lookup_value
##                                 FROM mktgcorp_flex_env@to_ccdw_exadata
##                                WHERE lookup_code = 'REVENUE_RERUN_TYPE_CD') = 'JRNLDTTM'
##                         )
##                          -- *** FILEREFCD SQL ***
##                      OR (    jrnl_detl_feeder_v.meta_file_reference_cd
##                                 BETWEEN (SELECT lookup_value
##                                            FROM mktgcorp_flex_env@to_ccdw_exadata
##                                           WHERE lookup_code = 'REVENUE_RERUN_FILEREFCD_BEG_CD')
##                                     AND (SELECT lookup_value
##                                            FROM mktgcorp_flex_env@to_ccdw_exadata
##                                           WHERE lookup_code = 'REVENUE_RERUN_FILEREFCD_END_CD')
##                          AND (SELECT lookup_value
##                                 FROM mktgcorp_flex_env@to_ccdw_exadata
##                                WHERE lookup_code = 'REVENUE_RERUN_TYPE_CD') = 'FILEREFCD'
##                         )
##                     )
##                 AND jrnl_detl_feeder_v.jrnl_trans_type_cd IN ('BILLING', 'ADJUSTMENT')
##                 AND SUBSTR (jrnl_detl_feeder_v.fincl_cust_sgmnt_cd, 1, 1) IN ('B', 'C', 'N', 'G'))
##               > TO_DATE (SUBSTR (partition_name, 2), 'YYYYMMDD');
##        EXIT;
##EOT`
##echo $max_part_name
##    analyze_partition_table mkdm QTA_REVENUE_DET $max_part_name  5
##    check_status
##fi

echo $(date) done
exit 0


