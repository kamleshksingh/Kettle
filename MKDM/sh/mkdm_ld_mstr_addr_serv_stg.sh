#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_mstr_addr_serv_stg.sh
#**
#** Job Name        :  LDMSTRSTG
#**
#** Original Author :  Praveen T
#**
#** Description     :  Script to Populate master_address_serv_stg table which has
#**                    contain Service address information and Account Type
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 10/03/2006 pxthiru  Initial Checkin
#** 03/22/2007 nbeneve  Removed steps to get cbsa name from cdw_switch
#*****************************************************************************
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
#Description: Create master_address_qual_temp from master_address
#             and network_qual.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_qual_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Create index on master_address_qual_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_qual_temp.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Analyze master_address_qual_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_QUAL_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Create mast_addr_cbsa_tmp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_addr_cbsa_tmp.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Analyze mast_addr_cbsa_tmp table .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MAST_ADDR_CBSA_TMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Create mast_addr_cbsa table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_mast_addr_cbsa.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Analyze mast_addr_cbsa table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MAST_ADDR_CBSA 5
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: Create master_address_ntwk_temp from work_network
#              and master_address_xref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_ntwk_temp.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description: Analyze master_address_ntwk_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_NTWK_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: Create stg_wtn_no_addr_match from master_address_ntwk_temp
#             and Account_key_ref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_stg_wtn_no_addr_match.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Analyze stg_wtn_no_addr_match table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM STG_WTN_NO_ADDR_MATCH 5
   check_status
fi

#-----------------------------------------------------------------
step_number=12
#Description: Create master_address_serv_temp from master_address_qual_temp.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_serv_temp.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=13
#Description: Analyze master_address_serv_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_SERV_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=14
#Description: Create master_address_serv_stg from master_address_serv_temp
#              and cbsa_ref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_serv_stg.sql $data_tablespace 
   check_status
fi

#-----------------------------------------------------------------
step_number=15
#Description: Analyze master_address_serv_stg table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_SERV_STG 5
   check_status
fi

#-----------------------------------------------------------------
step_number=16
#Description: Insert new cbsa_name in CBSA_REF table from temp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_cbsa_ref.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=17
#Description: Analyze table CBSA_REF
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM CBSA_REF 5
   check_status
fi

#-----------------------------------------------------------------
step_number=18
#Description: Drop temp tables created during master_address_serv_stg.
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drop_master_addr_tmp_tbls.sql $data_tablespace
   check_status
fi

exit 0
