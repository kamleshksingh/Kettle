-------------------------------------------------------------------------------
-- Program         :  bdm_rename_bus_rev_sum_temp_cur.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Rename the table BUSINESS_REVENUE_SUMM_TEMP2 to BUSINESS_REVENUE_SUMM_CUR.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 06/19/2007 axsi     Provided SELECT privilege  to bdm_user
-- 04/28/2009 sxlank2  Changed temp table name to BUSINESS_REVENUE_SUMM_TEMP2
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

PROMPT Renaming table business_revenue_summ_temp2 to business_revenue_summ_cur

RENAME business_revenue_summ_temp2 to business_revenue_summ_cur;

PROMPT Table Renamed

PROMPT Granting Select Privilege to BUSINESS_REVENUE_SUMM_CUR Table

GRANT SELECT ON BUSINESS_REVENUE_SUMM_CUR TO bdm_all_read,bdm_user;

PROMPT Grant Succeeded

EXIT
