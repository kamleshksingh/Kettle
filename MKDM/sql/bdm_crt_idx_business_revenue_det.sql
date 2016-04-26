-------------------------------------------------------------------------------
-- Program         :  bdm_crt_idx_business_revenue_det.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create index for bus_week_dtl_temp table.
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

DROP index bus_revenue_det_idx1;

WHENEVER SQLERROR EXIT FAILURE

PROMPT	Creating index on bus_week_dtl_temp table

CREATE INDEX bus_revenue_det_idx1 ON bus_week_dtl_temp(blg_acct_id)
TABLESPACE &1 NOLOGGING PARALLEL 4;

QUIT;
