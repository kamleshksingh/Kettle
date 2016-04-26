#!/bin/ksh
#*******************************************************************************
#** Program         :  start_mkdm_job.sh
#**
#** Original Author :  Rajesh Sugunthan
#**
#** Description     :  Control script to run MKDM jobs
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 02/12/2003 srajesh  Initial Checkin 
#*****************************************************************************

#---------------------------------------------------------------
# Include mkdm_env.sh Environment setup script
#---------------------------------------------------------------
. ~/.mkdm_env

#---------------------------------------------------------------
# Include common_funcs Common functions script
#---------------------------------------------------------------
. $FPATH/common_funcs.sh

#---------------------------------------------------------------
# Temporary variables
#---------------------------------------------------------------
TMP=$TMP_DIR/MKDMJOBINFO.$$ #Temp out file. Needed at later stage.
export V_PARM_JOB_NAME=$1 #Job Name parameter
V_MAIL_SUBJECT="JOB FAILED: ${V_PARM_JOB_NAME}"

#---------------------------------------------------------------
# Check for parameter passed.
# No params - Error Exit
#---------------------------------------------------------------
if [ $# -ne 1 ] ; then
    print "Insufficient parameters. Must pass Job Name"
    exit 1
fi

#---------------------------------------------------------------
# Get Job Info in TMP file
#---------------------------------------------------------------
sqlplus -s $ORA_CONNECT << END_OF_SQL
set pause off
set head off
set show off
set feed off
set timing off
set echo off
set linesize 110
spool $TMP
WHENEVER SQLERROR EXIT FAILURE 
WHENEVER OSERROR EXIT FAILURE 

SELECT 
  RPAD('V_JOB_NAME='        ||NVL(a.JOB_NAME,'NULL'),80),
  RPAD('V_SCRIPT_NAME='     ||NVL(a.SCRIPT_NAME,'NULL'),80),
  RPAD('V_PARM_LIST="'       ||NVL(a.PARM_LIST,'NULL') || '"',110),
  RPAD('V_DATA_TABLESPACE=' ||NVL(a.DATA_TABLESPACE,'NULL'),80),
  RPAD('V_INDEX_TABLESPACE='||NVL(a.INDEX_TABLESPACE,'NULL'),80),
  RPAD('V_RUN_ID='          ||NVL(b.RUN_ID,1000),80),
  RPAD('V_STATUS='          ||NVL(b.STATUS,'C'),80),
  RPAD('V_ERROR_STEP='      ||NVL(b.ERROR_STEP,1),80)
FROM 
    MKDM_JOB_CONTROL a, 
    MKDM_JOB_STATUS b
WHERE
   UPPER(b.JOB_NAME(+))          = UPPER(a.JOB_NAME) 
   AND UPPER(a.JOB_NAME)         = UPPER('$V_PARM_JOB_NAME')
   AND NVL(b.START_TIME,SYSDATE) = (SELECT NVL(MAX(START_TIME),SYSDATE) 
			                   FROM MKDM_JOB_STATUS 
			                   WHERE UPPER(JOB_NAME) = UPPER('$V_PARM_JOB_NAME'));
spool off;
QUIT;
END_OF_SQL

#check for SQL errors
if [ $? -gt 0 ] ; then
    print "Unable to fetch job info for ($V_PARM_JOB_NAME) from MKDM_JOB_CONTROL and MKDM_JOB_STATUS tables. (`date`)"
    mail_message="Unable to fetch job info for ($V_PARM_JOB_NAME) from MKDM_JOB_CONTROL and MKDM_JOB_STATUS tables. (`date`)"
    send_mail "$mail_message" "$V_MAIL_SUBJECT" "$MKDM_ERR_LIST"
    exit 1
fi

JOB_FOUND=`grep 'V_JOB_NAME=' $TMP | wc -l`
if [ $JOB_FOUND -lt 1 ]; then
     print "Invalid job name - $V_PARM_JOB_NAME."
     rm $TMP
 exit 1
fi

#---------------------------------------------------------------
# extract the information into shell variables
# Once got in memory, delete the TMP files 
#---------------------------------------------------------------
. $TMP
rm -fr $TMP

#---------------------------------------------------------------
# check if script file exists and has execute permissions
#---------------------------------------------------------------
if [ ! -f $SHDIR/$V_SCRIPT_NAME ]; then
     print "Cannot run the job. File $V_SCRIPT_NAME does not exists."
     exit 1
else
   if [ ! -x $SHDIR/$V_SCRIPT_NAME ]; then
        print "Cannot run the job. File $V_SCRIPT_NAME has no execute permission."
        exit 1
   fi
fi

#---------------------------------------------------------------
# Case on STATUS
# Case         Desc             Action
# R            Running          Exit err no
# C            Complete         increment RUN_ID
# E            Error            Get err no
#---------------------------------------------------------------
case "$V_STATUS" in
    R) print "Job ($V_PARM_JOB_NAME) already running. Cannot re-run the Job. (`date`)"
       mail_message="Attempt to re-run the job. Job ($V_PARM_JOB_NAME) already running. (`date`)"
       send_mail "$mail_message" "$V_MAIL_SUBJECT" "$MKDM_ERR_LIST"
       exit 1;;
    C) ((V_RUN_ID=V_RUN_ID+1))
       STEP=1 ;;
    E) STEP=$V_ERROR_STEP ;;
    *) print "Invalid job status ($V_STATUS) for ($V_PARM_JOB_NAME) in MKDM_JOB_STATUS. (`date`)"
       mail_message="Invalid job status ($V_STATUS) for ($V_PARM_JOB_NAME) in MKDM_JOB_STATUS. (`date`)"
       send_mail "$mail_message" "$V_MAIL_SUBJECT" "$MKDM_ERR_LIST"
       exit 1;;
