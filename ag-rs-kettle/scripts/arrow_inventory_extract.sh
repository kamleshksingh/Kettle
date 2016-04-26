#!/bin/sh
# SET required variables
. /b001/app/kettle/bin/setenv.sh

$KETTLE_HOME/data-integration/kitchen.sh -file $BASE_DIR/tasks/arrow_inventory_extract/arrow_inventory_extract.kjb -level=Basic >> $LOG_DIR/arrow_inventory_extract.log
