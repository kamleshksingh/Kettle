#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_crt_dsl_qual_acct.sh
#**
#** Job Name        :  CRTDSLQUAL
#**
#** Original Author :  Lakshmi Narasimhan
#**
#** Description     :  Creates a temporary table dsl_qual_acct with all dsl information.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 10/05/2006 lnarasi  Initial checkin.
#** 11/23/2006 urajend  Changes to dsl_qualification.
#** 12/07/2006 nbeneve  Added WTN Matched CRIS records to dsl_qual_acct table
#** 02/22/2007 urajend  Modified to adjust the est_impltn_dt date logic.
#** 06/25/2007 kpilla   Removed steps to create temp tables dsl_qual_no_oth and dsl_qual_no_oth2 
#**                     and changed steps 1 and 3 to get current records using cur_rec_indr column 
#**                     and replaced dsl_qual_acct_ref with common_dsl_qual_ref table. 
#** 10/24/2007 kpilla   Splitted step of creation of dsl_qual_oth3 table to 3 steps.
#** 10/12/2007 sxsub10  Population of dsl qualification for active CRIS and 
#**                     their associated LATIS accounts is based on WTN
#**06/04/2013  kxsing3  Added step 1 and step 2 in the process, and modified step 3 as part of performance improvment: MTB# 502.
#**
#**
#*****************************************************************************

#test hook
#. ~/.setup_env
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_string=$(date '+%Y%m%d')
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
common_tablespace=$1

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
date

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT EDW_DB_LINK
check_variables data_tablespace index_tablespace

#-----------------------------------------------------------------
step_number=1
# Description: Create a temporary table temp_dsl_qual_srv with records having serviceable addresses
#              
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_srv.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Create a index on temporary table temp_dsl_qual_srv
#              
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_temp_dsl_qual_srv.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Create a temporary table dsl_qual_srv with records having serviceable addresses
#              and cur_rec_indr='Y'.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_srv.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Analyze DSL_QUAL_SRV table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_SRV 5
    check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Create dsl_qual_no_srv which doesn't contain any
#              serviceable addresses.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_no_srv.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Create index on dsl_qual_no_srv table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_dsl_qual_no_srv.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Analyze DSL_QUAL_NO_SRV table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_NO_SRV 5
    check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: create dsl_qual_oth3_temp1 table
#              from dsl_qual_no_srv
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_oth3_temp1.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: analyze  dsl_qual_oth3_temp1 table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_OTH3_TEMP1 5 
    check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: create dsl_qual_oth3 table
#              from dsl_qual_oth3_temp1 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_oth3.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=11
# Description: Analyze DSL_QUAL_OTH3 table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_OTH3 5
    check_status
fi

#-----------------------------------------------------------------
step_number=12
# Description: To create Active CRIS qualification records using account_key_ref 
#              and work_network based on WTN
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_active_cris_qual.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=13
# Description: To create index on active_cris_qual
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_active_cris_qual.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=14
# Description: To analyze table active_cris_qual 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM ACTIVE_CRIS_QUAL 5
    check_status
fi

#-----------------------------------------------------------------
step_number=15
# Description: To create associated LATIS accounts 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_assoc_latis_rec.sql $data_tablespace $EDW_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=16
# Description: To create associated LATIS qualification
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_assoc_latis_qual.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=17
# Description: To create temp table which contains both active 
#              CRIS and assoc LATIS qualification
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_active_qual_temp.sql  $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=18
# Description: To create index on active_qual_temp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_idx_active_qual_temp.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=19
# Description: To analyze table active_qual_temp 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM ACTIVE_QUAL_TEMP 5
    check_status
fi

#-----------------------------------------------------------------
step_number=20
# Description: To create temp table which contains dsl 
#              qualification based on addresses
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_addr_tbl.sql $data_tablespace
    check_status
fi

#----------------------------------------------------------------
step_number=21
# Description: Create dsl_qual_addr_temp_del table.
#               which contains the records to be deleted from dsl_qual_addr_temp
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_addr_del_tbl.sql $data_tablespace
    check_status
fi

#----------------------------------------------------------------
step_number=22
# Description: To delete records from dsl_qual_addr_temp
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_dsl_qual_addr_temp.sql 
    check_status
fi

#----------------------------------------------------------------
step_number=23
# Description: Create dsl_qual_acct_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_acct_tbl.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=24
# Description: Analyze table dsl_qual_acct_temp
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_ACCT_TEMP 5
    check_status
fi

#-----------------------------------------------------------------
step_number=25
# Description: Deletes records from DSLQUAL partition of common_dsl_qual_ref table 
#               which are disqualified for more than 12 months.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_dsl_qual_acct_ref.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=26
# Description: Create common_dsl_qual_acct_ref_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_acct_ref.sql $common_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=27
# Description: Exchange DSLQUAL partition of common_dsl_qual_ref with
#              common_dsl_qual_acct_ref_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_exchg_common_dsl_qual_ref.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=28
# Description: Analyze partition table common_dsl_qual_ref
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_partition_table MKDM COMMON_DSL_QUAL_REF DSLQUAL 5
    check_status
fi

#-----------------------------------------------------------------
step_number=29
# Description: Create dsl_qual_acct_temp1 table.
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_temp_dsl_qual_acct_temp1.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=30
# Description: Drop and rename the dsl_qual_acct_temp1 to dsl_qual_acct table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_rename_dsl_qual_acct.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=31
# Description: Analyze DSL_QUAL_ACCT table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table MKDM DSL_QUAL_ACCT 5
    check_status
fi

#-----------------------------------------------------------------
step_number=32
# Description: Drop the temp tables.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drop_dsl_qual_tbls.sql
    check_status
fi

echo $(date) done
exit 0
