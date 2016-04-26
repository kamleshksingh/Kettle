#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_master_address_key.sh
#**
#** Job Name        :  LDMADDRKEY
#**
#** Original Author :  vxragun
#**
#** Description     :  Populate MASTER_ADDRESS_KEY from MASTER_ADDRESS_XREF.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 09/07/2006 vxragun  Initial Checkin
#*****************************************************************************


#. ~/.mkdm_env
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
check_variables data_tablespace index_tablespace

#-----------------------------------------------------------------
step_number=1
#Description: Create MASTER_ADDRESS_KEY_STG1  from MASTER_ADDRESS_XREF
#	      with MAID and key values of the pulling source.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_key_stg1.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Analyze MASTER_ADDRESS_KEY_STG1 table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_KEY_STG1 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Create MASTER_ADDRESS_KEY_STG2 from MASTER_ADDRESS_KEY_STG1
#	      by filtering on address type.     
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_key_stg2.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Rename MASTER_ADDRESS_KEY_STG2 to MASTER_ADDRESS_KEY.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rename_master_address_key.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Create indexes on MASTER_ADDRESS_KEY table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_master_address_key.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Analyze MASTER_ADDRESS_KEY table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_KEY 5
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Create views on MASTER_ADDRESS_KEY table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_vw_master_address_key.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Drop temp tables.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drop_mast_addr_key_temp.sql
   check_status
fi

exit 0
