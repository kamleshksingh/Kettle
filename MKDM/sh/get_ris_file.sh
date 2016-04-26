#!/bin/ksh
#*******************************************************************************
#** Program         : get_file_ris.dat 
#** 
#** Job Name        : GETRISFILE  
#** 
#** Original Author : John Kadingo 
#**
#** Description     :   
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#**                     Initial Checkin 
#*****************************************************************************

#test hook
#.~/.mkdm_env 
#. $FPATH/common_funcs.sh
today=`date  +%Y%m%d` 

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
# Not required for shell only
check_variables MKDM_SUPPORT_LIST 

#-----------------------------------------------------------------
step_number=1
#Description:  Move old ris.dat file to the archive directory 
#-----------------------------------------------------------------

if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
  if [ ! -d $STAGEDIR/ris ]; then
     mkdir $STAGEDIR/ris
     check_status
  fi
  if [ ! -d $STAGEDIR/ris/archive ]; then
     mkdir $STAGEDIR/ris/archive
     check_status
  fi
 
  mv $STAGEDIR/ris/ris.dat $STAGEDIR/ris/archive/ris.$today.dat
  cd $STAGEDIR/ris/archive

  for file in `find . -mtime +10`
  do
  rm -f $file
  done

  check_status
fi
#-----------------------------------------------------------------
step_number=2
#Description: Append all files in the ftp directory to ris.dat
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   cd  $FTP_DIR_RIS
   for file in `ls $FTP_DIR_RIS` 
      do 
         cat $file >> $STAGEDIR/ris/ris.dat
      done
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#Description: Clean the FTP site
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   cd  $FTP_DIR_RIS
   for file in `ls`
     do
        rm -f $file
     done
   check_status
fi
#-----------------------------------------------------------------
step_number=4
# Description: send_mail common function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="Job $L_SCRIPTNAME ran successful"
subject_msg="Job $L_SCRIPTNAME ran successful"
send_mail "$success_msg" "$subject_msg" "$MKDM_SUPPORT_LIST"

exit 0
