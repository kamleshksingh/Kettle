#!/bin/ksh
#*******************************************************************************
#** Program         :  dtv_bill_sync_proc.sh
#**
#** Original Author :  ddamoda
#**
#** Job Name        :  DTVBILL
#**
#** Description     :  Job for populating DTV_BILL_SYNC_ADDR table.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/09/2008 ddamoda  initial Checkin
#** 08/02/2008 ddamoda  set failure limit to 1% of total
#** 08/26/2008 ddamoda  Change process to get address from stg_account_cris and DTVDB
#** 11/22/2010 mxlaks2  Linux Migration
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
start_step=${start_step:=0}
DATADIR=$1

#-----------------------------------------------------------------
#Check for debug mode [-d]
#-----------------------------------------------------------------
if [ $debug -eq 1 ]; then
   set -x
fi

#-----------------------------------------------------------------
# Set $ parameters here.
#-----------------------------------------------------------------
CTLFILE=$CTLDIR/crdm_ld_dtv_bill_sync.ctl

#-----------------------------------------------------------------
# Function to check the return status and set the appropriate
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then
     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     subject_msg="DirectTV job Process Failed"
     echo "Process failed at the Step:  $step_number"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
     exit $step_number
  fi
}

#-----------------------------------------------------------------
# Function to load the temp table from ZIP file.
#-----------------------------------------------------------------

