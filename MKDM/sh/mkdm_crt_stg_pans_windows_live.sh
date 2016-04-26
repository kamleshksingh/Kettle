#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_crt_stg_pans_windows_live.sh
#**
#** Job Name        :  STGPANSWL
#**
#** Original Author :  dxpanne
#**
#** Description     :  To create a staging table to pull data from PANS Source
#**                    to populate windows live indicator
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/10/2008 dxpanne  Initial checkin.
#** 10/07/2013 czeisse  Changing DB LINK for PANS because PANS EOSL
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
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
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT data_tablespace index_tablespace
check_variables LINK_TO_PANS_DWOPS

#-----------------------------------------------------------------
step_number=1
# Description: To drop and create the staging table stg_pans_windows_live
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_stg_pans_windows_live.sql $data_tablespace $LINK_TO_PANS_DWOPS
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: To create index on the table stg_pans_windows_live
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_stg_pans_windows_live.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Analyze STG_PANS_WINDOWS_LIVE table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM STG_PANS_WINDOWS_LIVE 5
    check_status
fi

echo $(date) done
exit 0
