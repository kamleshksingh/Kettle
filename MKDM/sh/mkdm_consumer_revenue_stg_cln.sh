#!/bin/ksh
#*******************************************************************************
#** Program         :   mkdm_consumer_revenue_stg_cln.sh
#**
#** Job Name        :   CONSTGCLN
#**
#** Original Author :   dxkumar
#**
#** Description     :   This script cleans up the staging table CCDW_STG_BKD_BLG_DTL
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 08/10/2006 dxkumar  Initial checkin.
#** 05/29/2008 ssagili  Changed the logic to get the load_control_key 
#** 01/09/2008 jannama  Changed error handling in Step 2
#** 12/09/201  txmx     Added the cleaning of CCDW_STG_BKD_BLG_DTL table
#**                     STG_MKDM_BKD_BLG_DTL clean up process will be removed after
#**                     FINEDW decomission
#** 02/07/2012 czeisse  removing scripts that clean STG_MKDM_BKD_BLG_DTL.
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
# Set $ parameters here.
#-----------------------------------------------------------------


#-----------------------------------------------------------------
# Function to check the return status and set the appropriate # message
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then
     if [ $# -eq 2 ]; then 
        err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
        echo "$err_msg"

        subject_msg="Job Error - $L_SCRIPTNAME"
        send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
        exit $2
     else
        err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
        echo "$err_msg"

        subject_msg="Job Error - $L_SCRIPTNAME"
        send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
        exit $step_number
    fi  
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

export  ORA_CONNECT_MKDM=$ORA_CONNECT

#-----------------------------------------------------------------
step_number=1
# Description: To drop the partitions from CCDW_STG_BKD_BLG_DTL
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    export ORA_CONNECT=$ORA_CONNECT_MKDM
    run_sql mkdm_ccdw_stg_bkd_blg_dtl_clnup.sql
    check_status
fi
#-----------------------------------------------------------------
step_number=2
# Description: Analyze CCDW_STG_BKD_BLG_DTL Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm CCDW_STG_BKD_BLG_DTL 5
    check_status
fi


echo $(date) done
exit 0

