-------------------------------------------------------------------------------
-- Program         :  bdm_crt_idx_business_three_months_rev.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create index for business_three_months_rev table.
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

DROP index bus_three_months_rev_idx1;

WHENEVER SQLERROR EXIT FAILURE

PROMPT	Creating index on business_three_months_rev table

CREATE INDEX bus_three_months_rev_idx1 ON business_three_months_rev(blg_acct_id)
TABLESPACE &1 NOLOGGING PARALLEL 4;

QUIT;

