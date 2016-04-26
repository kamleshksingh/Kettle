-------------------------------------------------------------------------------
-- Program         :  bdm_bus_mkdm_drop_rev_sum_temp_tbl.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Drop revenue summary weekly temp table.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/23/2007 rananto  Performance Tuning
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

TRUNCATE TABLE &1;

DROP TABLE &1;

TRUNCATE TABLE &2;

DROP TABLE &2;

TRUNCATE TABLE BUS_REV_SUM_WKLY_TEMP;

DROP TABLE BUS_REV_SUM_WKLY_TEMP;

QUIT;
