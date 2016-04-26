-------------------------------------------------------------------------------
-- Program         :   check_create_partition.sql 
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This SQL spools the status for partition Creation process.
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID        Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 12/11/2007 kraman    Initial check-in   
-- 07/25/2008 axsi      Removed 'XP' (Partition Exists) from the error list 
-------------------------------------------------------------------------------


WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

SET HEAD OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGES 0

SPOOL &1

SELECT count(*) FROM dmart_partition_ref
 WHERE partition_error_cd IN ('PE','EE','IE','NN','EE')
   AND UPPER(MODULE_CD) like UPPER('&2%')
   AND partition_ind='Y';

SPOOL OFF;

QUIT;
