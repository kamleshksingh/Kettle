#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_crt_dsl_qual_bus_prospect.sh
#**
#** Job Name        :  BUSDSLPROS
#**
#** Original Author :  kpilla
#**
#** Description     :  Creates a table dsl_qual_bus_prospect with all dsl information.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 18/07/2007 kpilla  Initial checkin.
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
# Description: Create a temporary table dsl_qual_bus_prospect_temp
#             with dsl information 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_bus_prospect_temp.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Analyze DSL_QUAL_BUS_PROSPECT_TEMP table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm dsl_qual_bus_prospect_temp 5
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Deletes records from EXTERNAL partition of common_dsl_qual_ref table which are 
#             disqualified for more than 12 months.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_del_dsl_qual_bus_prospect.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Create common_dsl_qual_ref_temp table.  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_external_common_dsl_qual_temp.sql $common_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Exchange EXTERNAL partition of common_dsl_qual_ref with
#               common_dsl_qual_ref_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_exchg_external_common_dsl_qual_ref.sql 
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Analyze EXTERNAL partition of common_dsl_qual_ref table. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_partition_table mkdm common_dsl_qual_ref EXTERNAL 5
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Creates dsl_qual_bus_prospect_temp1 table. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_dsl_qual_bus_prospect_external.sql $data_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Drop and rename the dsl_qual_bus_prospect_temp1 to dsl_qual_bus_prospect table 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_rename_dsl_qual_bus_prospect.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Analyze table dsl_qual_bus_prospect. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm dsl_qual_bus_prospect 5
    check_status
fi

echo $(date) done
exit 0
