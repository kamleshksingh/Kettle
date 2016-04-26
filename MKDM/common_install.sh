#!/bin/ksh
#*******************************************************************************
#** Program         :  common_install.sh
#**
#** Original Author :  amahara
#**
#** Description     :  Please refer to Common Installation Guide.doc in 
#**                    dimensions before installation
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 12/11/2005 amahara  Initial Check in
#** 03/18/2014 czeisse  resetting .ssh directory permissions
#*******************************************************************************

. ~/.profile

L_SCRIPTNAME=`basename $0`
V_START_TIME=`date +%Y%m%d%H%M%S`

export LOGNAME=install_$2_${V_START_TIME}.log
exec 1>~/src/log/$LOGNAME

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of
#this script. d for Debug is always the default
#install_release: Release number (example 1.2.0)
#install_mode: 'C' for Complete install, 'P' for parital install
#-----------------------------------------------------------------
while getopts "s:r:m:d" option
do
   case $option in
     s) start_step=$OPTARG;;
     r) install_release=$OPTARG;;
     m) install_mode=$OPTARG;;
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
export V_UID=`who am i | awk '{print $1}'`
export V_TAR_FILE_NAME=${TAR_ENV}_${install_release}.tar

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
     send_mail "$err_msg" "$subject_msg"
     exit $step_number
  fi
}

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

function send_mail
{
   print "$1" | mail -s "$2" $INSTALL_MAIL_LIST
}

function validate_variables
{
   for var in  $*
   do
      eval "if [ -z \"\$$var\" ] ; \
      then \
         echo \"\$var not set\"; \
      fi"
   done
}

function check_null_vars
{
   unset check_vars_out
   check_vars_out=`validate_variables $*`

   if [ -n "$check_vars_out" ]
   then
      echo "The following variables need to be set before running"
      echo "$check_vars_out"
      subject_msg="$L_SCRIPTNAME failed due to unset variables"
      send_mail "$check_vars_out" "$subject_msg" 
      exit 1
   fi
}

