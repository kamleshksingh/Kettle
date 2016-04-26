#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_ld_dwbi_bobo_data.sh
#** 
#** Job Name        : LDBOBOSTG
#** 
#** Original Author : Verissa Beatty
#**
#** Description     : Load Combined Billing (BOBO) data from DBWI Dept layer
#**                   Runs Monthly on 3rd Friday of month.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 10/25/2010 vbeatty  Initial Checkin 
#*****************************************************************************

#test hook
#. ~/.mkdm_env 
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`
filedate=`date +'%Y%m%d'`

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

TABLE_NAME=cptdb_mktg_bobo_stg
VIEW_NAME=D_MASSMKT.CPTDB_MKTG_BOBO_V
LINK_2_DWBIDEPT=to_dwbi_dept

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

##############################################################################
#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT MKDM_ERR_LIST 
   
#-----------------------------------------------------------------
step_number=1
#Description:  Truncate and Load data into CPTDB_MKTG_BOBO_STG
#               table from DWBI Dept View
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_dwbi_bobo_data.sql "$TABLE_NAME $VIEW_NAME $LINK_2_DWBIDEPT"
   check_status
fi


#---------------------------------------------------------------------------
step_number=2
#Description: Analyze table MKDM CPTDB_MKTG_BOBO_STG
#---------------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM $TABLE_NAME 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: send_mail common function is called for successful
# completion and email notification.
#-----------------------------------------------------------------
success_msg="LDBOBOSTG job completed sucessfully on `date` ."
subject_msg="LDBOBOSTG job completed"
send_mail "$success_msg" "$subject_msg" "$MKDM_ERR_LIST"

exit 0

