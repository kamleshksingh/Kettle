-------------------------------------------------------------------------------
-- Program         :  bdm_drp_bus_rev_sum_cur.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Drop the table BUSINESS_REVENUE_SUMM_CUR.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/28/2009 sxlank2  Added DROP TABLE BUSINESS_REVENUE_SUMM_TEMP
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

DROP TABLE BUSINESS_REVENUE_SUMM_CUR;

DROP TABLE BLG_CSBAN_BTN_TMP;

DROP TABLE BUSINESS_REVENUE_SUMM_TEMP;

QUIT;

