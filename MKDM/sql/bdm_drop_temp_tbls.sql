-------------------------------------------------------------------------------
-- Program         :    bdm_drop_temp_tbls.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Drop temp tables
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------

SET TIMING ON
SET ECHO OFF

WHENEVER OSERROR EXIT FAILURE ;
WHENEVER SQLERROR CONTINUE;

DROP TABLE bus_week_dtl_temp;
DROP TABLE tmp_blld_usoc_acct;
DROP TABLE tmp_blld_prod_cd_acct;
DROP TABLE bus_week_dtl_latis;
DROP TABLE tmp_blld_prod_cd_latis;

QUIT;
