#*******************************************************************************
#** Program         :  mkdm_ld_lu_circuits.sh
#**
#** Job Name        :  LDLUCIRT
#**
#** Original Author :  Vandana Kushwaha
#**
#** Description     :  The job loads LU_CIRCUITS table in MKDM. Source of
#**                    the data is LU_CIRCUITS(BASECAMP Databse) table.
#**                    The job is weekly refresh.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 06/06/2007 vkushwa  Initial checkin.
#** 01/12/2011 sxlank2 changed source from DSMLMT to basecamp
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
# Description: Create the  LU_CIRCUITS table  from the
#              LU_CIRCUITS(BASECAMP Databse).Table has clli,luid and wtn
#              information of LU_CIRCUITS.
#              wtn is used to populate in WORK_NETWORK      
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_framework_lu_circuits.sql $data_tablespace $BASECAMP_DB_LINK
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Create index on LU_CIRCUITS table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_crt_lu_circuits_idx.sql $index_tablespace
    check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Analyze LU_CIRCUITS Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    analyze_table mkdm LU_CIRCUITS 5
    check_status
fi

echo $(date) done
exit 0
