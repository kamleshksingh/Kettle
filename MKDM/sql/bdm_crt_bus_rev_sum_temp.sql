-------------------------------------------------------------------------------
-- Program         :  bdm_crt_bus_rev_sum_temp.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create table business_REVENUE_SUMM_TEMP with records from current
--                    partition of business_REVENUE_SUMM and records present
--                    only in previous partition of BUSINESS_REVENUE_SUMM and not
--                    existing in current partition of BUSINESS_REVENUE_SUMM.
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

PROMPT Dropping BUSINESS_REVENUE_SUMM_TEMP table

DROP TABLE business_revenue_summ_temp;

PROMPT BUSINESS_REVENUE_SUMM_TEMP table dropped

WHENEVER SQLERROR EXIT FAILURE

COLUMN curr_partition NEW_VALUE curr_partition

COLUMN prev_partition NEW_VALUE prev_partition

SELECT  'P'||TO_CHAR(sysdate,'YYYYMM') curr_partition from dual;

SELECT  'P'||TO_CHAR(ADD_MONTHS(sysdate,-1),'YYYYMM') prev_partition from dual;

PROMPT  Creating BUSINESS_REVENUE_SUMM_TEMP table

CREATE TABLE business_revenue_summ_temp
TABLESPACE BREV_SUMM_CUR_TS
AS
SELECT  *
FROM business_revenue_summ partition (&curr_partition)
UNION
SELECT  prev.*
FROM    business_revenue_summ partition (&prev_partition) prev
        ,business_revenue_summ partition (&curr_partition) curr
WHERE   prev.blg_acct_id = curr.blg_acct_id(+)
AND     curr.blg_acct_id is null;

PROMPT  BUSINESS_REVENUE_SUMM_TEMP Table Created

QUIT;