function sql_load
{

   sqlldr userid=$ORA_CONNECT                           \
   errors=0                                             \
   control=$CTLFILE                                     \
   log=$LOGDIR/${DATFILE}_sqlld.$$.log \
   DIRECT=TRUE  \
   ROWS=100000 \
   bad=${LOGDIR}/${DATFILE}_sqlld.$$.bad \
   discard=${LOGDIR}/${DATFILE}_sqlld.$$.dis \
   data=${DTV_IN_DIR}/${DATFILE} \
   skip_index_maintenance=false
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

MISSING_FIELDS=$HOME/missing_field.txt
SPOOL_NULL=/opt/stage02/mkdm/rib/data_null.txt
SPOOL_TEMP=/opt/stage02/mkdm/rib/dtv_sync_spool.dat
SPOOL_SUCCESS=/opt/stage02/mkdm/rib/dtv_sync_notification.dat

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step DTV_IN_DIR ORA_CONNECT DATADIR CTLDIR data_tablespace index_tablespace 
check_variables DTV_MAIL_LIST MKDM_ERR_LIST GDT_ENV_FILE_PATH

rm -rf $SPOOL_NULL $SPOOL_SUCCESS $MISSING_FIELDS

#-----------------------------------------------------------------
step_number=1
#Description: Check file availability.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $DTV_IN_DIR
        FILELIST=`ls -rt *RIB_DTV_BILL_SYNC*.dat`
        if [ -z "$FILELIST" ] ; then
           FILELIST2=`find ${DTV_ARC_DIR}/RIB_DTV_BILL_SYNC*.dat -type f -mtime -45`
           if [ -z "$FILELIST2" ] ; then
               err_msg="$L_SCRIPTNAME : Job Failed -  DATFILE not received since 45 days!! Check with RIB Team "
               subject_msg="Job Error - $L_SCRIPTNAME"
               send_mail "$err_msg" "$subject_msg" "$DTV_MAIL_LIST"
               echo "DATFILE not received since 45 days!! Check with RIB team"
               exit 1
           else
               err_msg="DATFILE not received for this month"
               subject_msg="DTVBILL job completed"
               send_mail "$err_msg" "$subject_msg" "$DTV_MAIL_LIST"
               echo "DATFILE not received for this month"
               exit 0
            fi
        else
          echo "DATFILE received for this month"
        fi
      check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description:  Loads data into table from ${DATFILE} files.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   echo "Loading the data into DTV_BILL_SYNC table"
   cd $DTV_IN_DIR
   FILELIST=`ls -rt *RIB_DTV_BILL_SYNC*.dat`
   for DATFILE in $FILELIST
         do
                 sql_load
         done
fi

#-----------------------------------------------------------------
step_number=3
#Description: Checking whether table count matches the file record count
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $DTV_IN_DIR
   FILELIST=`ls -rt *RIB_DTV_BILL_SYNC*.dat`
   trl_rec_cnt=0
   for DATFILE in $FILELIST
        do
                trailer=`tail -1 $DATFILE`
                cnt=`expr substr $trailer 10 9 - 2`
                trl_rec_cnt=`expr $trl_rec_cnt + $cnt`
                check_status
        done
   tab_rec_cnt=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT count(1) FROM dtv_bill_sync WHERE status_cd=0 AND TRUNC(load_dt)>=TRUNC(SYSDATE-2);
   QUIT;
   END_OF_SQL`
       if [ $trl_rec_cnt -ne $tab_rec_cnt ]; then
              echo "ERROR. The rows found is NOT equal the rows expected. Check the files and rerun the process."
              echo "Rows loaded = $tab_rec_cnt"
              echo "Rows expected = $trl_rec_cnt"
              err_msg="The table count doesn't matches the trailer record count"
              subject_msg="DTVBILL load Failed"
              send_mail "$err_msg" "$subject_msg" "$DTV_MAIL_LIST"
              exit 1
        else
              echo "The rows found equal the rows expected."
              echo "Rows loaded = $tab_rec_cnt"
              echo "Rows expected = $trl_rec_cnt"
              cp $LOGDIR/${DATFILE}_sqlld.$$.log $LOGDIR/${DATFILE}_sqlld.log
              check_status
              print "Copied log file"
        fi
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Analyse DTV_BILL_SYNC table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM DTV_BILL_SYNC 5
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Creating temp table with address info using stg_account_cris
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_dtv_bill_sync_addr_temp.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Analyse dtv_bill_sync_addr_temp table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM DTV_BILL_SYNC_ADDR_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Inserting data into dtv_bill_sync_addr table from temp table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_dtv_bill_sync_addr.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Create temp table with rowid for update process
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_rowid_bill_sync.sql $data_tablespace	
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description: Create index on rowid
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_rowid_bill_sync.sql $index_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: Analyse table  DTV_BILL_SYNC_RTMP
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM DTV_BILL_SYNC_RTMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Updating status_cd for processed record
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_dtv_bill_sync_addr.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description: Running the Java Program to get the values from
#             DTVDB
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   machine=`uname -n`
   uid=`id -nu`
   java -Xms512m -Xmx512m DTVBillSync $machine $uid $GDT_ENV_FILE_PATH > ${LOGDIR}/DTVBILLSYNC.log
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description: Analyse DTV_BILL_SYNC_ADDR table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM DTV_BILL_SYNC_ADDR 5
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description: Compare the count of no of records processed and no of records errored out.
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   total_count=`sqlplus -s $ORA_CONNECT << END_OF_SQL
                     SET TIMING OFF;
                     SET SPACE 0;
                     SET NEWPAGE 0;
                     SET HEADING OFF;
                     SET FEEDBACK OFF;
                     SET TIME OFF;
                     SET TERMOUT OFF;
                     SET ECHO OFF;
                     SET WRAP OFF;
                     SET VERIFY OFF;
                     SET PAGESIZE 0;
                     SET LINESIZE 100;
                     WHENEVER SQLERROR EXIT FAILURE
                     WHENEVER OSERROR EXIT FAILURE
                     SELECT COUNT(1) FROM dtv_bill_sync_addr WHERE TRUNC(load_dt)>=TRUNC(SYSDATE-2);
   QUIT;
   END_OF_SQL`

   load_count=`sqlplus -s $ORA_CONNECT << END_OF_SQL
                     SET TIMING OFF;
                     SET SPACE 0;
                     SET NEWPAGE 0;
                     SET HEADING OFF;
                     SET FEEDBACK OFF;
                     SET TIME OFF;
                     SET TERMOUT OFF;
                     SET ECHO OFF;
                     SET WRAP OFF;
                     SET VERIFY OFF;
                     SET PAGESIZE 0;
                     SET LINESIZE 100;
                     WHENEVER SQLERROR EXIT FAILURE
                     WHENEVER OSERROR EXIT FAILURE
                     SELECT COUNT(1) FROM dtv_bill_sync WHERE status_cd='2' AND TRUNC(load_dt)>=TRUNC(SYSDATE-2);
    QUIT;
    END_OF_SQL`
    check_status
    valid_count=`expr 99 \* $total_count / 100`
    if [ $load_count -lt $valid_count ] ; then
        err_msg="$L_SCRIPTNAME : Job Failed - Count of null records is more than 1%"
        subject_msg="Job Error - $L_SCRIPTNAME"
        echo "$err_msg"
        echo "Please Contact DTV Team and Re-run the job"
        send_mail "$err_msg" "$subject_msg" "$DTV_MAIL_LIST"
       exit 1
     else
        echo "The count of null records is less than 1%"
        run_sql mkdm_spool_data_null_resp.sql $SPOOL_NULL
        check_status
     fi
fi

#-----------------------------------------------------------------
step_number=15
#Description: Spooling successfully processed records.
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_spool_dtv_data_resp.sql $SPOOL_TEMP
   sed -e 's/ amp /\&/g' $SPOOL_TEMP >> $SPOOL_SUCCESS
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description: Emailing the DTV synchronization account list.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  var="BLG_NM BLG_ADRS BLG_CITY_NM BLG_STATE_CD BLG_ZIP_CD"
  echo '*----------------------------------------------------------------*'>>$MISSING_FIELDS
  echo '*      NO.OF MISSING FIELDS DETAILS OF THIS MONTH LOAD           *'>>$MISSING_FIELDS
  echo '*----------------------------------------------------------------*'>>$MISSING_FIELDS
  echo '                                                                         '>>$MISSING_FIELDS

for i in $var
  do
      Null=`sqlplus -s $ORA_CONNECT << END_OF_SQL
                 SET TIMING OFF;
                 SET SPACE 0;
                 SET NEWPAGE 0;
                 SET HEADING OFF;
                 SET FEEDBACK OFF;
                 SET TIME OFF;
                 SET TERMOUT OFF;
                 SET ECHO OFF;
                 SET WRAP OFF;
                 SET VERIFY OFF;
                 SET PAGESIZE 0;
                 SET LINESIZE 100;
                 WHENEVER SQLERROR EXIT FAILURE
                 WHENEVER OSERROR EXIT FAILURE
                 SELECT COUNT(1) FROM dtv_bill_sync_addr WHERE TRUNC(load_dt)>=TRUNC(SYSDATE-2) AND $i IS NULL;
       QUIT;
       END_OF_SQL`
       echo "No.of missing $i -------------------$Null">>$MISSING_FIELDS
  done
  SPOOL_TIME=`date +%Y%m%d%H%M%S`
  (cat $MISSING_FIELDS;uuencode $SPOOL_SUCCESS dtv_sync_notification.${SPOOL_TIME}.dat)| mail  -s "DTV Double bill mail" "$DTV_BILL_MAIL_LIST"
  check_status
fi

#-----------------------------------------------------------------
step_number=17
# Description: Clean up the tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  run_sql mkdm_del_dtv_bill_sync.sql
  check_status
fi

#-----------------------------------------------------------------
step_number=18
# Description: Drop temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  run_sql mkdm_drp_dtv_bill_sync_addr_temp.sql
  check_status
fi

#-----------------------------------------------------------------
step_number=19
# Description: Archiving the processed files to archive directory
#              and removing temp files
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  rm -rf $SPOOL_TEMP
  cd $DTV_IN_DIR
  FILELIST=`ls -rt *RIB_DTV_BILL_SYNC*.dat`
  echo $FILELIST
  echo "Moving old file to $DTV_ARC_DIR directory."
        for DATFILE in $FILELIST
                do
                        mv -f $DTV_IN_DIR/${DATFILE} ${DTV_ARC_DIR}/${DATFILE}.$$
                        echo "Processed dat file moved to archive directory"
                        check_status
                done
  find ${DTV_ARC_DIR}/RIB_DTV_BILL_SYNC* -mtime +91 -exec rm -f {}    \;
  check_status
fi

#-----------------------------------------------------------------
step_number=20
# Description: Email notification.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  CNT=`cat $DTV_IN_DIR/data_null.txt |wc -l`
  if [ $CNT -eq 0 ] ; then
        err_msg="DTV_BILL_SYNC table loaded sucessfully"
        subject_msg="DTVBILL job sucessful"
        send_mail "$err_msg" "$subject_msg" "$DTV_MAIL_LIST"
  else
        subject_msg="DTV_BILL_SYNC_ADDR loaded successfully - List of null records"
        NULL_REC=`cat $SPOOL_NULL`
        send_mail "$NULL_REC" "$subject_msg" "$DTV_MAIL_LIST"
  fi
  echo "DTVBILL Job completed successfully"
  check_status
fi

exit 0











































































































































































































































































































































































































































































