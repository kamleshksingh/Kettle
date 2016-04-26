#!/bin/ksh
#*******************************************************************************
#** Program         :  dns_to_rsor.sh 
#** 
#** Job Name        :  DNSRSOREXT
#** 
#** Original Author :  kwillet 
#**
#** Description     : The Script would be used to createi RSORTN.dat,
#**                   The Source tables for these dat file are 
#**                   1)DNS_RESTRICT_STAGE
#**                   2)DNS_TN_MSTR
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 02/01/2006 kwillet  Initial Checkin 
#** 02/13/2006 kwillet  Remove the 7 from RSR7 in the data set name for production.
#** 03-06-2006 kshenba  BAU-374095,Change archive directory for DNSRSOREXT 
#** 10/05/2007 jannama  Included the DNS_DB_LINK variable for DNS
#** 11/22/2010 mxlaks2  Linux Migration
#*****************************************************************************
#test hook

. ~/.mkdm_env
   
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_ran=$(date '+%Y%m%d')

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

function check_ftp_status
{
   error_count=0
   error_count=`grep -c "Transfer complete" ${LOGDIR}/RSOR_DUMP_FTP.$$.log`
   if [ ${error_count} -eq 0 ]; then 
      for error_string in "Connection refused" \
	"Unable to send" \
	"Login failed" \
	"Requested action not taken" \
	"No such file or directory" \
	"User is not allowed" \
        "User not authorized" \
        "Invalid command" \
	"Not connected" \
	"No space left on device" 
      do
	error_count=`grep -c "${error_string}" ${LOGDIR}/RSOR_DUMP_FTP.$$.log` 
	if [ $error_count -ne 0 ]; then
 	   echo "Error. $error_string, Please check $LOG_FILE for more details."
 	   err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
	   echo "$err_msg"
	   subject_msg="Job Error - $L_SCRIPTNAME"
	   send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
	   exit $step_number
	fi
      done
fi
}

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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST DNS_DB_LINK
check_variables RSOR_FTP_USER RSOR_FTP_PASSWD RSORARCHIVEDIR
check_variables DATADIR LOGDIR

#-----------------------------------------------------------------
step_number=1
#Description: Create RSORTN.dat file from DNS_RESTRICTIONS,
#  	      and DNS_TN_MSTR tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql dns_tndmp_rsor.sql ${DNS_DB_LINK} 
   check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: FTP the RSORTN data to the RSOR Mainframe
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
cd ${DATADIR}
ftp -inv ${RSOR_NODE}  1> $LOGDIR/RSOR_DUMP_FTP.$$.log 2>&1 << FTPEOF  
user ${RSOR_FTP_USER} ${RSOR_FTP_PASSWD}
ascii
quote "SITE LRECL=10 RECFM=FB CYLINDERS PRIMARY=25 SECONDARY=10 BLKSIZE=32000"
cd rsr
put RSORTN.dat 'rsr.#usw.rsrprotc.donotcal(+1)' 
bye
FTPEOF
check_ftp_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Move the RSORTN data to the Archive Directory 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
cd ${DATADIR}
mv RSORTN.dat ${RSORARCHIVEDIR}/RSORTN.dat.${date_ran}
   check_status
cd ${RSORARCHIVEDIR}
zip RSORTN.dat.${date_ran}.Z RSORTN.dat.${date_ran}
   check_status
fi 

exit 0
