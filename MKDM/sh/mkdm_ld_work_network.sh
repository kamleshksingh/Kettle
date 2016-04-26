#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_work_network.sh
#**
#** Job Name        :  LDWRKNET
#**
#** Original Author :  Vandana Kushwaha
#**
#** Description     :  The job loads WORK_NETWORK table in MKDM. Source of
#**                    the data is Master_Marketing_Data(BASECAMP Databse) table.
#**                    The job is weekly refresh.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 05/28/2007 vkushwa  Initial checkin.
#** 01/11/2011 sxlank2  Changed source from DSLMT to basecamp 
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
#Command line arguments may be adjusted according to the needs of
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
date

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT data_tablespace index_tablespace
check_variables BASECAMP_DB_LINK

#-----------------------------------------------------------------
step_number=1
# Description: Create temporary tables for  basecamp in  MKDM
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_framework_temp_tables.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Create LU_QUAL_TEMP TABLE  in MKDM.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_framework_lu_qual_tmp.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi
#-----------------------------------------------------------------
step_number=3
# Description: Create lu_qual_backhaul temp table with backhaul restrction column

#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_framework_lu_qual_backhaul.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Insert records into lu_qual_backhaul with backhaul restriction column

#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_ins_framework_lu_qual_backhaul.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi
#-----------------------------------------------------------------
step_number=5
# Description: Create final temp table lu_qual_da with along with DA column

#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_framework_lu_qual_da.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Insert records into lu_qual_da with DA column

#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_ins_framework_lu_qual_da.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Create the  WORK_NETWORK_TEMP table  from the
#              Master_Marketing_Data(BASECAMP Databse).Table has clli,da,luid
#              information as well as other columns of Master_Marketing_Data.
#              SQL drops the WORK_NETWORK_TEMP table and then creats with
#              same structure as WORK_NETWORK. Then inserting the records
#              into WORK_NETWORK_TEMP from Master_Marketing_Data.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_work_network_temp.sql $data_tablespace 
    check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Drop the WORK_NETWORK table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drop_work_network.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: Rename the WORK_NETWORK_TEMP table to WORK_NETWORK.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_work_network_tbl.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Create index for WORK_NETWORK table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_work_network_idx.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=11
# Description: Analyze WORK_NETWORK Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm work_network 50
    check_status
fi


echo $(date) done
exit 0
