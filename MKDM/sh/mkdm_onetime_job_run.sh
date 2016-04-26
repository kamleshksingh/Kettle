#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_onetime_job_run.sh
#** 
#** Original Author :  
#**
#** Description     :  Executes all the one time scripts - SQL,PLS and SH
#**                    located in ~src/onetime
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 01/17/2005          Initial Checkin 
#*****************************************************************************
. ~/.mkdm_env
. $FPATH/common_funcs.sh

L_SCRIPTNAME=`basename $0`
#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

#********************************************************************
#Function chk_onetime_flg_file 
#********************************************************************
# Checks if the flag file has some entries
# If YES  - The job failed previously executing one of the onetime scripts.
#    NO   - A New Flag file is created with the list of scripts to be run.
#********************************************************************
function chk_onetime_flg_file
{
   touch $OUTDIR/one_time_scripts.txt
   files_in_flg_file=`cat $OUTDIR/one_time_scripts.txt|sed s/' '//g`
   if [ -z "$files_in_flg_file" ];then
      print "No scripts found in $OUTDIR/one_time_scripts.txt"
      crt_onetime_flg_file
   fi

}

#********************************************************************
#Function crt_onetime_flg_file
#********************************************************************
# Creates a flag file with the following:
# 1.All the .sh files in ~src/onetime
# 2.All the .sql files in ~src/onetime which donot have a driver script 
# 3.All the .pls files in ~src/onetime which donot have a driver script 
#********************************************************************
function crt_onetime_flg_file
{
   # Write the list of shell scripts to the flag file
   shell_file_list=`ls -1 *.sh`
   cur_file=`basename $0`
   shell_file_list=`print $shell_file_list|sed s/$cur_file//g`
   for shell_file in ${shell_file_list}
   do
      print $shell_file >> $OUTDIR/one_time_scripts.txt
   done

   # Write the list of sql scripts to the flag file
   sql_file_list=`ls -1 *.sql`
   sql_file_list=`print $sql_file_list|sed s/.sql//g`
   for sql_file in ${sql_file_list}
   do
      y_or_n=`grep "${sql_file}" *.sh|sed "s/ //g"|cut -f2 -d ":"|grep "^@${sql_file}"|wc -l|sed "s/ //g"`
      y_or_n_common_funcs=`grep "${sql_file}" *.sh|sed "s/ //g"|cut -f2 -d ":"|grep "^run_sql${sql_file}"|wc -l|sed "s/ //g"`
      if [ $y_or_n -eq 0 -a $y_or_n_common_funcs -eq 0 ];then
         print "${sql_file}.sql" >> $OUTDIR/one_time_scripts.txt
      fi
   done

   # Write the list of pls scripts to the flag file
   pls_file_list=`ls -1 *.pls`
   for pls_file in ${pls_file_list}
   do
      y_or_n=`grep "${pls_file}" *.sh|sed "s/ //g"|cut -f2 -d ":"|grep "^@${pls_file}"|wc -l|sed "s/ //g"`
      if [ $y_or_n -eq 0 ];then
         print "${pls_file}" >> $OUTDIR/one_time_scripts.txt
      fi
   done
}

#********************************************************************
#Function rem_from_onetime_flg_file
#********************************************************************
# On success of a script,
# the corresponding entry is removed from flag file
#********************************************************************
function rem_from_onetime_flg_file
{
   orig_onetime_file_lst=`cat $OUTDIR/one_time_scripts.txt`
   cur_onetime_file_lst=`print $orig_onetime_file_lst|sed s/$1//g`
   print $cur_onetime_file_lst > $OUTDIR/one_time_scripts.txt
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
#start_step=${start_step:=0}
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
     err_msg="$1"
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

if [ -d $BASEDIR/onetime ]
then
    cd $BASEDIR/onetime
else
    print "onetime directory doesnot exist"
    exit 0
fi


#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT MKDM_ERR_LIST

#-----------------------------------------------------------------
step_number=1
#Description: Call the function to check if the flag file exists in OUTDIR
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
chk_onetime_flg_file
check_status "Failed creating or checking flag file"
fi
#-----------------------------------------------------------------
step_number=2
#Description: Executing the shell scripts in ~src/onetime
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
shell_file_list=`cat $OUTDIR/one_time_scripts.txt|grep ".sh"`
for shell_file in ${shell_file_list}
do
print "**************************************************"
print "Executing $shell_file started at `date '+%m/%d/%y::%H:%M:%S'`."
print "**************************************************"
$shell_file >>$LOGDIR/$L_SCRIPTNAME.$$
check_status "Failed Executing $shell_file"
rem_from_onetime_flg_file $shell_file
print "************************************************************"
print "Executing $shell_file completed Successfully at `date '+%m/%d/%y::%H:%M:%S'`."
print "************************************************************"
done
fi

#-----------------------------------------------------------------
step_number=3
#Description: Executing the sql scripts in ~src/onetime
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
echo "*** Step Number $step_number"
sql_file_list=`cat $OUTDIR/one_time_scripts.txt|grep ".sql"`
for sql_file in ${sql_file_list}
do
print "*********************************************"
print "Executing ${sql_file} started at `date '+%m/%d/%y::%H:%M:%S'`."
print "**********************************************"
sqlplus -s $ORA_CONNECT <<EOF >>$LOGDIR/$L_SCRIPTNAME.$$
WHENEVER SQLERROR EXIT FAILURE;
WHENEVER OSERROR EXIT FAILURE;
@$sql_file
EOF
check_status "Failed Executing $sql_file"
rem_from_onetime_flg_file $sql_file
print "*************************************************************"
print "Executing $sql_file completed Successfully at `date '+%m/%d/%y::%H:%M:%S'`."
print "*************************************************************"
done
fi

#-----------------------------------------------------------------
step_number=4
#Description: Executing the pls scripts in ~src/onetime
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
echo "*** Step Number $step_number"
pls_file_list=`cat $OUTDIR/one_time_scripts.txt|grep ".pls"`
for pls_file in ${pls_file_list}
do
print "*********************************************"
print "Executing ${pls_file} started at `date '+%m/%d/%y::%H:%M:%S'`."
print "**********************************************"
sqlplus -s $ORA_CONNECT <<EOF >>$LOGDIR/$L_SCRIPTNAME.$$
@$pls_file
EOF
check_status "Failed Executing $pls_file"
rem_from_onetime_flg_file $pls_file
print "*************************************************************"
print "Executing $pls_file completed Successfully at `date '+%m/%d/%y::%H:%M:%S'`."
print "*************************************************************"
done
fi

# After successful Execution remove the flag file.

rm $OUTDIR/one_time_scripts.txt
#-----------------------------------------------------------------
step_number=5
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="One time scripts Completed Successfully."
subject_msg="One time scripts Completed Successfully."
send_mail "$success_msg" "$subject_msg" "$MKDM_ERR_LIST"
check_status "Failed duing sending success mail"

exit 0
