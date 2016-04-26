#!/bin/ksh
#*******************************************************************************
#** Program         : mkdm_ld_lnp_data.sh 
#** 
#** Job Name        : MKDMLDLNP 
#** 
#** Original Author : Manju 
#**
#** Description     : The driver script to load lnp_data table. 
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User     
#** Date       ID       Description
#** MM/DD/YYYY CUID         
#** ---------- -------- ------------------------------------------------
#** 10/15/2004 mpalamo  Initial Checkin 
#** 02/10/2005 mmuruga  Modified the file name and the extension of the file
#**                     and used gunzip to decompress the file  
#*****************************************************************************
L_SCRIPTNAME=`basename $0`
date_string=$(date '+%m%d')
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
                                                      # Name of compressed file
export ftp_tag_file=${FINEDW_IN_DIR}/lnp/w?2w?-????????.tag
export tag_file=${LNP_STG_INDIR}/
                                                      # Name of tag file
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
start_step=${start_step:=1}
#-----------------------------------------------------------------
# Check the variables to ensure everything is set proper for this
# job stream to run correctly.  If the variables are not set
# the common function will exit and send email. 
#-----------------------------------------------------------------
check_variables start_step ORA_CONNECT_MKDM MKDM_ERR_LIST DATADIR LNPARCHIVEDIR LNP_STG_INDIR

   cd ${FINEDW_IN_DIR}/lnp
   check_status
   ls w?2w?-????????.tag
   check_status 'No TAG File found' "$?"
   export ftp_tag_file=`ls w?2w?-????????.tag | awk 'NR==1 {print $1}'`
   export ftp_data_file=`print $ftp_tag_file | sed 's/tag/txt.gz/g'`
   export ftp_data_file1=`print $ftp_tag_file | awk '{print substr($1,1,14)}'`
   print "New,,..... $ftp_data_file" 
   check_status
#-----------------------------------------------------------------
step_number=1
# Description: Check for existence of data file.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
    echo "*** Step Number $step_number"
    test -r ${ftp_data_file}
    check_status
fi
#-----------------------------------------------------------------
step_number=2
#  Description: Copy data file from ftp area to archive area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   print "Coping file to $LNPARCHIVEDIR/lnp directory."
   cp ${ftp_data_file} ${LNPARCHIVEDIR}/${ftp_data_file1}..$$.txt.gz
   check_status
fi

#-----------------------------------------------------------------
step_number=3
#  Description: Move data file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number" 
   print "Moving txt.gz file to $LNP_STG_INDIR directory."
   mv -f ${ftp_data_file} ${LNP_STG_INDIR}
   check_status
fi
#-----------------------------------------------------------------
step_number=4
#  Description: Move tag file from ftp area to staging area.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   print "Moving tag file to $LNP_STG_INDIR directory."
   mv -f  ${ftp_tag_file} ${LNP_STG_INDIR}
   check_status
fi
#-----------------------------------------------------------------
step_number=5
#  Description: Unzipping the files.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
   echo "*** Step Number $step_number"
   print "Unzipping the files"
   cd $LNP_STG_INDIR
    gunzip -t ${ftp_data_file}
   if [[ $? -ne 0 ]]; then
      print " failed gunzip -t.  It will be deleted."
      rm ${tag_file}
      return 1
   else
      gunzip ${ftp_data_file}
      check_status
   fi
fi
#-----------------------------------------------------------------
step_number=6
# Description: Step to append data into LNP_DATA table.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   sqlldr userid=${ORA_CONNECT_MKDM} \
          control=${CTLDIR}/mkdm_ld_lnp_data.ctl \
          data=${LNP_STG_INDIR}/${ftp_data_file1}.txt \
          log=${LOGDIR}/mkdm_ld_lnp_data.log  \
          bad=${LOGDIR}/mkdm_ld_lnp_data.bad  \
          rows=10000 \
          errors=10000
	  check_status
fi

#-----------------------------------------------------------------
step_number=7
# Description: Calls SQL script to roll off data older than two month.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   run_sql mkdm_roll_off_lnp_data
   check_status
fi

#-----------------------------------------------------------------
step_number=8
# Description: Calls analyze function to analyze LNP_DATA.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   analyze_table MKDM LNP_DATA 10
   check_status
fi

#-----------------------------------------------------------------
step_number=9
# Description: The step to move the file to the archive directory.
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Deleting old txt file ."
   rm -f ${LNP_STG_INDIR}/${ftp_data_file1}.txt	
   check_status
   print "Deleting old TAG file ."
   rm -f ${LNP_STG_INDIR}/${ftp_tag_file}
   check_status 
fi

#-----------------------------------------------------------------
step_number=10
# Description: Deleting lnp files from archive directory which
#              are older than 90 days
#-----------------------------------------------------------------
if [ $start_step -le $step_number ]; then
   echo "*** Step Number $step_number"
   print "Deleting old files from $LNPARCHIVEDIR/lnp directory."
   rm -f `find ${LNPARCHIVEDIR} -mtime +30 -print`
   check_status
fi

exit 0
