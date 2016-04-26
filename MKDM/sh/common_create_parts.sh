#!/bin/ksh
#*******************************************************************************
#** Program         :   common_create_parts.sh
#**
#** Job Name        :   CRTCOMPART 
#**
#** Original Author :   Keerthana Raman
#**
#** Description     :   This job creates partitions for tables in all modules
#**                    
#**                    
#** Revision History:   Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 12/11/2007 kraman    Initial check-in   
#*****************************************************************************

#test hook
#. ~/.setup_env
#. ~/.mkdm_env
#. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`

date_string=$(date '+%Y%m%d')
start_step=0

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
     send_mail "$err_msg" "$subject_msg" "$COMMON_PART_MAIL"
     exit $step_number
  fi
}

#-----------------------------------------------------------------
# Function to get the connect String
#-----------------------------------------------------------------
function get_connect_info
{
    
    lookup_mod=`echo $1|sed 's/-/_/g'`_CONN
    export ORA_CONNECT=`sqlplus -s $CONNECT_CRDM <<END
    		 SET HEAD OFF
    		 SET PAGESIZE 0
    	         SET FEEDBACK OFF
    	         SET TRIMOUT ON
    		 SELECT lookup_value
    		 FROM crdm_flex_env
    		 WHERE UPPER(lookup_code)=upper('$lookup_mod');
    		 EXIT;
                 END`
    check_status
    
    if [[ $ORA_CONNECT = '' ]]; then
	echo "***********Unable to determine Connect Info***********"
    	exit $step_number 
    fi      
}

