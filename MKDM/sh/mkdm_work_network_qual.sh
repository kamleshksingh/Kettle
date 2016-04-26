#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_work_network_qual.sh
#**
#** Job Name        :  
#**
#** Original Author :  Vandana Kushwaha
#**
#** Description     :  Script to populate NETWORK_QUAL for first time
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 09/21/2006 vkushwa  Initial check in
#** 06/01/2007 rananto  Included step to create index on network_qual table
#** 06/06/2007  sxsub10 modified to create network_qual table with new
#**                     structural changes done to work_network and network_qual
#** 09/03/2007  sxsub10 Added step to drop master_address_temp
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
#Description: Creating master_address_temp table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_master_address_temp.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Analyze table MASTER_ADDRESS_TEMP
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MASTER_ADDRESS_TEMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Creating network_qual_n
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_network_qual_n.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Renaming NETWORK_QUAL_N to NETWORK_QUAL
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_network_qual_rename.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Creating index on network_qual table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_network_qual_indx.sql $index_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description: Analyze table NETWORK_QUAL
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM NETWORK_QUAL 5
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Drop table master_address_temp
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_master_address_temp.sql
   check_status
fi
echo $(date) done
exit 0

