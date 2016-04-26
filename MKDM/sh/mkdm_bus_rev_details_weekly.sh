#!/bin/ksh
#*******************************************************************************
#** Program         :  	mkdm_bus_rev_details_weekly.sh
#** 
#** Job Name        :  	BUSREVDTL
#**
#** Original Author :  	mmuruga
#**
#** Description     :  	This script pulls revenue information weekly into 
#**			BUSINESS_REVENUE_DET from STG_MKDM_BKD_BLG_DTL and
#**                     MKDM_LOAD_CONTROL tables in FINEDW. 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 02/24/2007 mmuruga	Initial checkin.
#*****************************************************************************

#test hook
#. ~/.mkdm_env
. $FPATH/common_funcs.sh

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
check_variables start_step ORA_CONNECT data_tablespace index_tablespace EDW_DB_LINK

#-----------------------------------------------------------------
step_number=1
# Description: 	Create Partition for all missed out partitions of
#	       	BUSINESS_REVENUE_DET table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    echo "*** Step Number $step_number"
    create_partition BUSINESS_REVENUE_DET
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description:	Insert records into BUSINESS_REVENUE_DET table from
#		STG_MKDM_BKD_BLG_DTL and MKDM_LOAD_CONTROL tables in
#		FINEDW. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_bus_rev_dtl.sql $OUTDIR/run_date.txt
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description:  Insert LATIS records into BUSINESS_REV_DET_LATIS table from
#               STG_MKDM_BKD_BLG_DTL and MKDM_LOAD_CONTROL tables in
#               FINEDW.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_date=`cat $OUTDIR/run_date.txt`
   run_sql mkdm_ld_bus_rev_dtl_lat.sql $run_date
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Analyze BUSINESS_REVENUE_DET Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm BUSINESS_REVENUE_DET 5
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Analyze BUSINESS_REV_DET_LATIS Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm BUSINESS_REV_DET_LATIS 5
   check_status
fi

rm -f $OUTDIR/run_date.txt

echo $(date) done
exit 0
