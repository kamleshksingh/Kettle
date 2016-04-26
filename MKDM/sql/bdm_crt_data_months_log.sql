-------------------------------------------------------------------------------
-- Program         :    bdm_crt_data_months_log.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create temp table to maintain the distinct data months
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

DROP TABLE bdm_data_months_log;

WHENEVER SQLERROR EXIT FAILURE;

CREATE TABLE bdm_data_months_log
(
  BILL_MO     VARCHAR2(30)
)
TABLESPACE STAGING;

QUIT;
