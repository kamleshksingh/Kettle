-------------------------------------------------------------------------------
-- Program         :  crdm_drp_con_rev_sum_cur.sql
--
-- Original Author :  urajend
--
-- Description     :  Drop the table CONSUMER_REVENUE_SUMM_CUR.
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
WHENEVER SQLERROR CONTINUE

DROP TABLE CONSUMER_REVENUE_SUMM_CUR;

EXIT
