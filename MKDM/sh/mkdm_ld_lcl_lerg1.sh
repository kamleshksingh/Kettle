#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_lcl_lerg.sh
#**
#** Job Name        :  
#**
#** Original Author :  Karthick
#**
#** Description     :  Loading LERG tables.The tables were pulled from LOSDB database.
#**           
#**   Table Names		Description     
#**      
#**   LCL_LERG1      -     Raw data from LERG1 - OCN/Company Names/Contact info.                   
#**   LCL_LERG10     -     Raw Data from LERG10 - Operator Service Codes by NPA/NXX.
#**   LCL_LERG11     -     Raw Data from LERG11 - Operator Service Codes by Locality.
#**   LCL_LERG12     -     Raw Data from LERG12 - Location Routing Numbers.
#**   LCL_LERG14     -     Raw Data from LERG14 - Diverse Toll Routing.
#**   LCL_LERG1CON   -     Raw data from LERG1CON - OCN/Additional Contact info.    
#**   LCL_LERG2      -     Raw data from LERG2 - Country Codes.
#**   LCL_LERG3      -     Raw data from LERG3 - NPA Listing - Numerical - 
#**    		           Includes NPA split information.
#**   LCL_LERG4      -     Raw data from LERG4 - Common Channeling Signaling (SS7)Codes
#**                        (high-level point code information).
#**   LCL_LERG5      -     Raw data from LERG5 - LATA Codes by Region.
#**   LCL_LERG6_BASE -     Raw Data from LERG6 - Destination Code (NPA/NXX).
#**   LCL_LERG7      -     Raw Data from LERG7 - Switching Entities.
#**   LCL_LERG7_SHA  -     Raw Data from LERG7SHA - Switch Homing Data.
#**   LCL_LERG8      -     Raw data from LERG8 - Rate Centers.
#**   LCL_LERG8_LOC  -     Raw Data from LERG8_LOC - Localities per Rate Center.
#**   LCL_LERG9      -     Raw data from LERG9 - Homing Arrangements.
#**   LCL_LERG6      -     Destination Codes (NPA/NXX) and Thousands Block Pooling Assignments.
#**   LCL_LERG13     -     Derived from LERG13_BASE and CNUM - Thousands Block Assignments.
#**   LCA_XDSL       -     Contains information on all Wire Center xDSL capabilities.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/22/2005 kshenba  Initial Checkin
#*****************************************************************************

#test hook
#. setup_env
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
export TABLE_NAME=$1

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
check_variables start_step ORA_CONNECT MAIL_LIST TABLE_NAME LOSDB_DB_LINK

#-----------------------------------------------------------------
step_number=1
#Description: Loading LERG tables.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_ld_lerg_tbl1.sql $TABLE_NAME $LOSDB_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Analyzing LERG tables.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table mkdm $TABLE_NAME 50
   check_status
fi

#-----------------------------------------------------------------
#step_number=3
#Description: send_mail common function is called for successfull
# completion and email notification.
#-----------------------------------------------------------------
#success_msg="$TABLE_NAME loaded successfully on `date ` ."
#subject_msg="$TABLE_NAME Loaded!!"
#send_mail "$success_msg" "$subject_msg" "$MAIL_LIST"
#check_status

exit 0
