#!/bin/bash
. /g001/home/pentaho/bin/setenv.sh

export KETTLE_HOME=/g001/home/pentaho
#L_SCRIPTNAME=`basename $0`
export V_START_TIME=`date +%Y%m%d%H%M%S`
export SRC_DIR="${KETTLE_HOME}/extracts/richrelevance"
export FILE_PREFIX="catalog_full_arrowcom_"
export date_tag=`date +%Y'_'%m'_'%d`
export TRG_FILE="$FILE_PREFIX""${date_tag}"
export LOG_FILE=$LOG_DIR/"zip_richrelevance.""$V_START_TIME"".log"
echo $V_START_TIME $SRC_DIR $TRG_FILE $KETTLE_HOME
cd "$SRC_DIR"

echo "$TRG_FILE"

zip "${TRG_FILE}".zip *"$date_tag"".txt" >>"$LOG_FILE"

RC="$?"
if [ "$RC" -ne "0" ] ; then 
printf "Completed with failure $RC"
#exit $?
fi;

