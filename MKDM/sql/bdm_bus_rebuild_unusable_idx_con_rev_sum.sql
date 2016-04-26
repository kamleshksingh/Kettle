-------------------------------------------------------------------------------
-- Program         :  bdm_bus_rebuild_unusable_idx_con_rev_sum.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Rebuild unusable indexes of BUSINESS_REVENUE_SUMM table.
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

COLUMN partition_name NEW_VALUE partition_name

SELECT  'P'||substr('&1',LENGTH('&1')-5) partition_name FROM dual;

PROMPT Rebuilding Unusable Indexes on BUSINESS_REVENUE_SUMM

ALTER TABLE business_revenue_summ MODIFY PARTITION &partition_name REBUILD UNUSABLE LOCAL INDEXES;

PROMPT  Indexes Rebuilt Successfully

QUIT;
