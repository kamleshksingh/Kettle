#!/bin/ksh
#*******************************************************************************
#** Program         :  mast_addr_xref_ncoa_check.sh
#**
#** Job Name        :  Runs as script
#**
#** Original Author :  nbeneve
#**
#** Description     :  Checks master address xref ncoa partition and fails 
#**                    if it is not refreshed.
#**
#** Revision History:  Please do not stray from the example provided.
#**
#** Modfied    User
#** Date       ID       Description
#** MM/DD/YYYY CUID
#** ---------- -------- ------------------------------------------------
#** 08/10/2008 nbeneve  Initial checkin.
#*****************************************************************************

. ~/.mkdm_env

count=`sqlplus -s $ORA_CONNECT << END_OF_SQL
SET PAUSE OFF
SET HEAD OFF
SET SHOW OFF
SET FEED OFF
SET ECHO OFF
SET LINESIZE 30
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
SELECT count(1) FROM master_address_xref partition (MAX_NCOA) 
WHERE sce_sys_cd = 'NCOA' and load_date > sysdate - 5;
QUIT;
END_OF_SQL`

if [ $count -gt 0 ]; then
exit 0
else
exit 1
fi