function get_part_mod_list
{
        
    return_val=`sqlplus -s $CONNECT_CRDM <<END
    		 SET HEAD OFF
    		 SET PAGESIZE 0
    	         SET FEEDBACK OFF
    	         SET LINE 200
    	         SET TRIMOUT ON
    		 SELECT lookup_value
    		 FROM crdm_flex_env
    		 WHERE UPPER(lookup_code)=upper('$1');
    		 EXIT;
    	        END`
    	        
    if [[ $return_val = '' ]]; then
	echo "***********Unable to determine Partition List***********"
    	exit $step_number 
    fi        	        
    
    export  $2="$return_val"    
  
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
date

MODSTATUS=$HOME/module_status.txt
CHKFILE=$HOME/check_file.txt
TEMP=$HOME/temp_crt_part_rpt.txt
HEADER=$HOME/header_crt_part_rpt.txt
CONNECT_MKDM=$ORA_CONNECT

get_part_mod_list CREATE_PART_MOD_LIST PART_MODULE_LIST
check_status

#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email.
#-----------------------------------------------------------------

check_variables start_step ORA_CONNECT data_tablespace index_tablespace 
check_variables COMMON_PART_MAIL PART_MODULE_LIST

#-----------------------------------------------------------------
step_number=1
# Description: Create temp table for storing modules 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    run_sql create_module_temp_det.sql
    check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: Insert module names 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
 # $PART_MODULE_LIST is defined in .mkdm_env
    for mod_val in $PART_MODULE_LIST
    do	
    run_sql insert_modules.sql $mod_val
    check_status
    done
#Write in header file
      echo '                                                                             ' >$HEADER
      echo '*---------------------------------------------------------------------------*'>>$HEADER
      echo '*                      CREATE PARTITION PROCESS REPORT                      *'>>$HEADER
      echo '*---------------------------------------------------------------------------*'>>$HEADER
      echo '*  TABLE_NAME                 | OWNER |LST_PRT_CRT_DT|    STATUS            *'>>$HEADER
      echo '*---------------------------------------------------------------------------*'>>$HEADER
    rm $HOME/*_create_part_rpt.txt
fi

#-----------------------------------------------------------------
step_number=3
# Description: Update status for errored modules 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
     echo "*** Step Number $step_number"
     run_sql  update_module_temp_for_error.sql 
     check_status
     # Write in module status file 
        echo '                                                                             ' >$MODSTATUS
        echo '*----------------------------------------------------------------*'>>$MODSTATUS
        echo '*      MODULE WISE REPORT FOR CREATE PARTITION PROCESS           *'>>$MODSTATUS
        echo '*----------------------------------------------------------------*'>>$MODSTATUS
        echo '*     MODULE NAME    |       STATUS                              *'>>$MODSTATUS
        echo '*----------------------------------------------------------------*'>>$MODSTATUS
     rm $HOME/*_create_main_rpt.txt
fi
   
mod_list=`sqlplus -s $ORA_CONNECT <<END
	    SET HEAD OFF
	    SET PAGESIZE 0
            SET FEEDBACK OFF
            SET TRIMOUT ON
	    SELECT module_nm
	    FROM module_det_temp
	    WHERE status='N' or status='I'
	    order by status,module_nm ;
	    EXIT;
          END`
check_status

for MODULE_CODE in $mod_list
do
echo "                                                                   "
echo "****************PROCESSING FOR MODULE $MODULE_CODE ****************" 
echo "                                                                   "
	ORA_CONNECT=$CONNECT_MKDM
	run_sql update_module_temp_det.sql $MODULE_CODE I
	check_status
	
	get_connect_info $MODULE_CODE 
	check_status
        echo "Connect variable :::::::: $ORA_CONNECT"
	#-----------------------------------------------------------------
	step_number=4
	# Description: Create partitions for tables in corresponding module         
	#-----------------------------------------------------------------
	if [ $start_step -le $step_number ] ; then
	    echo "*** Step Number $step_number"
	    run_sql create_partition.sql $MODULE_CODE
	    check_status
	fi

	#-----------------------------------------------------------------
	step_number=5
	#Description: Re-Build Invalid Indexes (Local and Global)
	#-----------------------------------------------------------------
	if [ $start_step -le $step_number ] ; then
	   echo "*** Step Number $step_number"
	   run_sql rebuild_unusable_indexes.sql $MODULE_CODE
	   check_status
	fi

	#-----------------------------------------------------------------
	step_number=6
	# Description: Generate report             
	#-----------------------------------------------------------------
	if [ $start_step -le $step_number ] ; then
	    echo "*** Step Number $step_number"
             RPTFILE=$HOME/${MODULE_CODE}_create_part_rpt.txt
	    run_sql crt_part_rpt.sql $RPTFILE $MODULE_CODE 
	    check_status
	fi

	#-----------------------------------------------------------------
	step_number=7
	# Description: Update the status for current module_cd
	#-----------------------------------------------------------------			
	if [ $start_step -le $step_number ] ; then
	    echo "*** Step Number $step_number"
	    ORA_CONNECT=$CONNECT_MKDM
             run_sql check_create_partition.sql $CHKFILE $MODULE_CODE
             check_status
             export check_run=`cat $CHKFILE`
             if [ $check_run -gt 0 ] ;  then
                 run_sql update_module_temp_det.sql $MODULE_CODE E
                 check_status
             else
                 run_sql update_module_temp_det.sql $MODULE_CODE C
                 check_status
             fi
         fi
		     
      start_step=4  
      step_number=4
done

#-----------------------------------------------------------------
step_number=8
# Description: send_mail common function is called for sending reports for each module
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    cd $HOME
    for fl_nm in *_create_part_rpt.txt
    do
    MAIN_MOD_NM=`echo $fl_nm | cut -d'-' -f1`
    cat $fl_nm >> $HOME/${MAIN_MOD_NM}_create_main_rpt.txt
    done

    for fl_nm in *_create_main_rpt.txt
    do
    MAIN_MOD_NM=`echo $fl_nm | cut -d'_' -f1`
    cat $HEADER>$HOME/send_file.txt
    cat $fl_nm>>$HOME/send_file.txt
    success_msg=`cat $HOME/send_file.txt`
    subject_msg="Create partition process for $MAIN_MOD_NM "
    send_mail "$success_msg" "$subject_msg" "$COMMON_PART_MAIL"
    check_status
    rm $HOME/send_file.txt
    done
    cd -
fi

#-----------------------------------------------------------------
step_number=9
# Description: Check for any errors in partition creation
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    cd $HOME
    for fl_nm in *_create_main_rpt.txt
    do
    MAIN_MOD_CD=`echo $fl_nm | cut -d'_' -f1`
    run_sql check_create_partition.sql $CHKFILE $MAIN_MOD_CD
    check_status
    export check_run=`cat $CHKFILE`
    if [ $check_run -gt 0 ] ;  then
       echo "*    ${MAIN_MOD_CD}                   Error                          *"  >> $MODSTATUS
       check_status
    else 
        echo "*    ${MAIN_MOD_CD}                 Completed                        *" >> $MODSTATUS
        check_status
        rm $HOME/$fl_nm
        rm $HOME/${MAIN_MOD_CD}*create_part_rpt.txt
    fi
    done
    cd -
fi

#-----------------------------------------------------------------
step_number=10
# Description: send_mail common function is called for sending status  
#              of Job Completion 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    mod_in_error=`grep -i "Error" $MODSTATUS | wc -l | cut -d' ' -f1`
    check_status
    success_msg=`cat $MODSTATUS`
    check_status
    if [[ ${mod_in_error} -gt 0 ]]; then
        subject_msg="Common partition Creation process Failed"	
        send_mail "$success_msg" "$subject_msg" "$COMMON_PART_MAIL" 
        check_status
        exit 3 
    else        
        subject_msg="Common partition creation process completed Successfully."
        send_mail "$success_msg" "$subject_msg" "$COMMON_PART_MAIL"
        check_status
    fi
fi

#-----------------------------------------------------------------
step_number=11
# Description: Drop temp tables and delete files
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
     ORA_CONNECT=$CONNECT_MKDM
     run_sql drop_module_temp_det.sql
     check_status     
     rm $CHKFILE $MODSTATUS $HEADER     
     check_status
fi

echo $(date) done
exit 0
