#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_qta_revenue_reports.sh
#**
#** Job Name        : QTAREVLD
#**
#** Original Author : Thrinadh Vamsikrishna.M
#**
#** Description     : Loads Revenue data weekly for QTA 
#**                   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 11/15/2010 txmx  Initial Checkin
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

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
     send_mail "$err_msg" "$subject_msg" "$MAIL_LIST"
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

check_variables start_step ORA_CONNECT data_tablespace index_tablespace

step_number=1
# Description: Add new weely partition for QTA_REVENUE_DET
#----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_add_part_qta_rev_det.sql $data_tablespace
   check_status
fi
#----------------------------------------------------------------
step_number=2
# Description:  Insert records into QTA_REVENUE_DET table from
#               MKDM_REVENUE_DET_TEMP
#----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ins_qta_rev_det.sql
   check_status
fi
#-----------------------------------------------------------------
step_number=3
# Description: Analyze QTA_REVENUE_DET Table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"

max_part_name=`sqlplus -s $ORA_CONNECT <<EOT
        WHENEVER OSERROR EXIT FAILURE
        WHENEVER SQLERROR EXIT FAILURE
        SET HEADING OFF
        SET LINESIZE 500
        SELECT partition_name FROM user_tab_partitions
        WHERE table_name='QTA_REVENUE_DET' AND
        partition_position=(SELECT MAX(partition_position)
        FROM user_tab_partitions
        WHERE table_name='QTA_REVENUE_DET');
        EXIT;
EOT`
echo $max_part_name
    analyze_partition_table mkdm QTA_REVENUE_DET $max_part_name  5
    check_status
fi
#-----------------------------------------------------------------
step_number=4
# Description: Drop old partitions from QTA_REVENUE_DET table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql mkdm_drp_part_qta_rev_det.sql 
    check_status
fi


echo $(date) done
exit 0


