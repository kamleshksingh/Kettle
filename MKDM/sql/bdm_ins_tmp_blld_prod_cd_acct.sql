-------------------------------------------------------------------------------
-- Program         :    bdm_ins_tmp_blld_prod_cd_acct.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Inserts latis records into tmp_blld_prod_cd_acct table 
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
WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Inserting into table TMP_BLLD_PROD_CD_ACCT


INSERT INTO tmp_blld_prod_cd_acct
SELECT /*+ PARALLEL(lat,4) */ * from tmp_blld_prod_cd_latis lat;

COMMIT;

QUIT;
