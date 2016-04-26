#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_revenue_account_cur.sh
#**
#** Job Name        :  REVACCTCUR
#**
#** Original Author :  GGOPAL
#**
#** Description     :  Create mkdm_revenue_account_cur table
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/25/2008 ggopal  Initial checkin.
#** 10/14/2008 nbeneve  Added separate process for RIBD records
#** 10/16/2008 dxpanne  To validate the load of mkdm_revenue_account_cur
#**                     by blank acct_estab_dat
#** 10/25/2008 ddamoda  To change the mkdm_revenue_account_cur table as partitioned table.
$** 06/10/2008 vxredd4	To truncate the previous partition in mkdm_revenue_account_cur
                        table if not get any data from mkdm_revenue_det for current month.
#*****************************************************************************

. ~/.mkdm_env
. $FPATH/common_funcs.sh

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

part_date=$1
THRESHOLD_CRIS=$2
THRESHOLD_LAT=$3

function get_blg_sce_sys_cd
{
  if [ $step_number -eq 4 ] ; then
   BLG_SCE_SYS_CD_LIST=`sqlplus -s $ORA_CONNECT <<END_OF_SQL
   SET HEAD OFF
   SET PAGESIZE 0
   SET FEEDBACK OFF
   SET TRIMOUT ON
   SELECT TRIM(blg_sce_sys_cd) FROM mkdm_rev_acct_parm WHERE status_indr='N';
   EXIT
   END_OF_SQL`
   check_status
   check_variables BLG_SCE_SYS_CD_LIST
  fi
}

check_variables start_step part_date MKDM_ERR_LIST
check_variables THRESHOLD_LAT THRESHOLD_CRIS

#-----------------------------------------------------------------
step_number=1
#Description: Create Temp table to process each blg_sce_sys_cd
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_mkdm_rev_acct_parm.sql $part_date
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Comparing the existing partition names with the distinct blg_sce_sys_cd
#             and creating new partition in MKDM_REVENUE_ACCOUNT_CUR
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   new_part=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT UPPER(blg_sce_sys_cd) FROM mkdm_rev_acct_parm a MINUS SELECT LTRIM(partition_name,'P_') FROM all_tab_partitions WHERE table_name='MKDM_REVENUE_ACCOUNT_CUR';
   QUIT;
   END_OF_SQL` 
 
  echo $new_part 
  for i in $new_part
  do
     run_sql mkdm_crt_part_rev_acct_cur.sql $i $data_tablespace 
     check_status
  done
  check_status
fi

#-------------------------------------------------------------------
step_number=3
#Description:  To truncate the previous partition in mkdm_revenue_account_cur
#              table if not get any data from mkdm_revenue_det for current month
#-------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   prev_part=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT  LTRIM(partition_name,'P_') FROM all_tab_partitions WHERE table_name='MKDM_REVENUE_ACCOUNT_CUR' MINUS  SELECT UPPER(blg_sce_sys_cd) FROM mkdm_rev_acct_parm a;
   QUIT;
   END_OF_SQL`

  echo $prev_part
  for i in $prev_part
  do 
     run_sql mkdm_trunc_part_rev_acct_cur.sql $i
     check_status
  done
  check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Insert into mkdm_revenue_account_cur based on the huge BLG_SCE_SYS_CD
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   get_blg_sce_sys_cd

for BLG_SCE_SYS_CD in $BLG_SCE_SYS_CD_LIST
 do
   if [[ $BLG_SCE_SYS_CD = 'LAT' || $BLG_SCE_SYS_CD = 'SSW' ]]; then
     run_sql mkdm_ins_mkdm_revenue_account_cur_LAT_SSW.sql $data_tablespace $part_date $BLG_SCE_SYS_CD
   elif [[ $BLG_SCE_SYS_CD = 'RIBD' ]]; then
     run_sql mkdm_ins_mkdm_revenue_account_cur_RIBD.sql $data_tablespace $part_date $BLG_SCE_SYS_CD
   else
     run_sql mkdm_ins_mkdm_revenue_account_cur.sql $data_tablespace $part_date $BLG_SCE_SYS_CD
   fi
   check_status
 done

fi

#-----------------------------------------------------------------
step_number=5
#Description: To analyze table mkdm_revenue_account_cur
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MKDM_REVENUE_ACCOUNT_CUR 5 
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Drop temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_del_mkdm_revenue_account_cur_temp.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: To validate the load of mkdm_revenue_account_cur
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   error_out=0

cnt_cris=`sqlplus -s $ORA_CONNECT <<END_OF_SQL
   SET HEAD OFF
   SET PAGESIZE 0
   SET FEEDBACK OFF
   SET TRIMOUT ON
   SELECT COUNT(1) FROM mkdm_revenue_account_cur
   WHERE acct_estab_dat IS NULL
   AND blg_sce_sys_cd LIKE 'CRIS%'; 
   EXIT
   END_OF_SQL`
   check_status

    if [ $cnt_cris -gt $THRESHOLD_CRIS ] ; then
         echo "Number of blank acct_estab_dat for CRIS records is more than the threshold limit"
         echo "Job Failed - Number of blank acct_estab_dat records is above threshold limit for CRIS
"
   err_cris="\nNumber of blank acct_estab_dat for CRIS records is more than the threshold limit \n\
             Threshold limit for CRIS is $THRESHOLD_CRIS \n\
             Count of blank acct_estab_dat is $cnt_cris                                       \n"
         error_out=1;
    fi

cnt_lat=`sqlplus -s $ORA_CONNECT <<END_OF_SQL
   SET HEAD OFF
   SET PAGESIZE 0
   SET FEEDBACK OFF
   SET TRIMOUT ON
   SELECT COUNT(1) FROM mkdm_revenue_account_cur 
   WHERE acct_estab_dat IS NULL
   AND blg_sce_sys_cd LIKE 'LAT%';
   EXIT
   END_OF_SQL`
   check_status

    if [ $cnt_lat -gt $THRESHOLD_LAT ] ; then
        echo "Number of blank acct_estab_dat for LATIS records is more than the threshold limit"
        echo "Job Failed - Number of blank acct_estab_dat records is above threshold limit for LATIS
"
err_lat="\nNumber of blank acct_estab_dat for LATIS records is more than the threshold limit \n\
          Threshold limit for LATIS is $THRESHOLD_LAT                                      \n\
          Count of blank acct_estab_dat is $cnt_lat                         "
        error_out=1;
    fi

    if [ $error_out -eq 1 ] ; then
        err_msg=$err_cris$err_lat
        echo "$err_msg"
        subject_msg="Job Error - REVACCTCUR"
        send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
        exit 7
    fi

   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: To update the parm list
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_parm_list_REVACCTCUR.sql
   check_status
fi

exit 0
