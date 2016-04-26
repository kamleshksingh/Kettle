#!/bin/sh
# SET required variables
. /b001/app/kettle/bin/setenv.sh

$KETTLE_HOME/data-integration/kitchen.sh -file $BASE_DIR/tasks/pac_inventory_extract/pac_inventory_extract.kjb --level=Basic >> $LOG_DIR/pac_inventory_extract.log
