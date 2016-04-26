#!/bin/ksh
#*******************************************************************************
#** Program         :  crt_pans_data.sh
#** 
#** Job Name        :  PANSDATA
#** 
#** Original Author :  Ginny Walker
#**
#** Description     :   Retrieves the PANS data daily
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 10/11/2004 vewalke  Initial Checkin 
#*****************************************************************************

#test hook
# . $HOME/pcms/crdm_dev/common/.setup_env 
# . $FPATH/common_funcs.sh

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
start_step=${start_step:=0}

#-----------------------------------------------------------------
#Check for debug mode [-d]
#-----------------------------------------------------------------
if [ $debug -eq 1 ]; then
   set -x
fi

#-----------------------------------------------------------------
# Set $ parameters here. 
#-----------------------------------------------------------------
   V_EXTRACT_DATE=`sqlplus -s $ORA_CONNECT <<EOT       
                                                        
        whenever oserror exit failure                   
        whenever sqlerror exit failure                  
        set echo on;                                    
        set pagesize 0;
        select trunc(max(last_run_date -1)) 
          from mkdm_job_control             
         where job_name= 'PANSDATA';        
EOT`                                        
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
check_variables start_step ORA_CONNECT MKDM_ERR_LIST 

#-----------------------------------------------------------------
step_number=1
#Description: Creates the ln_from_pans table. There are two scripts
#             one runs on Mondays and the other runs Tues - Fri.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"

     run_sql crt_ln_from_pans staging $V_EXTRACT_DATE
   check_status
fi
#-----------------------------------------------------------------
step_number=2                                                     
#Description: Creates an index on ln_from_pans table                   
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then                        
   echo "*** Step Number $step_number"                            

run_sql crt_index_ln_from_pans.sql     staging
analyze_table mkdm ln_from_pans 5
   check_status                                                   
fi                                                                
#-----------------------------------------------------------------
step_number=3                                                     
#Description: Creates the so_from_pans table. There are two scripts 
#             one runs on Mondays and the other runs Tues - Fri.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then                        
   echo "*** Step Number $step_number"                            

     run_sql crt_so_from_pans       staging $V_EXTRACT_DATE
   check_status                                                   
fi                                                                
#-----------------------------------------------------------------
step_number=4                                                     
#Description: Creates an index on the so_from_pans table                   
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then                        
   echo "*** Step Number $step_number"                            
run_sql crt_index_so_from_pans.sql     staging
analyze_table mkdm so_from_pans 5 
   check_status                                                   
fi                                                                
#----------------------------------------------------------------- 
step_number=5                                                      
#Description: Creates the pans_data table                       
#----------------------------------------------------------------- 
if [ $start_step -le $step_number ] ; then                         
   echo "*** Step Number $step_number"                             
run_sql crt_pans_data.sql           delivery
   check_status                                                    
fi                                                                 
#----------------------------------------------------------------- 
step_number=6                                                      
#Description: Creates the dsl_pans_cons view
#----------------------------------------------------------------- 
if [ $start_step -le $step_number ] ; then                         
   echo "*** Step Number $step_number"                             
run_sql crt_dsl_pans_cons_view.sql                                    
   check_status                                                    
fi                                                                 
#----------------------------------------------------------------- 
step_number=7                                                      
#Description: Creates the bdm_wonback_slscd view                       
#----------------------------------------------------------------- 
if [ $start_step -le $step_number ] ; then   
   echo "*** Step Number $step_number"       
run_sql crt_bdm_wonback_slscd_view.sql           
   check_status                              
fi                                           
#---------------------------------------------------------
step_number=8                                           
#Description: Runs the function to update mkdm_job_control
#---------------------------------------------------------
if [ $start_step -le $step_number ] ; then 
   echo "*** Step Number $step_number"    
   upd_mkdm_job_control PANSDATA
   check_status
fi               
#-----------------------------------------------------------------
#step_number=9
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
#success_msg="The MKDM pans_data table is now updated. "
#subject_msg="MKDM pans_data Table Update"
#send_mail "$success_msg" "$subject_msg" "$MKDM_PANS_MAIL_LIST"
#check_status

exit 0

