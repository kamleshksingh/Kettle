#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_con_prospect_qual_temp.sh
#**
#** Job Name        :  LDCONPROS
#**
#** Original Author :  Vandana Kushwaha
#**
#** Description     :  Script to populate con_prospect_qual_temp to house 
#**                    VOIP,BSI,CO INdr,MISMAILED indr and DSL column for
#**                    acxiom_nq_tbl in CRDM. The job will refresh the table weekly.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 05/07/2007 vkushwa  Initial check in
#** 06/21/2007 vkushwa  Removed BSI columns and added new columns from new 
#**                     DSL_QUAL_CON_PROSPECT_ACCT table US-526632
#*****************************************************************************

#test hook
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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST data_tablespace index_tablespace

#-----------------------------------------------------------------
step_number=1
#Description: Create MASTER_ACXIOM_NQ_TEMP table to get MAID,co_addr_indr
#             mismailed_indr and sys_sce_key information for acxiom_nq.The 
#             source of these columns are master_address_xref 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_acxiom_nq_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Analyze table MASTER_ACXIOM_NQ_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ACXIOM_NQ_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Creating con_prospect_qual_temp to house all VOIP
#              Co and Mismailed indicator and Broadband information for
#             Acxiom_nq dsl Updates.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_con_prospect_qual_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Analyze table CON_PROSPECT_QUAL_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM CON_PROSPECT_QUAL_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: drop temp tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drop_tmp_acxiom_nq.sql
   check_status
fi

echo $(date) done
exit 0
