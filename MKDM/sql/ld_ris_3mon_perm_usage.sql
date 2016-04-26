-- Program         : ld_ris_3mon_perm_usage.sql 
--
-- Original Author : dpannee 
--
-- Description     : 
--
-- Revision History:
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 03/30/2006 dpannee  initial checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
---------------------------------------------------------------------------------
SET TIMING ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

PROMPT Inserting into ris_3mon_hist_perm_usage
PROMPT ***************************************

INSERT /*+ APPEND */ INTO ris_3mon_hist_perm_usage
 SELECT /*+ PARALLEL (a,4) */ * 
    FROM ris_perm_usage_tmp a;


COMMIT;
QUIT
