#!/bin/ksh
#*******************************************************************************
#** Program         : dns_ocls_ofem.sh
#** 
#** Job Name        : DNSOCLSEXT  
#** 
#** Original Author : kenneth Willette 
#**
#**
#** Description     : The Script would be used to create  DNCLmmddX.dns,
#**                   The Source tables for these dat file are
#**                   1)DNS_DNC_DNE_TEMP
#**                   2)DNS_CDW_DNC_DNE_TEMP
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 10/04/2006 kwillet  Initial checkin.
#** 11/22/2010 mxlaks2  Linux Migration
#** 01/09/2013 kxsing3  updated function chk_ftp_errors
#*****************************************************************************

##############################################################################
# Comment these test hooks before deilvery
##############################################################################
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_string=$(date '+%Y%m%d')
start_step=0

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------
#-----------------------------------------------------------------
# Function for  FTPing file to  DNS Server
#-----------------------------------------------------------------
function ftp_exec
{
   ftp -niv ${DNS_FTP_BOX} >> ${LOGDIR}/DNS_ftpput_dnsoclsext$$.log << FTPEOF
   user ${DNS_FTP_USER} ${DNS_FTP_PASSWD}
   asc
   pwd
   $1
   dir
bye
FTPEOF
}
#-----------------------------------------------------------------
# Function for  Checking FTP errors
#-----------------------------------------------------------------
function chk_ftp_errors
{

 COUNT_FOUND=`egrep -i 'File receive OK' $LOGDIR/DNS_ftpput_dnsoclsext$$.log | wc -l`

   if [ $COUNT_FOUND -eq 0 ]; then

     err_msg="$L_SCRIPTNAME     Errored at Step: $step_number"
     echo "$err_msg"
     subject_msg="Job Error - $L_SCRIPTNAME"
     send_mail "$err_msg" "$subject_msg" "$MKDM_ERR_LIST"
     exit $step_number
   fi
}

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of 
#this script. d for Debug is always the default
#-----------------------------------------------------------------

while getopts "s:t:i:d:f" option
do
   case $option in
     s) start_step=$OPTARG;;
     t) data_tablespace=$OPTARG;;
     i) index_tablespace=$OPTARG;;
     d) debug=1;;
     f) date_string=$OPTARG;;  
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

FILEDATE=`date +'%m%d'`

export FILENAME=DNCL${FILEDATE}1.dns

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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST DNS_FTP_BOX DNS_FTP_USER DNS_FTP_PASSWD 

#-----------------------------------------------------------------
step_number=1
#Description: Drop the DNS_DNC_DNE_TEMP table that is created from
#             DNS data base via dblink
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql dns_drp_dnc_dne_tbl.sql
   check_status
fi
#-----------------------------------------------------------------
step_number=2
#  Description: Create the DNS_DNC_DNE_TEMP table from DNS DB 
#--------------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_dnc_dne_tbl.sql ${data_tablespace} ${DNS_DB_LINK} 
   check_status
fi
#--------------------------------------------------------------------
step_number=3
#  Description: Drop and Create index for TN on the 
#               DNS_DNC_DNE_TEMP table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then   
   run_sql dns_crt_dnc_dne_indx.sql ${index_tablespace} 
   check_status
fi
#-----------------------------------------------------------------
step_number=4
#  Description: Analyze The dns_dnc_dne_temp Table
#               DNS_DNC_DNE_TEMP table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  dns_dnc_dne_temp  50 
   check_status
fi
#-----------------------------------------------------------------
step_number=5
#  Description: Drop dns_cdw_dnc_dne_temp table that was created  
#               from the CPLST10v table on CDW 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_drp_cdw_dncdne_tbl.sql 
   check_status
fi 
#-----------------------------------------------------------------
step_number=6
#  Description: Create dns_cdw_dnc_dne_temp table from the 
#               CPLST10V table on CDW from the TN on the
#               DNS_DNC_DNE_TEMP  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_cdw_dncdne_tbl.sql ${data_tablespace} ${CDW_DB_LINK}  
   check_status
fi
#-----------------------------------------------------------------
step_number=7
#  Description: Create index on table dns_cdw_dnc_dne_temp  
#               ON the acct_id and acct_seq_no
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_cdw_dncdne_indx.sql ${index_tablespace} 
   check_status
fi
#-----------------------------------------------------------------
step_number=8
#  Description: Analyze the dns_cdw_dnc_dne_temp Table 
#
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  dns_cdw_dnc_dne_temp  50
   check_status
fi
#-----------------------------------------------------------------
step_number=9
#  Description: Drop the OCLS and OFEM Accounts table
#               OCLS_OFEM_ACCTS table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    run_sql  dns_drp_oclsofem_accts_tbl.sql
   check_status
fi
#-----------------------------------------------------------------
step_number=10
#  Description: Create the OCLS and OFEM Accounts table with
#               Acct_id and acct_seq_no only. This table will be 
#               created by a union and then joined to CDW's CSBAN10V. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_oclsofem_accts.sql ${data_tablespace} 
   check_status
fi
#-----------------------------------------------------------------
step_number=11
#  Description: Create index on table OCLS_OFEM_ACCTS table
#               ON acct_id and acct_seq_no
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_oclsofem_accts_indx.sql ${index_tablespace}
   check_status
fi
#-----------------------------------------------------------------
step_number=12
#  Description: Drop and Create index for TN on the
#                DNS_DNC_DNE_TEMP table
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   analyze_table mkdm  ocls_ofem_accts  50
   check_status
fi
#-----------------------------------------------------------------
step_number=13
#  Description: Spool report  to stagedir from the 
#               dns_cdw_dnc_dne_temp and the csban10v table on
#               cdw using the acct_id and acct_seq_no
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_crt_ocls_rpt.sql ${STAGEDIR}/${FILENAME} $CDW_DB_LINK
   check_status
fi
#-----------------------------------------------------------------
step_number=14
#Description:i FTP the ${FILENAME}"  to DNS ftp site   
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   cd ${STAGEDIR}
   echo "*** Step Number $step_number"
   ftp_exec "put ${FILENAME}"
   chk_ftp_errors
     check_status
fi
#-----------------------------------------------------------------
step_number=15
#  Description: Drop all DNS Temp Tables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   run_sql dns_drp_dnc_dne_all_tbl.sql
   check_status
fi
#-----------------------------------------------------------------
step_number=16
#Description:  Cleanup file from ftp directory and mv to archive
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   mv ${STAGEDIR}/${FILENAME} ${ARCHIVEDIR}/
   zip ${ARCHIVEDIR}/${FILENAME}.Z ${ARCHIVEDIR}/${FILENAME}
   check_status
fi
#-----------------------------------------------------------------
step_number=17
# Description: Delete files over 45 days old from the archive dir
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   find ${ARCHIVEDIR}/DNC*.dns.* -mtime +46 -exec rm -f {}  \; 
   check_status
fi                      
#-----------------------------------------------------------------
step_number=18
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="DNSOCLSEXT DNS OCLS-OFEM btn extract Has Successfully ran at `date`."
subject_msg="DNSOCLSEXT DNS OCLS-OFEM btn extract Has Ran Successfully"
send_mail "$success_msg" "$subject_msg" "$MAIL_LIST"
check_status
exit 0
