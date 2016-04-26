#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_ld_clli_city 
#** 
#** Job Name        :  
#** 
#** Original Author : john kadingo 
#**
#** Description     :   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 06/03/2004          Initial Checkin 
#*****************************************************************************

#test hook
#. ~/pcms/mkdm/common/.mkdm_env.tst
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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST

#-----------------------------------------------------------------
step_number=1
#Description:  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_dslpup_ld_clli_city.sql 
   check_status
fi
#-----------------------------------------------------------------
# Any extra Steps necessary, can be cut and or pasted from the 
# example below
#-----------------------------------------------------------------
#-----------------------------------------------------------------
step_number=2
# Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_dslpup_crt_indx_clli_city.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description:
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   analyze_table mkdm CLLI_CITY_REF 5
   check_status
fi

#-----------------------------------------------------------------
#step_number=$
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
#success_msg="Job name successful message goes here  and allows for multiple line formats"
#subject_msg="Subject message goes here"
#send_mail "$success_msg" "$subject_msg" "$MAIL_LIST"
#check_status

exit 0

