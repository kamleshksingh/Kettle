#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_upd_mismail_addr_tbl.sh 
#**
#** Job Name        :  UPDMISMAIL 
#**
#** Original Author :  mmuruga 
#**
#** Description     :  To update Parse and Match Flag in mismailed_address table. 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 02/22/2007 mmuruga  Initial Checkin
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
check_variables MKDM_MIS_MAIl_WKLY_LIST
#-----------------------------------------------------------------
step_number=1
#Description: Create mismailed_address temp table .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_crt_mismail_adrs_tbl.sql $data_tablespace
   check_status
fi

#-----------------------------------------------------------------
step_number=2
#Description: Update Parse and Match Flag in mismailed_address table .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table  MKDM MISMAILED_ADRS_TMP 5
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Update Parse and Match Flag in mismailed_address table .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_adr_parse_indr_mismail.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description: Update Parse and Match Flag in mismailed_address table .
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_upd_mismail_addr_tbl.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description: Analyze MISMAILED_ADDRESS table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   analyze_table MKDM MISMAILED_ADDRESS 5
   check_status
fi

#-----------------------------------------------------------------
step_number=6
#Description:  Spool the count of unmatched/unparsed records.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_get_cnt_unmat_rec.sql $OUTDIR/mismail_cnt.txt $OUTDIR/mismail_cnt1.txt $OUTDIR/mismail_cnt2.txt
   check_status
fi

#-----------------------------------------------------------------
step_number=7
#Description: Drop temp table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   run_sql mkdm_drp_mismail_addr_tmp_tbl.sql
   check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: send_mail common function is called for successfull
# completion and email notification.
#-----------------------------------------------------------------
success_msg="Total count of records in MISMAIlED_ADDRESS     : `cat $OUTDIR/mismail_cnt2.txt` \n
   Count of Unmatched records in MISMAIlED_ADDRESS : `cat $OUTDIR/mismail_cnt.txt` \n
   Count of Unparsed records in MISMAIlED_ADDRESS  : `cat $OUTDIR/mismail_cnt1.txt`"
subject_msg="mismailed_address updated successfully"
send_mail "$success_msg" "$subject_msg" "$MKDM_MIS_MAIl_WKLY_LIST"
check_status

rm -f $OUTDIR/mismail_cnt2.txt $OUTDIR/mismail_cnt.txt $OUTDIR/mismail_cnt1.txt
check_status

exit 0
