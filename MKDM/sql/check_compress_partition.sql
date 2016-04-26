-------------------------------------------------------------------------------
-- Program         :  check_compress_partition.sql
--
-- Original Author :  dxpanne
--
-- Description     :  To check the error 
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID      Description
-- MM/DD/YYYY CUID
------------- -------- --------------------------------------------------------
-- 07/25/2008 dxpanne Initial check in
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

SET HEAD OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGES 0

SPOOL &2

SELECT count(*) FROM dmart_partn_compress_ref
 WHERE compress_error_cd IN ('E','IE','EE')
   AND UPPER(module_cd) like UPPER('&1');
   
SPOOL OFF;
