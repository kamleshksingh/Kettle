#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_upd_cplus_loyalty_customer.sh
#**
#** Job Name        :  MKDMLDCPLS
#**
#** Original Author :  rxsank2
#**
#** Description     :  update cplus loyalty customer table
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 05/22/2009 rxsank2  Initial Checkin
#*****************************************************************************

. ~/.mkdm_env

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
start_step=${start_step:=0}

#-----------------------------------------------------------------
#Check for debug mode [-d]
#-----------------------------------------------------------------
if [ $debug -eq 1 ]; then
   set -x
fi

#-----------------------------------------------------------------
# Set $ parameters here.
#-----------------------------------------------------------------
YYYYMMDD=`date +%Y%m%d`

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
        fi
     fi
     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     subject_msg="Job Error - $L_SCRIPTNAME"
     echo "Process failed at the Step:  $step_number"
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

check_variables start_step ORA_CONNECT MKDM_ERR_LIST CPLUS_MAIL_LIST CPLUS_IN_DIR CPLUS_ARC_DIR 

#-----------------------------------------------------------------
step_number=1
#Description: To verify the existance of the tag file from cplus
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   if [ -f $CPLUS_IN_DIR/cplus_loyalty_$YYYYMMDD.tag ] ;
      then  
          echo "The tag file cplus_loyalty_$YYYYMMDD.tag exists"
          check_status
      else
          echo "The tag file cplus_loyalty_$YYYYMMDD.tag doesnot exists" 
          mail_msg="Tag file cplus_loyalty_$YYYYMMDD.tag is not present in $CPLUS_IN_DIR"
          mail_subject_msg="MKDMLDCPLS:Tag file not available"
          send_mail "$mail_msg" "$mail_subject_msg" "$CPLUS_MAIL_LIST"
          exit $step_number 
   fi
fi

#-----------------------------------------------------------------
step_number=2
#Description:  Purge records which are older than 6 months
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

   run_sql mkdm_purge_cplus_loyalty_customer.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description:  Move tag file to archive directory
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

   mv $CPLUS_IN_DIR/cplus_loyalty*.tag $CPLUS_ARC_DIR/.
   check_status
fi

#-----------------------------------------------------------------
# completion and email notification.
#-----------------------------------------------------------------
success_msg="MKDMLDCPLUS job completed successfully on `date`."
subject_msg="MKDMLDCPLUS job completed "
send_mail "$success_msg" "$subject_msg" "$MKDM_ERR_LIST"
check_status

exit 0
