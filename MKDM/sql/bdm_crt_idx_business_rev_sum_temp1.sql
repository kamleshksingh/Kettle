-------------------------------------------------------------------------------
-- Program         :  bdm_crt_idx_business_rev_sum_temp1.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create index for business_rev_sum_temp1 table.
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

DROP index business_rev_sum_temp1_idx1;


WHENEVER SQLERROR EXIT FAILURE

PROMPT	Creating index on business_rev_sum_temp1 table

CREATE INDEX business_rev_sum_temp1_idx1 ON business_rev_sum_temp1(blg_acct_id)
TABLESPACE &1 NOLOGGING PARALLEL 4;


QUIT;

