#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_rm_log_files.sh
#** 
#** Job Name        :  MKDMRMLG 
#** 
#** Original Author :  Poongundran A
#**
#** Description     :  Script to remove the old log files
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 02/22/2005 PANBALA  Initial checkin.
#** 02/13/2008 rananto  Changed the script to delete the log files older than 3 months

#*****************************************************************************

#test hook
#. ~/.setup_env 
#. $FPATH/common_funcs.sh
#. ~/.mkdm_env

L_SCRIPTNAME=`basename $0`

start_step=0


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
check_variables LOGDIR

#To Remove log files older than 90 days
step_number=1
if [ $start_step -le $step_number ]; then
   find ${LOGDIR} -mtime +90 -type f -exec rm -f  {} \;
   check_status
fi

echo $(date) done
exit 0
