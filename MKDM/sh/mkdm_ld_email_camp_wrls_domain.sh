#!/bin/ksh
#*******************************************************************************
#** Program         :  mkdm_ld_email_camp_wrls_domain.sh 
#**
#** Job Name        :  ECMPWRLSDM  
#**
#** Original Author :  ddamoda
#**
#** Description     :  Loads the data into email_camp_wrls_domain table using sqlldr
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 04/05/2009 ddamoda  Initial Check in. 
#** 08/06/2009 mxlaks2  Changed the exit status of check_status function 
#*****************************************************************************

#-----------------------------------------------------------------
# Set $ parameters here.
#-----------------------------------------------------------------
L_SCRIPTNAME=`Basename $0`

FNAME=DomainNames.txt
CTLFILE=${CTLDIR}/mkdm_ld_email_camp_wrls_domain.ctl


SQLLDR_LogFile=${LOGDIR}/mkdm_ld_email_camp_wrls_domain_$$.log
SQLLDR_UserId=${ORA_CONNECT}
SQLLDR_BadFile=${LOGDIR}/mkdm_ld_email_camp_wrls_domain_$$.bad
SQLLDR_DisFile=${LOGDIR}/mkdm_ld_email_camp_wrls_domain_$$.dis

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
# Function to check the return status and set the appropriate
# message
#-----------------------------------------------------------------
function check_status
{
  if [ $? -ne 0 ]; then
     err_msg="$L_SCRIPTNAME failed because of $1"
     echo "$err_msg"
     exit $step_number 
  fi
}

#-----------------------------------------------------------------
#Begin Main Program
#-----------------------------------------------------------------

print "$L_SCRIPTNAME started at `date` \n"
echo $FNAME "is being loaded by sqlldr"

#-----------------------------------------------------------------
step_number=1
#Description: Loading data from file into EMAIL_CAMP_WRLS_DOMAIN  
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  cd ${ECAMP_FILE_DIR}

  strings -a $FNAME > temp.txt
  rm -rf $FNAME
  mv temp.txt $FNAME
  sqlldr userid=${ORA_CONNECT} \
         control=${CTLFILE} \
         DIRECT=TRUE \
         ROWS=1000 \
         log=$SQLLDR_LogFile \
         bad=$SQLLDR_BadFile \
         discard=$SQLLDR_DisFile \
         data=$FNAME \
         ERRORS=0 \
         SKIP_UNUSABLE_INDEXES=TRUE
  check_status "error in loading $FNAME into the table using sqlldr"
fi

#-----------------------------------------------------------------
step_number=2
#Description: Archieving the loaded file. 
#-----------------------------------------------------------------
if [ $start_step -le $step_number ] ; then
  echo "*** Step Number $step_number"
  cd ${ECAMP_FILE_DIR}
  mv -f ${FNAME} ${ECAMP_ARC_DIR}/${FNAME}.$$
  check_status
  
  cd ${ECAMP_ARC_DIR}
  count=`find Domain*.txt -mtime +366|wc -l`
  if [ $count -ne 0 ] ; then
  find Domain*.txt -mtime +366 -exec rm -f {}    \;
  check_status
  fi
  
fi

echo $(date) done
exit 0