esac

#---------------------------------------------------------------
# Insert STATUS as 'R' returning START TIME
#---------------------------------------------------------------
V_START_TIME=`date +%Y%m%d%H%M%S`

sqlplus -s $ORA_CONNECT << END_OF_SQL
    WHENEVER SQLERROR EXIT FAILURE 
    WHENEVER OSERROR EXIT FAILURE 
    
    INSERT INTO MKDM_JOB_STATUS 
        ( JOB_NAME, RUN_ID, START_TIME, STATUS )
    VALUES( '$V_PARM_JOB_NAME',$V_RUN_ID, TO_DATE($V_START_TIME,'YYYYMMDD HH24:MI:SS'), 'R' );
QUIT;
END_OF_SQL

#check for SQL errors
if [ $? -ne  0 ] ; then
    print "Error while inserting row in MKDM_JOB_STATUS table with status as Running for ($V_PARM_JOB_NAME). (`date`)"
    mail_message="Error while inserting row in MKDM_JOB_STATUS table with status as Running for ($V_PARM_JOB_NAME). (`date`)"
    send_mail "$mail_message" "$V_MAIL_SUBJECT" "$MKDM_ERR_LIST"
    exit 1
fi

#---------------------------------------------------------------
# Call the script, passing the step number, tablespace, indexspace and param list.
# Divert the output to a log file.
# SCRIPT_NAME -s STEP -t TABLESPACE -i INDEXSPACE parameters
#---------------------------------------------------------------
LOGFILE=$1.${V_START_TIME}.log

$SHDIR/$V_SCRIPT_NAME -s $STEP -t $V_DATA_TABLESPACE -i $V_INDEX_TABLESPACE $V_PARM_LIST > $LOGDIR/$LOGFILE 2>&1

#---------------------------------------------------------------
# Save the return status of the above called script.
#---------------------------------------------------------------
STAT=$?
 
#---------------------------------------------------------------
# Check for return status 
# = 0 --> update STATUS = C, END_TIME
# > 0 --> update STATUS = E, END_TIME, ERROR_STEP = $STAT
#---------------------------------------------------------------
if [ $STAT -eq 0 ] ; then
    V_STAT='C'
fi
if [ $STAT -ne 0 ] ; then
    V_STAT='E'
fi

sqlplus -s $ORA_CONNECT << END_OF_SQL
    WHENEVER SQLERROR EXIT FAILURE 
    WHENEVER OSERROR EXIT FAILURE 
    
    UPDATE MKDM_JOB_STATUS 
        SET STATUS = '$V_STAT', 
            END_TIME = SYSDATE,
            ERROR_STEP = $STAT
    WHERE 
    UPPER(JOB_NAME) = UPPER ('$V_PARM_JOB_NAME') 
    AND RUN_ID = $V_RUN_ID 
    AND START_TIME = TO_DATE($V_START_TIME,'YYYYMMDD HH24:MI:SS');
    QUIT;
END_OF_SQL

#check for SQL errors
if [ $? -ne 0 ] ; then
    print "Error while updating row in MKDM_JOB_STATUS table with status ($V_STAT) for ($V_PARM_JOB_NAME). (`date`)"
    mail_message="Error while updating row in MKDM_JOB_STATUS table with status (V_STAT) and error-step ($STAT) for ($V_PARM_JOB_NAME). (`date`)"
    send_mail "$mail_message" "$V_MAIL_SUBJECT" "$MKDM_ERR_LIST"
    exit 1
fi

#---------------------------------------------------------------
# Exit status
#---------------------------------------------------------------
exit $STAT
