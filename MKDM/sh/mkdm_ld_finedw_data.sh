#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_ld_finedw_data.sh
#** 
#** Job Name        : MDMLDFIN 
#** 
#** Original Author : Keith Kane  
#**
#** Description     : Process incoming file from FINEDW
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 01/09/2004 kkane    Initial Checkin 
#** 04/20/2004 gsankar  Added the report part. 
#** 05/25/2005 smathew  Added validation in step 1 for confirming the presence
#**                     of the load file and exiting out successfully if absent 
#**                     besides sending email notification reporting the absence.
#** 02/12/2009 jananma  Modified the code to fail if files are not present
#*****************************************************************************

#test hook
#. ~/.mkdm_env 
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`
filedate=`date +'%Y%m%d'`

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

CTLFILE=/$CTLDIR/mkdm_ld_finedw_data.ctl    
TABLE_NAME=common_view_stg
FINEDW_ZIP_FILE=finedw_r3_bdm.dat.Z
FINEDW_UNZIP_FILE=finedw_r3_bdm.dat

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
# Notice this is different than usual.  This is being done to
# force the restart step to 1 if the job fails within the first 4 steps. 
     if [ $step_number -le 4 ] ; then
        exit 1
     else
        exit $step_number
     fi
  fi
}

##############################################################################


#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT MKDM_ERR_LIST FINEDW_IN_DIR \
     FINEDW_ZIP_FILE FINEDW_ARCHIVE_DIR FINEDW_PROCESS_DIR \
     FINEDWMAIL_LIST

   
#-----------------------------------------------------------------
step_number=1
#Description: Look for the incoming file from finedw.  If present,
# move the file to the processing directory.  If not, send out
# an error message.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
echo "*** Step Number $step_number"
  mkdir -p $FINEDW_PROCESS_DIR
  mkdir -p $FINEDW_ARCHIVE_DIR
  if [ ! -s $FINEDW_IN_DIR/$FINEDW_ZIP_FILE ];
  then
    echo " ERROR.  File from FINEDW not present.  Contact FINEDW"
    error_msg="File - $FINEDW_ZIP_FILE from FINEDW not present.  Contact FINEDW."
    subject_msg="FINEDW Files Not Present Load Unsuccessful"
    send_mail "$error_msg" "$subject_msg" "$FINEDWMAIL_LIST"
    return 1 
  else
    rm -f $FINEDW_PROCESS_DIR/*
    cp $FINEDW_IN_DIR/$FINEDW_ZIP_FILE $FINEDW_PROCESS_DIR/$FINEDW_ZIP_FILE
  fi
  check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Execute common function trucate_table to truncate
#     the COMMON_VIEW_STG table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   truncate_table $TABLE_NAME
   check_status
fi
                                 
#-----------------------------------------------------------------
step_number=3
#Description:  Loads data into COMMON_VIEW_STG table from ZIP files.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   gunzip  $FINEDW_PROCESS_DIR/$FINEDW_ZIP_FILE
   check_status
fi

#-----------------------------------------------------------------
step_number=4
#Description:  Loads data into COMMON_VIEW_STG table from ZIP files.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   sqlldr $ORA_CONNECT \
          errors=0 \
          control=$CTLFILE \
          log=$LOGDIR/$L_SCRIPTNAME.$$.$FILENAME.log \
          DIRECT=TRUE \
          ROWS=200000 \
          bad=$LOGDIR/$L_SCRIPTNAME.$$.$FILENAME.bad \
          data=$FINEDW_PROCESS_DIR/$FINEDW_UNZIP_FILE

   check_status
fi

#-----------------------------------------------------------------
step_number=5
#Description:  Cleanup file from ftp directory and mv to archive
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   mv $FINEDW_IN_DIR/$FINEDW_ZIP_FILE  \
      $FINEDW_ARCHIVE_DIR/${filedate}_$FINEDW_ZIP_FILE
   rm $FINEDW_PROCESS_DIR/$FINEDW_UNZIP_FILE
   check_status
fi

#-----------------------------------------------------------------
step_number=6
# Description: Delete files over 45 days old from the archive dir
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   find ${FINEDW_ARCHIVE_DIR}/. -mtime +45 -exec rm -f {}    \;
   check_status
fi                       

#-----------------------------------------------------------------
step_number=7
# Description: Generate Report on common_view_stg.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_rpt_finedw_check $OUTDIR/mkdm_rpt_finedw.rpt
fi

#-----------------------------------------------------------------
step_number=8
# Description: Check the report.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   RPT=`cat $OUTDIR/mkdm_rpt_finedw.rpt |wc -l`
   if [ $RPT -eq 4 ] ; then
    success_msg="No Records Loaded In Common View Stg."
    subject_msg="FINEDW Load Failed!!!"
    send_mail "$success_msg" "$subject_msg" "$FINEDWMAIL_LIST"
    exit $step_number
   fi

   if [ $RPT -eq 5 ] ; then
    success_msg="Only One Month Of Data Available. Re-get The File For This FINEDW Load!!

`cat $OUTDIR/mkdm_rpt_finedw.rpt`"
    subject_msg="FINEDW Load Failed!!!"
    send_mail "$success_msg" "$subject_msg" "$FINEDWMAIL_LIST"
    exit $step_number
   fi

   if [ $RPT -gt 7 ] ; then
    success_msg="More Than Three Journal Months Data Present In The Staging View.

`cat $OUTDIR/mkdm_rpt_finedw.rpt`"
    subject_msg="FINEDW Load Failed!!!"
    send_mail "$success_msg" "$subject_msg" "$FINEDWMAIL_LIST"
    exit $step_number
   fi

   if [ $RPT -gt 5 ] && [ $RPT -lt 8 ] ; then
    success_msg="We have 2-3 Journal Months Of Data. See Details Below.
    
`cat $OUTDIR/mkdm_rpt_finedw.rpt`"
    subject_msg="FINEDW Load Successful."
    send_mail "$success_msg" "$subject_msg" "$FINEDWMAIL_LIST"
   fi

fi

exit 0

