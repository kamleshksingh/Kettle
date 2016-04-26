#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_crt_voip_rate_center.sh
#**
#** Job Name        :  CRTRCQUAL
#**
#** Original Author :  Beneven Noble
#**
#** Description     :  Script to load voip_rate_center table
#**                    From CNUM file 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- -----------------------------------------------------
#** 01/24/2007 nbeneve  Initial check in
#** 10/05/2011 skondav  Changed source of voip_rate_center from cpacni to CNUM file - CSTAKE 271776
#*****************************************************************************************************

#test hook
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

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

     if [[ "${2}" = "2" ]]; then
         mail_msg="$1"
         mail_sub="Job Error - $L_SCRIPTNAME"
	 send_mail "$mail_msg" "$mail_sub" "$MKDM_ERR_LIST" 
         exit $3
     fi

     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     echo "$err_msg"
     subject_msg="Job Error - $L_SCRIPTNAME"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST" 
     exit $step_number
  fi
}

#-----------------------------------------------------------------
# Function  to check the sqlldr load
#-----------------------------------------------------------------
function chk_load
{
   print "Verify Load of $2"
   print "**********************************************"

   rows_loaded=`grep 'Rows successfully loaded' $LOGDIR/mkdm_voip_rate_center.log| awk 'NR==1 {print $1}'`
   print "Rows loaded into table      = $rows_loaded"
   print "Rows in the file $2         = $1"

   if [ $rows_loaded -eq $1 ]; then
      print "The rows loaded into table equals the rows expected."
      return 0
   else
      print "ERROR. The rows loaded is NOT equal to the rows expected. Check the file $2 and rerun the process."
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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST data_tablespace index_tablespace LINK_TO_CPACNI
check_variables StageExtCNUM FtpExtCNUM CNUM_MAIL_LIST
#-----------------------------------------------------------------
step_number=1
#Description: Check if the file is present
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

   cd ${FtpExtCNUM}
   check_status

   if [ -e voip_rate_centers_????????.csv ];
   then
      echo "File Present"
      ls voip_rate_centers_????????.csv
   else
      echo "File not Present"
      send_mail "The voip_rate_center.yyyymmdd.csv file is not sent to MKDM" "File Not Present" "$CNUM_MAIL_LIST"
      exit $step_number
   fi

   rm -f ${StageExtCNUM}/voip_rate_centers_????????.csv
   check_status

   cd ${FtpExtCNUM}
   mv voip_rate_centers_????????.csv ${StageExtCNUM}/
   check_status
fi

cd ${StageExtCNUM}
export CSVFILE=`ls voip_rate_centers_????????.csv`
export csv_file_cnt=`wc -l ${StageExtCNUM}/${CSVFILE}|cut -f1 -d" "`
export row_count=`expr $csv_file_cnt - 1`

#-----------------------------------------------------------------
step_number=2
#Description: Truncate table VOIP_RATE_CENTER table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_trun_voip_rate_center.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Sqlload the files into the voip_rate_center table in mkdm
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   cd ${StageExtCNUM}
   sqlldr userid=${ORA_CONNECT} \
   control=$CTLDIR/mkdm_voip_rate_center.ctl \
   data='$CSVFILE' \
   log=$LOGDIR/mkdm_voip_rate_center.log \
   discard=$LOGDIR/mkdm_voip_rate_center.disc \
   bad=$LOGDIR/mkdm_voip_rate_center.bad \
   rows=1000000 \
   skip=1 \
   DIRECT=TRUE
   check_status "Job failed in sqlldr step" "2" "$step_number" 

   chk_load ${row_count} ${CSVFILE}

fi

#-----------------------------------------------------------------
step_number=4
#Description: Analyze VOIP_RATE_CENTER table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM VOIP_RATE_CENTER  5
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Remove files
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   rm -f ${StageExtCNUM}/voip_rate_centers_????????.csv
   check_status
fi

echo $(date) done
exit 0






