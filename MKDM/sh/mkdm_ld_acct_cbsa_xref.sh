#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_acct_cbsa_xref.sh
#**
#** Job Name        :  LDCBSAXREF
#**
#** Original Author :  urajend
#**
#** Description     :  Script to Populate master_addr_cbsa_stg table which
#**                    contains cbsa_cd,cbsa_name,service_zip populated from zip9_source
#**                    if a particular cbsa_cd or service_zip doesn't contain proper data.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/26/2007 urajend  Initial Checkin
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
#Description: The SQL script to create temp table which consists of cbsa information
#             from cbsa_ref by joining with master_address_xref
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_cbsa_xref_temp1.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Create index on acct_cbsa_xref_temp1
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_cbsa_xref_temp1.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: The SQL script to find the cbsa information from cbsa_ref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_cbsa_xref_temp2.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Create index on acct_cbsa_xref_temp2
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_cbsa_xref_temp2.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: The SQL script to find the cbsa information from zip9_source
#             using zip9 match.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_cbsa_xref_temp3.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Create index on acct_cbsa_xref_temp3
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_cbsa_xref_temp3.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: The SQL script to find the distinct dom_cbsa values from zip9_source.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_dom_cbsa_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=8
#Description: The SQL script to find the zip5 match.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_cbsa_xref_temp4.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=9
#Description: The SQL script to find the cbsa information .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_acct_cbsa_xref_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=10
#Description: creates indexes on acct_cbsa_xref_temp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_idx_acct_cbsa_xref_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=11
#Description: Drops the acct_cbsa_xref and the other temp tables and 
#             rename acct_cbsa_xref_temp to acct_cbsa_xref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rename_acct_cbsa_xref_temp.sql
   check_status
fi


exit 0
