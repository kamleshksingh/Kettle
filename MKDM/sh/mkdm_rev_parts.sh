#!/bin/ksh
#*******************************************************************************
#** Program         :  	mkdm_rev_parts.sh
#** 
#** Job Name        :  	REVDTLPART
#**
#** Original Author :  	ssagili
#**
#** Description     :  	This script compresses the partitions older than 3 months,
#**		        creates the next partition and drops the partitions older 
#**                     than 60 months in MKDM_REVENUE_DET Table.
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 05/29/2008 ssagili	Initial checkin.
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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST data_tablespace 
check_variables index_tablespace

#-----------------------------------------------------------------
step_number=1
# Description:	Drops partitions older than 60 months in 
#               MKDM_REVENUE_DET table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_rev_det_drop_part.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description:	Compresses partitions older than 3 months in
#               MKDM_REVENUE_DET table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_rev_det_compress_part.sql 
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description:	Creates new partition for  MKDM_REVENUE_DET
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_rev_det_create_part.sql $data_tablespace $index_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description:	Rebuilds the unusable indexes on MKDM_REVENUE_DET
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"
   run_sql mkdm_rebuild_unusable_indexes_rev_det.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Analyzes MKDM_REVENUE_DET Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
    echo "*** Step Number $step_number"
    analyze_table mkdm MKDM_REVENUE_DET 1
    check_status
fi

echo $(date) done
exit 0
