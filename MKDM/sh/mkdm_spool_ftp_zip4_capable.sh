#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_spool_ftp_zip4_capable.sh
#**
#** Job Name        : MKDMZIPFTP
#**
#** Original Author : Loveen Mittal
#**
#** Description     : Driver script that spools and FTP the Zip Code+4 data 
#**                   files the availability of DSL, Prism, and other consumer products   
#**                   with Alternative Partners.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/18/2013 aa49920	Initial checkin
#*****************************************************************************

##############################################################################
# Comment these test hooks before deilvery
##############################################################################
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of #this script. d for Debug is always the default
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

DAT_FILE_NM=ZIP4_PRISM_HSI_CAPABLE.DAT
echo $DAT_FILE_NM

SPOOL_PATH=/opt/stage01/mkdm
echo $SPOOL_PATH

#-----------------------------------------------------------------
# Function to check the return status, set the appropriate # message
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then

 err_msg="$L_SCRIPTNAME (MKDMZIPFTP)    Errored at Step: $step_number"
  echo "Process failed at the Step:  $step_number" 
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
check_variables start_step ORA_CONNECT data_tablespace 
check_variables ALT_SFTP_USER ALT_SFTP_PATH ALT_SFTP_SERVER ALT_MAIL_LIST 
check_variables index_tablespace CRDM_DB_LINK MKDM_ERR_LIST

#-----------------------------------------------------------------
step_number=1
#Description: Spool file.
#-----------------------------------------------------------------
if [ $start_step -le  $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_spool_zip4_prism_hsi_capable.sql $SPOOL_PATH/$DAT_FILE_NM $CRDM_DB_LINK
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Error handling in case the file is not generated in
#             spool path or if its size is less than 50 MB.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   cd $SPOOL_PATH

   FSIZE=`du -sm $SPOOL_PATH/$DAT_FILE_NM | cut -f1`

   if [[ ! -f $DAT_FILE_NM ]] || [[ $FSIZE  -lt 50 ]] ; then
   print "Filesize is $FSIZE MB"

   err_msg="Zip+4 Prism and HSI Capable file extract failed. File size is less than 50 MB. Please check the file."
      subject_msg="Zip+4 Prism and HSI Capable file extract failed at Step: $step_number"
      send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
      exit $step_number
   else

   echo "File is present and is $FSIZE MB in size."

   check_status

   fi


fi

#-----------------------------------------------------------------
step_number=3
# Description: SCP file to FTP server         
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   cd $SPOOL_PATH
   echo "*** Step Number $step_number"
   scp $DAT_FILE_NM $ALT_SFTP_USER@$ALT_SFTP_SERVER:$ALT_SFTP_PATH
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Remove file from MKDM server
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   cd $SPOOL_PATH
   echo "*** Step Number $step_number"
   rm -f $DAT_FILE_NM
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Send mail
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
         success_msg="Zip+4 Prism and HSI Capable file extract process finished successfully. File loaded to the ftp.qwest.com server"
	 subject_msg="Zip+4 Prism and HSI Capable file extract process finished successfully"
         send_mail "$success_msg" "$subject_msg" "$ALT_MAIL_LIST"
    check_status
fi


echo $(date) done
exit 0
