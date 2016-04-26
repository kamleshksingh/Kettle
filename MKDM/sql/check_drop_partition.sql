--*****************************************************************************
--** Program         :  mkdm_check_drop_partition.sql
--**
--** Original Author :  
--**
--** Description     :  This SQL sools the status for partition Dropping process.
--**                    
--**
--** Revision History:  Please do not stray from the example provided.
--**
--** Modfied    User
--** Date       ID       Description
--** MM/DD/YYYY CUID
--** ---------- -------- ------------------------------------------------
--** 11/13/2007  kraman  Intial Checkin
--*****************************************************************************

WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

SET HEAD OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGES 0

SPOOL &1

SELECT count(*) FROM dmart_partition_ref
 WHERE partition_error_cd IN ('TE','DE','IE','NN')
   AND UPPER(module_cd) like UPPER('&2%')
   AND partition_ind='Y';

SPOOL OFF;

QUIT;
