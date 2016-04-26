#!/bin/ksh
#*******************************************************************************
#** program         :  mkdm_crt_dsl_qual_con_prospect_acct.sh
#**
#** Job Name        :  CONDSLPRT
#**
#** Original Author :  urajend
#**
#** Description     :  Creates a temporary table dsl_qual_con_prospect_acct with all dsl information.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 11/02/2006 urajend  Initial checkin.
#** 05/21/2007 vkushwa  Added VOIP cabable indr Logc US-511843
#** 07/18/2007 ddamoda  Changed the script to add 2 dates, ACCT_EST_IMPLTN_DT 
                        and MIN_LINE_EST_IMPLTN_DT US-531442 
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
check_variables start_step ORA_CONNECT

#-----------------------------------------------------------------
step_number=1
# Description: Create temp table for VOIP indicator,updated during weekly
#              switchout. Sourced from voip_rate_center and
#              master_adrs_rate_center_xref.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_voip_indicator_temp.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Analyze voip_indicator_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm VOIP_INDICATOR_TEMP 5
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Create a temporary table dsl_qual_con_prospect_acct_temp
#             with dsl information and voip_capable indicator.
#             source are voip_indicator_temp, master_address_xref
#             and network_qual
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_con_prospect_acct_temp.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Analyze DSL_QUAL_CON_PROSPECT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm dsl_qual_con_prospect_temp 5
    check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Drop voip_indicator_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drop_voip_indicator_temp.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Deletes records from ACXIOM_NQ partition of common_dsl_qual_con_ref table which are
#             disqualified for more than 12 months.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_dsl_qual_con_prospect.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Create common_dsl_qual_con_ref_temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_acxiom_nq_common_dsl_qual_temp.sql $common_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Exchange ACXIOM_NQ partition of common_dsl_qual_con_ref with
#               common_dsl_qual_con_ref_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_exchg_acxiom_nq_common_dsl_qual_ref.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Analyze ACXIOM_NQ partition of common_dsl_qual_con_ref table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_partition_table mkdm common_dsl_qual_ref ACXIOM_NQ 5
    check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Creates dsl_qual_con_prospect_temp1 table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_con_prospect_acxiom_nq.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=11
# Description: Drop and rename the dsl_qual_con_prospect_temp1 to dsl_qual_con_prospect table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_rename_dsl_qual_con_prospect.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=12
# Description: Analyze table dsl_qual_con_prospect_acct.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm dsl_qual_con_prospect_acct 5
    check_status
fi


echo $(date) done
exit 0
