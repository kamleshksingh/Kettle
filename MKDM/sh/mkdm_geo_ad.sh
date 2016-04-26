#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_geo_ad.sh
#**
#** Job Name        : MKDMGEOAD
#**
#** Original Author : czeisse
#**
#** Description     : Driver script that pulls MSN subscriber data and sends it 
#**                     to Experian.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 09/18/2009 czeisse	Iniial checkin
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of #this script. d for Debug is always the default
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
# Set the default values for all options.  This will only set the # variables which were NOT previously set in the getopts section.
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
CTLFILE=$CTLDIR/mkdm_ld_improv.ctl

DAT_FILE_NM=IMPROV_????????.txt
echo $DAT_FILE_NM

SUBSCRIBER_NAME=qwest_`date +"%Y%m%d"`_`date +"%H%M%S"`.dat SPOOL_PATH=/opt/stage01/experian EXPERIAN_FILE_DIR=/opt/stage01/experian

#-----------------------------------------------------------------
# Function to check the return status, set the appropriate # message
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
   data=${IMPROV_FTP_DIR}/${DATFILE} \
   skip_index_maintenance=false
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
date

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this 
# job stream to run correctly.  If the variables are not set 
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT data_tablespace 
check_variables EXPERIAN_SFTP_USER IMPROV_FTP_DIR IMPROV_FTP_ARC_DIR 
check_variables index_tablespace PANS_DB_LINK

#-----------------------------------------------------------------
step_number=1
#Description: Check file availability.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $IMPROV_FTP_DIR
   if [ ! -f $DAT_FILE_NM ] ; then
      print  "IMPROV file not present in $IMPROV_FTP_DIR"
      err_msg="$L_SCRIPTNAME (LDCDEDISC): Job Failed -  IMPROV file IMPROV_????????.txt not present as expected. Please request for the file."
      subject_msg="GEO Ad process Failed !!!"
      send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
      exit $step_number
   fi

fi


#-----------------------------------------------------------------
step_number=2
# Description: Creates geo_improv_optout table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_geo_improv_optout.sql $data_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:  Loads data into table from ${DATFILE} files.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   echo "Loading the data into GEO_IMPROV_OPTOUT table"
   cd $IMPROV_FTP_DIR
   FILELIST=`ls -rt *IMPROV*.txt`
   for DATFILE in $FILELIST
         do
                 sql_load
         done
fi

#-----------------------------------------------------------------
step_number=4
#Description: Checking whether table count matches the file record count
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $IMPROV_FTP_DIR
   FILELIST=`ls -rt *IMPROV*.txt`
   trl_rec_cnt=0
   for DATFILE in $FILELIST
        do
                trl_rec_cnt=`wc -l < IMPROV_????????.txt`
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
   SELECT count(1) FROM geo_improv_optout;
   QUIT;
   END_OF_SQL`
       if [ $trl_rec_cnt -ne $tab_rec_cnt ]; then
              echo "ERROR. The rows found is NOT equal the rows expected. Check the files and rerun the process."
              echo "Rows loaded = $tab_rec_cnt"
              echo "Rows expected = $trl_rec_cnt"
              err_msg="The table count doesn't matches the file record count"
              subject_msg="Improv file load Failed"
              send_mail "$err_msg" "$subject_msg" "$COMMON_PART_MAIL"
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
step_number=5
# Description: Creates geo_pans_ppid_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_geo_pans_ppid_temp.sql $data_tablespace $PANS_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Create geo_ppid_subscribe_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_geo_ppid_subscribe_temp.sql $data_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Create index on geo_ppid_subscribe_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_geo_ppid_subscribe_temp_indx.sql $index_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Analyse GEO_PPID_SUBSCRIBE_TEMP table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM GEO_PPID_SUBSCRIBE_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Create geo_master_subscribe_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_geo_geo_master_subscribe_tmp.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: create geo_ppid_subscriber where the user has not opted out (IMPROV file)
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_geo_ppid_subscriber_optout.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Spooling subscriber file.
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_spool_geo_experian_subscriber.sql $SPOOL_PATH/$SUBSCRIBER_NAME
   #sed -e 's/ amp /\&/g' $SPOOL_TEMP >> $SPOOL_SUCCESS
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#  Description: Zipping the subscriber file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   print "Zipping the subscriber file"
   cd $EXPERIAN_FILE_DIR
   gzip $EXPERIAN_FILE_DATE*.dat
   check_status
fi

#-----------------------------------------------------------------
step_number=13
# Description: FTP file to Experian.         
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   cd $EXPERIAN_FILE_DIR
   echo "*** Step Number $step_number"
   scp $EXPERIAN_FILE_DATE*.dat.gz $EXPERIAN_SFTP_USER@63.236.28.53:/home/xfr_user/filedrop
   check_status
fi

#-----------------------------------------------------------------
step_number=14
# Description: Archiving the processed files to archive directories
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  #rm -rf $SPOOL_TEMP
  cd $IMPROV_FTP_DIR
  FILELIST=`ls -rt *IMPROV*.txt`
  echo $FILELIST
  echo "Moving old file to $IMPROV_FTP_ARC_DIR directory."
        for DATFILE in $FILELIST
                do
                        mv -f $IMPROV_FTP_DIR/${DATFILE} ${IMPROV_FTP_ARC_DIR}/${DATFILE}.$$
                        echo "Processed improv dat file moved to archive directory"
                        check_status
                done
  find ${IMPROV_FTP_ARC_DIR}/IMPROV* -mtime +10 -exec rm -f {}    \;
  check_status
fi

#-----------------------------------------------------------------
step_number=15
# Description: Drop temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  run_sql mkdm_drp_geo_temp.sql
  check_status
fi

#-----------------------------------------------------------------
step_number=16
# Description: Delete the subscriber file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   cd $EXPERIAN_FILE_DIR
   echo "*** Step Number $step_number"
    rm -rf *
   check_status
fi

#-----------------------------------------------------------------
step_number=17
# Description: Send mail
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
         success_msg="Geo Ad process finished successfully "
         send_mail "$success_msg" "$subject_msg" "$COMMON_PART_MAIL"
    check_status
fi


echo $(date) done
exit 0