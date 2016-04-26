#!/bin/ksh
#*******************************************************************************
#** Program         :  common_compress_partitions.sh
#**
#** Job Name        :  COMPPART
#**
#** Original Author :  dxpanne
#**
#** Description     :  This job compress partitions in data marts
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 07/29/2008 dxpanne  Initial checkin.
#*****************************************************************************

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
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
     send_mail "$err_msg" "$subject_msg" "$COMMON_PART_MAIL"
     exit $step_number
  fi
}

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
#Begin Main Program
#-----------------------------------------------------------------
print "$L_SCRIPTNAME started at `date` \n"

CONNECT_MKDM=$ORA_CONNECT

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT data_tablespace index_tablespace
check_variables COMMON_PART_MAIL 

#-----------------------------------------------------------------
step_number=1
# Description: To update the status in dmart_parts_module_code_ref
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql upd_dmart_parts_module_code_ref_all.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: To truncate table dmart_partn_status_ref 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql compress_trunc_result_details.sql
    check_status
fi

rm -f ${DATADIR}/compress_partition_mod_list.txt

MODDATFILE=${DATADIR}/compress_partition_mod_list.txt
sqlplus -s $ORA_CONNECT <<EOT
   SET PAUSE OFF
   SET HEAD OFF
   SET SHOW OFF
   SET FEED OFF
   SET ECHO OFF
   SET LINESIZE 30
   spool $MODDATFILE
   WHENEVER SQLERROR EXIT FAILURE
   WHENEVER OSERROR EXIT FAILURE
   SELECT DISTINCT module_cd FROM dmart_partn_module_stat_ref
   WHERE compress_status_cd IN ('N','I','E') ORDER BY module_cd;
   spool off;
   QUIT;
EOT
check_status

for mod_cd in `cat $MODDATFILE`
do
echo "                                                                   "
echo "****************PROCESSING FOR MODULE $mod_cd ****************"
echo "                                                                   "
        run_sql update_dmart_parts_module_code_ref.sql $mod_cd  I

ORA=`sqlplus -s $CONNECT_MKDM <<END
            SET HEAD OFF
            SET PAGESIZE 0
            SET FEEDBACK OFF
            SET TRIMOUT ON
            WHENEVER OSERROR EXIT FAILURE
            WHENEVER SQLERROR EXIT FAILURE
	    SELECT oracle_connection_val
	    FROM dmart_partn_module_stat_ref
	    WHERE UPPER(MODULE_CD)=upper('$mod_cd');
            EXIT;
          END`

        check_status
        check_variables $ORA
        ora1=\$$ORA
        ORA_CONNECT=`eval echo $ora1`
        
        check_status
        echo "Connect variable :::::::: $ORA_CONNECT"

	#-----------------------------------------------------------------
	step_number=3
	# Description: Compress the partitions
	#-----------------------------------------------------------------
	if [ $start_step -le $step_number ] ; then
	    echo "*** Step Number $step_number"
	    run_sql compress_partition.sql $mod_cd
	    check_status
	fi

	#-----------------------------------------------------------------
	step_number=4
	#Description: Re-Build Invalid Indexes (Local and Global)
	#-----------------------------------------------------------------
	if [ $start_step -le $step_number ] ; then
	   echo "*** Step Number $step_number"
	   run_sql compress_rebuild_unusable_indexes.sql $mod_cd
	   check_status
	fi

        #-----------------------------------------------------------------
        step_number=5
        #Description: Update the status for the current module
        #-----------------------------------------------------------------
        if [ $start_step -le $step_number ] ; then
           echo "*** Step Number $step_number"
           CHKSTATUS=$DATADIR/compress_check_status.txt
           run_sql check_compress_partition.sql $mod_cd $CHKSTATUS
           check_status
           export check_value=`cat $CHKSTATUS`
           if [ $check_value -gt 0 ] ; then
               run_sql update_dmart_parts_module_code_ref.sql $mod_cd  E
               check_status
           else
               run_sql update_dmart_parts_module_code_ref.sql $mod_cd  C
               check_status
           fi 
        fi

	start_step=3
	step_number=3
done

ORA_CONNECT=$CONNECT_MKDM

#-----------------------------------------------------------------
step_number=6
# Description: To generate the report
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    rm -f $DATADIR/compress_partition_report.txt
    RPTFILE=${DATADIR}/compress_partition_report.txt
    run_sql compress_generate_rpt.sql $RPTFILE
    check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: send_mail common function is called for sending status
#              of Job Completion
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    success_msg=`cat $RPTFILE`
    subject_msg="Common partition creation process"
    send_mail "$success_msg" "$subject_msg" "$COMMON_PART_MAIL"
    check_status
fi

echo $(date) done
exit 0
