-------------------------------------------------------------------------------
-- Program         :  crdm_rename_con_rev_sum_temp_cur.sql
--
-- Original Author :  urajend
--
-- Description     :  Rename the table CONSUMER_REVENUE_SUMM_TEMP to CONSUMER_REVENUE_SUMM_CUR.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 09/07/2006 urajend  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

PROMPT Renaming table consumer_revenue_summ_temp to consumer_revenue_summ_cur

RENAME consumer_revenue_summ_temp to consumer_revenue_summ_cur;

PROMPT Table Renamed

PROMPT Granting Select Privilege to CONSUMER_REVENUE_SUMM_CUR Table

GRANT SELECT ON CONSUMER_REVENUE_SUMM_CUR TO crdm_all_read;

PROMPT Grant Succeeded

EXIT
