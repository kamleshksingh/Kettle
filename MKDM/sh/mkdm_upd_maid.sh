#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_upd_maid.sh
#**
#** Job Name        :    
#**
#** Original Author :  nbeneve
#**
#** Description     :  Script to update MAID/NCOA_MAID in target table from master_address_archive
#**                 :  Takes 3 parameters from PARM_LIST 
#**                    1. Table Name
#**                    2. mast_pri_address_id/ncoa_mast_pri_address_id
#**                    3. mast_sec_address_id/ncoa_mast_sec_address_id 
#**
#**                    eg : <table_name> mast_pri_address_id mast_sec_address_id 
#**                         <table_name> ncoa_mast_pri_address_id ncoa_mast_sec_address_id
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/05/2008 nbeneve  Initial Checkin
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
table_name=$1
column_name1=$2
column_name2=$3
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
#Description: Create temp table with rowid for update process
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
run_sql mkdm_crt_rowid_tmp_tbl.sql ${table_name} ${data_tablespace} ${column_name1} ${column_name2}
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Create index on rowid
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql crt_idx_rowid_tmp_tbl.sql ${table_name} ${data_tablespace}
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Analyze temp table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM ${table_name}_rtmp 5
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Update target table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_target_tbl.sql ${table_name} ${column_name1} ${column_name2}
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Drop temp table
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql drop_rowid_tmp_tbl.sql ${table_name}
   check_status
fi

exit 0
