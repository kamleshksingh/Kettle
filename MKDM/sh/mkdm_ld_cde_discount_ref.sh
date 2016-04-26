#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_cde_discount_ref.sh
#**
#** Original Author :  nbeneve
#**
#** Job Name        :  LDCDEDISC
#**
#** Description     :  Job to populate CDE_DISCOUNT_REF table
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 05/05/2009 nbeneve  Initial Checkin
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

TEMP_ORA_CONNECT=$ORA_CONNECT

#-----------------------------------------------------------------
#Check for debug mode [-d]
#-----------------------------------------------------------------
if [ $debug -eq 1 ]; then
   set -x
fi

#-----------------------------------------------------------------
# Set $ parameters here.
#-----------------------------------------------------------------
CTLFILE=$CTLDIR/mkdm_ld_cde_discount_ref.ctl
CDE_FTP_DIR=/home/ftp/pub/CDE
CDE_STG_DIR=/opt/stage02/cde
cd $CDE_FTP_DIR
DAT_FILE_NM=`ls DISCDESC_D??????.DAT`
TAG_FILE_NM=`print $DAT_FILE_NM | sed 's/.DAT/.TAG/g'`
echo $DAT_FILE_NM
echo $TAG_FILE_NM

#-----------------------------------------------------------------
# Function to check the return status and set the appropriate
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then
     err_msg="$L_SCRIPTNAME (LDCDEDISC)    Errored at Step: $step_number"
     subject_msg="Job Error - $L_SCRIPTNAME"
     echo "Process failed at the Step:  $step_number"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
     exit $step_number
  fi
}

#-----------------------------------------------------------------
# Function to load the temp table from ZIP file.
#-----------------------------------------------------------------

function sql_ldr
{

   sqlldr userid=$ORA_CONNECT                           \
   errors=0                                             \
   control=$CTLFILE                                     \
   log=$LOGDIR/${L_SCRIPTNAME}_sqlld.$$.log             \
   DIRECT=TRUE                                          \
   ROWS=10000                                           \
   bad=${LOGDIR}/${L_SCRIPTNAME}_sqlld.$$.bad           \
   discard=${LOGDIR}/${L_SCRIPTNAME}_sqlld.$$.dis       \
   data=${CDE_STG_DIR}/${DAT_FILE_NM}                   \
   skip_index_maintenance=false                         \
   skip=1
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

check_variables start_step ORA_CONNECT MKDM_ERR_LIST CDE_MAIL_LIST MKDM_DB_LINK data_tablespace

#-----------------------------------------------------------------
step_number=1
#Description:  Check the presence of CDE discount file and move it to staging dir 
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $CDE_FTP_DIR
   if [ ! -f "$DAT_FILE_NM" ] ; then
      print  "CDE discount file not present in $CDE_FTP_DIR"
      err_msg="$L_SCRIPTNAME (LDCDEDISC): Job Failed -  CDE Discount file DISCDESC_D??????.DAT/.TAG not recieved on 1st of the month as expected. Please request for the file."
      subject_msg="CDE_DISCOUNT_REF load process Failed !!!"
      send_mail "$err_msg" "$subject_msg" "$CDE_MAIL_LIST"
      exit $step_number
   else
      rm -f $CDE_STG_DIR/DISCDESC_D*
      check_status
      cp $DAT_FILE_NM $CDE_STG_DIR 
      cp $TAG_FILE_NM $CDE_STG_DIR 
      check_status
   fi

fi

#-----------------------------------------------------------------
step_number=2
#Description: Create CDE_DISCOUNT_REF_STAGE table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_cde_discount_ref_stage.sql $data_tablespace
   check_status

fi

#-----------------------------------------------------------------
step_number=3
#Description:  Loads file into CDE_DISCOUNT_REF_STAGE table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   sql_ldr
   check_status

fi

#-----------------------------------------------------------------
step_number=4
#Description: Checking whether table count matches the file record count
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $CDE_STG_DIR
   tag_cnt=`cat ${TAG_FILE_NM}`
   check_status
   rec_cnt=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT TRIM(COUNT(1)) FROM cde_discount_ref_stage;
   QUIT;
   END_OF_SQL`
   check_status
       if [ $tag_cnt -ne $rec_cnt ]; then
          rec_cnt=`echo $rec_cnt|sed '/^$/d'`   # To remove empty line present
          echo "ERROR. Record count in the DAT file doesnt match tag file count\n"
          echo "Record count      = $rec_cnt"
          echo "Tag file count    = $tag_cnt"
          err_msg="The record count in the DAT file doesn't match tag file count.\n\n\t Record Count  :$rec_cnt\n\t Tag file count:$tag_cnt"
          subject_msg="Job Error - $L_SCRIPTNAME(LDCDEDISC) FAILED !!!"
          send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
          exit 1
        else
          rec_cnt=`echo $rec_cnt|sed '/^$/d'`    # To remove empty line present
          echo "Record count matches tag file count"
          echo "Record count   = $rec_cnt"
          echo "Tag file count = $tag_cnt"
          check_status
       fi
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Loads MKDM CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_cde_discount_ref.sql
   check_status

fi

#-----------------------------------------------------------------
step_number=6
#Description: Analyze CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM cde_discount_ref 5
   check_status

fi

#-----------------------------------------------------------------
step_number=7
#Description: Drop CDE_DISCOUNT_REF_STAGE table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_cde_discount_ref_stage.sql
   check_status

fi

export ORA_CONNECT=$CONNECT_CRDM

#-----------------------------------------------------------------
step_number=8
#Description: Loads CRDM CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql ld_cde_discount_ref.sql $MKDM_DB_LINK
   check_status

fi

#-----------------------------------------------------------------
step_number=9
#Description: Analyze CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table CRDM cde_discount_ref 5
   check_status

fi


export ORA_CONNECT=$CONNECT_BDM


#-----------------------------------------------------------------
step_number=10
#Description: Loads BDM CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   MKDM_DB_LINK=to_mkdm
   run_sql ld_cde_discount_ref.sql $MKDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Analyze CDE_DISCOUNT_REF table
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table BDM cde_discount_ref 5 $ORA_CONNECT
   check_status

fi

#-----------------------------------------------------------------
step_number=12
#Description:  Removing file from CDE ftp dir and archive process 
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $CDE_STG_DIR
   mv DISCDESC_D* archive
   cd $CDE_FTP_DIR
   rm -f $DAT_FILE_NM $TAG_FILE_NM
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description:  Remove files older than 24 months
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rm -f `find $CDE_STG_DIR/archive/DISCDESC_D* -mtime +731 -print`
   check_status

fi

export ORA_CONNECT=$TEMP_ORA_CONNECT

#-----------------------------------------------------------------
step_number=14
# Description: send_mail common function is called for successfull
# completion and email notification.
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rec_cnt=`sqlplus -s $ORA_CONNECT << END_OF_SQL
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT count(1) FROM cde_discount_ref;
   QUIT;
   END_OF_SQL`
   rec_cnt=`echo $rec_cnt|sed '/^$/d'` # To remove empty line present
   success_msg="CDE_DISCOUNT_REF table loaded successfully in MKDM,CRDM and BDM. No of records loaded : $rec_cnt"
   subject_msg="CDE_DISCOUNT_REF Table Loaded Successfully !!!"
   send_mail "$success_msg" "$subject_msg" "$CDE_MAIL_LIST"
   check_status
fi

exit 0

