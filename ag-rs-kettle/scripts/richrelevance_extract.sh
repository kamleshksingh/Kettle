#!/bin/sh

##
# Create Rich relevance extract
##

# SET required variables
. /g001/home/pentaho/bin/setenv.sh
v_START_TIME=`date +%Y%m%d%H%M%S`
$KETTLE_HOME/data-integration/kitchen.sh -file $BASE_DIR/tasks/rich_relevance_extract/richrelevance_inventory_extract.kjb -level=Basic > $LOG_DIR/richrelevance_inventory_extract_${v_START_TIME}.log


RC="$?"
if [ "$RC" -eq "0" ] ; then 
export V_START_TIME=`date +%Y%m%d%H%M%S`
export SRC_DIR="${KETTLE_HOME}/extracts/richrelevance"
export FILE_PREFIX="catalog_full_arrowcom_"
export date_tag=`date +%Y'_'%m'_'%d`
export TRG_FILE="$FILE_PREFIX""${date_tag}".zip
export TRG_DIR=/home/arrowelectronics
#export LOG_DIR=/b001/logs
##
# Create Rich relevance extract
##

# SET required variables

v_START_TIM=E`date +%Y%m%d%H%M%S`
export VAR_UTILS_DIR=$KETTLE_HOME/utils

$KETTLE_HOME/data-integration/kitchen.sh -file $VAR_UTILS_DIR/ftp_process.kjb -param:DEST_FILE=$TRG_FILE -param:DEST_PATH=$TRG_DIR -param:SRC_FILE="$SRC_DIR"/"$TRG_FILE" -param:ftp_box=RICHRELEVANCE_FTP_HOST -param:ftp_operation=put -level=Rowlevel > $LOG_DIR/richrelevance_ftp_process_${v_START_TIME}.log

#exit $?
else
exit $RC
fi;
