-------------------------------------------------------------------------------
-- Program         :  bdm_crt_idx_tmp_blld_prod_cd_acct.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create index for tmp_blld_prod_cd_acct table.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

DROP index tmp_blld_prod_cd_acct_idx1;

WHENEVER SQLERROR EXIT FAILURE

PROMPT	Creating index on tmp_blld_prod_cd_acct table

CREATE INDEX tmp_blld_prod_cd_acct_idx1 ON tmp_blld_prod_cd_acct(blg_acct_id)
TABLESPACE &1 NOLOGGING PARALLEL 4;

QUIT;
