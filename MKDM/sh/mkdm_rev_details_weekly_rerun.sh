#!/bin/ksh
#*******************************************************************************
#** Program         :  	mkdm_rev_details_weekly_rerun.sh
#** 
#** Job Name        :  	MKDMREVDRR
#**
#** Original Author :  	ssagili
#**
#** Description     :  	This script pulls revenue information weekly into 
#**		        MKDM_REVENUE_DET from CCDW_STG_BKD_BLG_DTL_RERUN and CRTS_B584_DIM
#**
#**  NOTE:   ****  Do Not Run At same time as the Normal processes:
#**                     Weekly:  MKDMREVDTL & QTAREVLD
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 05/29/2008 ssagili	Initial checkin.
#** 11/15/2010 aramana  Modified the scrip to include MKDM_REVENUE_DET_TEMP table process.
#** 04/04/2012 vbeatty  Modified to use the CCDW_STG_BKD_BLG_DTL_RERUN table
#*****************************************************************************

#test hook
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

start_step=0

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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST


#-----------------------------------------------------------------
step_number=1
# Description:  Insert records into MKDM_REVENUE_DET_TEMP_RERUN table from
#               CCDW_STG_BKD_BLG_DTL_RERUN, and CRTS_B584_DIM
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   echo $data_tablespace
   run_sql mkdm_ld_rev_dtl_temp_rerun.sql $data_tablespace
   check_status
fi
#-----------------------------------------------------------------
step_number=2
# Description:	Insert records into MKDM_REVENUE_DET table from
#		MKDM_REVENUE_DET_TEMP_RERUN
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_rev_dtl_rerun.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description:	To rebuild the unusable indexes on MKDM_REVENUE_DET
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_rebuild_unusable_indexes_rev_det.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Analyze MKDM_REVENUE_DET Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    echo "*** Step Number $step_number"
    run_sql mkdm_revenue_det_analyze.sql
    check_status
fi

echo $(date) done
exit 0
