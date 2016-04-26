-------------------------------------------------------------------------------
-- Program         :  bdm_drop_rev_sum_temp_tbl.sql
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

WHENEVER SQLERROR EXIT FAILURE

INSERT INTO bdm_data_months_log VALUES('&2');
COMMIT;

QUIT;
