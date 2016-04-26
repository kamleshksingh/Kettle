#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_stg_account_cris.sh
#** 
#** Job Name        :  
#** 
#** Original Author : Sanjeev Chaudhary 
#**
#** Description     :  Script to load account data (csban) from CDW
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 06/21/2004 schaudh  Initial checkin.
#*****************************************************************************

##############################################################################
# Comment these test hooks before deilvery
##############################################################################
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_string=$(date '+%Y%m%d')
start_step=0

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------


#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of 
#this script. d for Debug is always the default
#-----------------------------------------------------------------

while getopts "s:t:i:d:f" option
do
   case $option in
     s) start_step=$OPTARG;;
     t) data_tablespace=$OPTARG;;
     i) index_tablespace=$OPTARG;;
     d) debug=1;;
     f) date_string=$OPTARG;;  
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
date

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables RBS_LARGE start_step ORA_CONNECT CDW_DB_LINK MKDM_ERR_LIST 

#-----------------------------------------------------------------
step_number=1
# Description: Truncate the table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    truncate_table stg_account_cris  
    check_status
fi

#-----------------------------------------------------------------
step_number=2
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   nuke_all MKDM stg_account_cris per
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   run_sql  mkdm_stg_account_cris $CDW_DB_LINK $RBS_LARGE 

   check_status
fi

#-----------------------------------------------------------------
step_number=4
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   build_all mkdm stg_account_cris per
   check_status
fi

echo $(date) done
exit 0
