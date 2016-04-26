-------------------------------------------------------------------------------
-- Program         :  bdm_bus_exch_part_rev_summary.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Exchange data of revenue summary weekly temp table with
--		      the corresponding partition of BUSINESS_REVENUE_SUMM table.
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

SELECT	'P'||substr('&1',LENGTH('&1')-5) partition_name FROM dual;

PROMPT Truncating the partition of BUSINESS_REVENUE_SUMM

ALTER TABLE business_revenue_summ TRUNCATE PARTITION &partition_name;

PROMPT Exchanging the revenue summary temp table with that of partition BUSINESS_REVENUE_SUMM

ALTER TABLE business_revenue_summ EXCHANGE PARTITION &partition_name WITH TABLE &1 WITH VALIDATION;

PROMPT "Partition exchange done"

QUIT;
