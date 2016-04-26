-------------------------------------------------------------------------------
-- Program         :    bdm_drop_monthly_temp_tbls.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Drop temp tables
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------

SET TIMING ON
SET ECHO OFF

WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ;

DROP TABLE business_three_months_rev;
DROP TABLE business_rev_sum_temp1;
DROP TABLE business_rev_sum_temp2;
DROP TABLE bus_rev_avg_temp;

QUIT;
