-------------------------------------------------------------------------------
-- Program         :  bdm_crt_idx_con_rev_sum_cur.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create index on BUSINESS_REVENUE_SUMM_CUR table.
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
WHENEVER SQLERROR EXIT FAILURE

CREATE UNIQUE INDEX business_revenue_summ_cur_uk ON business_revenue_summ_cur(blg_acct_id,sce_sys_cd)
tablespace brev_summ_cur_ts  nologging parallel 4;

EXIT
