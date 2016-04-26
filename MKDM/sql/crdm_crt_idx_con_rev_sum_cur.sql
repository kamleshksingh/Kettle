-------------------------------------------------------------------------------
-- Program         :  crdm_crt_idx_con_rev_sum_cur.sql
--
-- Original Author :  urajend
--
-- Description     :  Create index on CONSUMER_REVENUE_SUMM_CUR table.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 09/07/2006 urajend  Initial Checkin
-- 12/31/2008 dxpanne  Updated tablespace to revenue_data
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

CREATE UNIQUE INDEX consumer_revenue_summ_cur_uk ON consumer_revenue_summ_cur(univ_acct_id)
tablespace revenue_data nologging parallel 4;

EXIT
