-------------------------------------------------------------------------------
-- Program         :    bdm_crt_tmp_blld_prod_cd_latis.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create a temporary tmp_blld_prod_cd_latis table. 
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga Initial Checkin
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE tmp_blld_prod_cd_latis;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table TMP_BLLD_PROD_CD_LATIS


CREATE TABLE tmp_blld_prod_cd_latis
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT DISTINCT a.blg_acct_id, b.prod_cd 
FROM bus_week_dtl_temp a, tmp_blld_prod_cd_acct b
WHERE a.blg_to_blg_acct_id = b.blg_acct_id
AND a.prod_cd = b.prod_cd
;


PROMPT	TABLE tmp_blld_prod_cd_latis created

QUIT;


