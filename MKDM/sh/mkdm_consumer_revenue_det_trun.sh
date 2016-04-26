#!/bin/ksh
#*******************************************************************************
#** Program         :   mkdm_consumer_revenue_det_trun.sh
#**
#** Job Name        :   CONREVTRUN
#**
#** Original Author :   dxkumar
#**
#** Description     :   Truncates two month older partition on
#**                     CONSUMER_REVENUE_SUMMARY table.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 08/10/2006 dxkumar  Initial checkin.
#** 01/31/2007 mmuruga  Added steps to drop older partition for business table.
#*****************************************************************************


L_SCRIPTNAME=`basename $0`

start_step=0

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
# Function to check the return status and set the appropriate # message
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
check_variables start_step ORA_CONNECT

#-----------------------------------------------------------------
step_number=1
#Truncates two month older partition on
#CONSUMER_REVENUE_SUMMARY table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_consumer_revenue_det_trun.sql
    check_status
fi


#-----------------------------------------------------------------
step_number=2
#Drop two month older partition on
#BUSINESS_REVENUE_SUMMARY table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_business_revenue_det_trun.sql
   check_status
fi


echo $(date) done
exit 0

