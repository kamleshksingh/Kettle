-------------------------------------------------------------------------------
-- Program         :  ld_ris_3mon_perm_usage_trim.sql 
--
-- Original Author : dpannee 
--
-- Description     : Removes records older than 3months.
--
-- Revision History: Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 03/30/2006 dpannee Initial checkin 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET ECHO ON

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

DELETE FROM ris_3mon_hist_perm_usage
 WHERE load_date < ADD_MONTHS(SYSDATE, -3);

COMMIT;
QUIT
