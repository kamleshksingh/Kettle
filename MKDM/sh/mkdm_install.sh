#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_install.sh
#**
#** Job Name        :
#**
#** Original Author :  
#**
#** Description     :   The purpose of this shell script is to
#**
#**
#**
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 10/24/2003 cuid     Change Description
#** 02/21/2005 PANBALA  Modified archive file moving part and onetime 
#**                     handling part
#*******************************************************************************

. ~/.mkdm_env

L_SCRIPTNAME=`basename $0`

#-----------------------------------------------------------------
#Declare functions
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#Process command line arguments
#Command line arguemnts may be adjusted according to the needs of 
#this script. d for Debug is always the default
#install_release: Release number (example 1.2.0)
#install_mode: 'C' for Complete install, 'P' for parital install
#
#-----------------------------------------------------------------
start_step=0
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
     send_mail "$err_msg" "$subject_msg" 
     exit $step_number
  fi
}

function remove_old_files
{
   print "Removing old files"
  
   dir_list="sh sql pls onetime common_funcs"

   for dir_name in $dir_list 
   do
      if [ -d $HOME/src/$dir_name ]; then
         tar_file_name=${dir_name}_archive_${install_release}
         cd $HOME/src/$dir_name
         print "Archivng $dir_name directory"
         tar -cvf $tar_file_name *
         print "Compressing $tar_file_name"
         compress $tar_file_name
         if [ -d $INSARCHIVEDIR ]; then
            print "Moving ${tar_file_name}.Z into $INSARCHIVEDIR "
            mv $tar_file_name.Z $INSARCHIVEDIR/$tar_file_name.Z
            rm -f *
            print "Archived $dir_name successfully"
         else
            print "Archive directory does not exists"
         fi
      fi
   done   
}

function archive_patch_files
{
   print "Archiving Patch Files"

         cd /tmp/$V_UID/patch
         tar_file_name=patch_archive_${install_release}
         tar -cvf $tar_file_name *
         print "Compressing $tar_file_name"
         compress $tar_file_name
         if [ -d $INSARCHIVEDIR ]; then
            print "Moving ${tar_file_name}.Z into $INSARCHIVEDIR "
            mv $tar_file_name.Z $INSARCHIVEDIR/$tar_file_name.Z
            rm -f *
            print "Archived $dir_name successfully"
         else
            print "Archive directory does not exists"
         fi
}

function get_tar_file
{
   print "Getting release tar file from FTP Area"

   if [ ! -d /tmp/$V_UID ]; then
      mkdir /tmp/$V_UID
      check_status
   fi

   if [ -f /tmp/$V_UID/${V_TAR_FILE_NAME}.Z ]; then
      rm -f /tmp/$V_UID/${V_TAR_FILE_NAME}.Z
   fi

   cd /tmp/$V_UID
   ftp -inv $REL_FILE_NODE << _EOT_ >$HOME/src/log/FTP_${install_release}.log
      user $REL_FILE_USER $REL_FILE_PASS
      cd pub/mkdm
      get ${V_TAR_FILE_NAME}.Z
_EOT_

   FTP_ERROR=`egrep -i "No such file or directory" $HOME/src/log/FTP_${install_release}.log | wc -l`

   if [ $FTP_ERROR -gt 0 ]; then
      print "Error while FPTing ${V_TAR_FILE_NAME}.Z"
      exit 1
   fi
   print "FTPd the file ${V_TAR_FILE_NAME}.Z successfully"
}

function uncompress_tar {
   print "Copying the TAR file from TMP to $HOME/src"
   cp /tmp/$V_UID/$V_TAR_FILE_NAME.Z $HOME/src
   check_status
   cd $HOME/src
   print "Uncompressing the TAR file"
   uncompress ${V_TAR_FILE_NAME}.Z
   check_status
}


function install_release_tar
{
   cd $HOME/src
   print "Installing the files"
   tar -xvf $V_TAR_FILE_NAME
   check_status
   print "Release ${install_release} Successfully installed"
}
 
function remove_tmp
{
   print "Removing TAR file from TMP"
   rm -f /tmp/$V_UID/${V_TAR_FILE_NAME}.Z
   print "Removed TAR file from TMP"
   print "Removinh release file from $HOME"
   rm -f $HOME/src/$V_TAR_FILE_NAME
}