function archive_old_files
{
   for dir_name in $DIR_LIST
   do
      if [ -d $HOME/$dir_name ]; then
         export isonetime=N
         core=`echo "$dir_name" |cut -f2 -d "/"`
         tar_file_name=${core}_archive_${install_release}
         export isonetime=`echo $dir_name | awk '/one/ { print "Y" }'`
         export isonetime=${isonetime:=N}
         cd $HOME
         print "Archiving $dir_name directory"
         tar -cvf $tar_file_name $dir_name/*
         print "Compressing $tar_file_name"
         gzip -f $tar_file_name      
         if [ -d $INSARCHIVEDIR ]; then
            print "Moving ${tar_file_name}.gz into $INSARCHIVEDIR "
            mv $tar_file_name.gz $INSARCHIVEDIR/$tar_file_name.gz
            check_status
            if [ $install_mode = 'C' -o $isonetime = 'Y' ]; then
               cd $HOME/$dir_name
               check_status
               rm -f *
            fi
            print "Archived $dir_name successfully"
         else
            print "Archive directory does not exists"
            return 1
         fi
      fi
   done
}

function compile_pls
{
   print "Compiling PLS files"
   PLS_LOG=$LOG_DIR/PLS_LOG_${install_release}.$$.log
   PLS_ERR=$LOG_DIR/PLS_SPL_${install_release}
   cd $1
   # *.* is used because in BDM the pls have .sql extension and in other modules .pls extension is used
   for PLS_FILE in `ls -r $1/*.*`  
   do
      FILE_NM=`basename $PLS_FILE`
      SQL_LINE="@$PLS_FILE $PLS_ERR.$$.$FILE_NM.1 $EDW_LINK"
      sqlplus -s $ORA_CONNECT<< _EOF_ > $PLS_ERR.$$.$FILE_NM.log
         WHENEVER SQLERROR EXIT FAILURE
         WHENEVER OSERROR EXIT FAILURE
         SPOOL $PLS_ERR
         $SQL_LINE
         SPOOL OFF
         EXIT;
_EOF_

      typeset PLS_ERRORS=`egrep -i 'pls-|with compilation errors| unable to CONNECT to ORACLE | Errors for' $PLS_ERR.$$.$FILE_NM.log | wc -l`

      if [ $PLS_ERRORS -ne 0 ]; then
         print "Error while compiling $PLS_FILE"
         send_mail "Error while compiling $PLS_FILE" "Release ${install_release} failed"
         cat $PLS_ERR.$$.$FILE_NM.log >> $PLS_LOG
         rm -f $PLS_ERR.$$.$FILE_NM.log
         rm -f $PLS_ERR.$$.$FILE_NM.1
         return 1
      fi
      cat $PLS_ERR.$$.$FILE_NM.log >> $PLS_LOG
      rm -f $PLS_ERR.$$.$FILE_NM.log
      rm -f $PLS_ERR.$$.$FILE_NM.1
   done
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

check_null_vars install_release start_step install_mode LOG_DIR DIR_LIST
check_null_vars REL_FILE_NODE REL_FILE_USER REL_FILE_PASS REL_FILE_DIR 
check_null_vars INSTALL_MAIL_LIST PLS_DIR TAR_ENV INSARCHIVEDIR
check_null_vars ORA_CONNECT

#-----------------------------------------------------------------
step_number=1
# Description: To validate the install mode for the release,
#              mode should be 'C' for Complete install 'P' for Partial install
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   if [ ${install_mode} = 'C' ]; then
      print "Complete install Mode"
   elif [ ${install_mode} = 'P' ]; then
      print "Partial install Mode"
   else      
      print "Incorrect mode! Mode should be 'C' for Complete 'P' for Partial"
      err_msg="Release ${install_release} failed due to Incorrect Mode"
      subject_msg="Release ${install_release} failed"
      send_mail "$err_msg" "$subject_msg"
      exit 1
   fi
fi

#-----------------------------------------------------------------
step_number=2
# Description: To get the tar file from FTP site
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Getting release tar file from FTP Area"
   cd $HOME
   sftp $REL_FILE_USER@$REL_FILE_NODE << _EOT_ >${LOG_DIR}/FTP_${install_release}.log
      cd $REL_FILE_DIR
      get ${V_TAR_FILE_NAME}.gz
_EOT_

   FTP_ERROR=`egrep -i "No such file or directory" ${LOG_DIR}/FTP_${install_release}.log | wc -l`

   if [ $FTP_ERROR -gt 0 ]; then
      err_msg="Error while FPTing ${V_TAR_FILE_NAME}.gz"
      subject_msg="Release ${install_release} failed"
      send_mail "$err_msg" "$subject_msg"
      exit 1
   fi

   if [ ! -s $HOME/${V_TAR_FILE_NAME}.gz ]; then
     err_msg="The ${V_TAR_FILE_NAME}.gz is not FTPed"
     subject_msg="Job Error - $L_SCRIPTNAME"
     send_mail "$err_msg" "$subject_msg"
     exit 1
  fi
   
   print "FTPd the file ${V_TAR_FILE_NAME}.gz successfully"
fi

#-----------------------------------------------------------------
step_number=3
# Description: Uncompress the TAR file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Copying the TAR file from TMP to $HOME"
   cd $HOME
   print "Uncompressing the TAR file"
   gunzip ${V_TAR_FILE_NAME}.gz
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: Archive and remove the old files
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   archive_old_files
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: Archive env file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   if [ -f $HOME/$ENV_FILE ]; then
      cp $HOME/$ENV_FILE $INSARCHIVEDIR/$ENV_FILE.$install_release.$$
      check_status
   fi
fi

#-----------------------------------------------------------------
step_number=6
# Description: Install the release file into the destination directories
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   cd $HOME
   chmod -R 755 .
   print "Installing the files"
   tar -xvf $V_TAR_FILE_NAME
   check_status
   print "Release ${install_release} Successfully installed"
fi

#-----------------------------------------------------------------
step_number=7
# Description: Install env file
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   if [ -f $BASEDIR/common/$ENV_FILE ]; then
      mv $BASEDIR/common/$ENV_FILE $HOME/$ENV_FILE
      check_status
   fi
fi

#-----------------------------------------------------------------
step_number=8
# Description: Make all the shell scripts as executables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Making the shells as Executables"
   cd $HOME
   find . -name '*.*sh' | xargs chmod +x
fi

#-----------------------------------------------------------------
step_number=9
# Description: To execute compile_pls to compile the PLS programs
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   for dir_nm in $PLS_DIR
   do
      if [ COMPILE_PLS = 'Y' ]; then
      compile_pls $dir_nm
      fi
   done
   check_status
fi

#-----------------------------------------------------------------
step_number=10
# Description: Remove the release file from home directory
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Removing release file from $HOME"
   rm -f $HOME/$V_TAR_FILE_NAME
   rm -f $HOME/$V_TAR_FILE_NAME.gz
fi

#-----------------------------------------------------------------
step_number=11
#  Description: Reset the .ssh directory permission to 700
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Resetting .ssh directory permission"
   cd $HOME
   chmod 700 .ssh
fi

#-----------------------------------------------------------------
# Description: send_mail function is called for successfull
# completion and email notification.
#-----------------------------------------------------------------
success_msg="Install for release ${install_release} completed successfully"
subject_msg="Release ${install_release} completed successfully on $V_UID@`uname -n`"
send_mail "$success_msg" "$subject_msg"
check_status

exit 0
