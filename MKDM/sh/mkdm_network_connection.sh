#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_network_connection.sh
#** 
#** Job Name        :  
#** 
#** Original Author : bxbail3
#**
#** Description     :  
#**                   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
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
     send_mail "$err_msg" "$subject_msg" "$MAIL_LIST"
     exit $step_number
  fi
}

function send_mail {
   print $1||mail -s "$2" "$3"
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
start_step=${start_step:=1}

#-----------------------------------------------------------------
step_number=1
#Description:  
#-----------------------------------------------------------------
echo "Executing Step: $step_number"
if [ $start_step -le  $step_number ] ; then
   sqlplus -s $ORA_CONNECT_MKDM  <<_EOF_
      WHENEVER OSERROR EXIT FAILURE
      WHENEVER SQLERROR EXIT FAILURE
      @${SQLDIR}/network_connection $CDW_DB_LINK
_EOF_
   check_status  
fi

#-----------------------------------------------------------------
#step_number=$
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="Table network_connection loaded successfully"
subject_msg="network_connection loaded successfully"
send_mail "$success_msg" "$subject_msg" "MAIL_LIST"
check_status

exit 0