function validate_mode
{
   if [ ${install_mode} = 'C' ]; then
      print "Complete install Mode"
   elif [ ${install_mode} = 'P' ]; then
      print "Partial install Mode"
   else
      print "Incorrect mode! Mode should be 'C' for Complete 'P' for Partial"
      err_msg="Release ${install_release} failed due to Incorrect Mode"
      subject_msg="Release ${install_release} failed"
      send_mail "$success_msg" "$subject_msg"     
      exit 1
   fi
}

function make_shell_executable
{
   print "Making the shells as Executables"
   cd $HOME
   find . -name '*.sh' | xargs chmod +x
   check_status
}

function compile_pls
{
   print "Compiling PLS files"
   PLS_LOG=$HOME/src/log/PLS_LOG_${install_release}.log
   PLS_ERR=$HOME/src/log/PLS_SPL_${install_release}.log
   cd $HOME/src/pls
   for PLS_FILE in `ls $HOME/src/pls/*sql`
   do
      sqlplus -s $ORA_CONNECT<< _EOF_ >> $PLS_LOG
         WHENEVER SQLERROR EXIT FAILURE
         WHENEVER OSERROR EXIT FAILURE
         SPOOL $PLS_ERR
         @$PLS_FILE 
         EXIT;
_EOF_
   typeset PLS_ERRORS=`egrep -i 'pls-|with compilation errors|Errors for' $PLS_ERR | wc -l`

   if [ $PLS_ERRORS -ne 0 ]; then
      print "Error while compiling $PLS_FILE"
      send_mail "Error while compiling $PLS_FILE" "Release ${install_release} failed"
   fi    
   done
}

function send_mail
{
print "$1" | mailx -s "$2" $MKDM_INSTALL_LIST
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
      send_mail "$check_vars_out" "$subject_msg" $CMPMGT_INSTALL_LIST
      exit 1
   fi
}


function remove_patch_files {
  if [ ! -d /tmp/$V_UID/patch ]; then
      mkdir /tmp/$V_UID/patch
      check_status
   fi

   cd $HOME/src
   patch_list=`tar -tf $V_TAR_FILE_NAME`
   for file_name in $patch_list
   do
      if [ -f $file_name ]; then
         mv $file_name /tmp/$V_UID/patch 
      fi
   done
   check_status
   archive_patch_files
}
#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"

check_null_vars install_release install_mode start_step ARCHIVEDIR REL_FILE_NODE REL_FILE_USER REL_FILE_PASS INSARCHIVEDIR
export V_UID=`who am i | awk '{print $1}'`
export V_TAR_FILE_NAME=mkdm_${install_release}.tar

#-----------------------------------------------------------------
step_number=1
# Description: To execute validate_mode to validate the install
#              mode for the release, mode should be 'C' for 
#              Complete install 'P' for Partial install
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   validate_mode
   check_status
fi

#-----------------------------------------------------------------
step_number=2
# Description: To execute get_tar_file name to get the tar file 
#              from FTP site
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   get_tar_file
   check_status
fi

#-----------------------------------------------------------------
step_number=3
# Description: Uncompress the TAR file
#             
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   uncompress_tar
   check_status
fi

#-----------------------------------------------------------------
step_number=4
# Description: If the install is complete Archive and remove the 
#              old files
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   if [ $install_mode = 'C' ]; then
      remove_old_files
   elif [ $install_mode = 'P' ]; then
      remove_patch_files
   fi
   check_status
fi

#-----------------------------------------------------------------
step_number=5
# Description: To execute the function to install the release file
#              into the destination directories
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   install_release_tar
fi

#-----------------------------------------------------------------
step_number=6
# Description: To execute make_shell_executable to make all the 
#              shell scripts as executables
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   make_shell_executable
fi

#-----------------------------------------------------------------
step_number=7
# Description: To execute compile_pls to compile the PLS programs
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   compile_pls
fi

#-----------------------------------------------------------------
step_number=8
# Description: To execute remove_tmp to remove the release file
#              from temp directory
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   remove_tmp
   check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: 
#             
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   if [ -f .mkdm_env ]; then
      mv $HOME/.mkdm_env $HOME/.mkdm_env_bkp
   fi
   check_status
   mv $HOME/src/common/.mkdm_env $HOME/.mkdm_env
   check_status
   mv $HOME/src/sh/mkdm_install.sh $HOME/src/mkdm_install.sh
   check_status
fi

#-----------------------------------------------------------------
# Description: send_mail function is called for successfull 
# completion and email notification. 
#-----------------------------------------------------------------
success_msg="Install for release ${install_release} completed successfully"
subject_msg="Release ${install_release} completed successfully"
send_mail "$success_msg" "$subject_msg" 
check_status

exit 0

