-------------------------------------------------------------------------------
-- Program         :  crdm_crt_con_rev_sum_temp.sql
--
-- Original Author :  urajend
--
-- Description     :  Create table CONSUMER_REVENUE_SUMM_TEMP with records from current
--                    partition of CONSUMER_REVENUE_SUMM and records present
--                    only in previous partition of CONSUMER_REVENUE_SUMM and not
--                    existing in current partition of CONSUMER_REVENUE_SUMM.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 09/07/2006 urajend  Initial Checkin
-- 12/31/2008 dxpanne  Updated tablespace to revenue_data
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

PROMPT Dropping CONSUMER_REVENUE_SUMM_TEMP table

DROP TABLE CONSUMER_REVENUE_SUMM_TEMP;

PROMPT CONSUMER_REVENUE_SUMM_TEMP table dropped

WHENEVER SQLERROR EXIT FAILURE

COLUMN curr_partition NEW_VALUE curr_partition

COLUMN prev_partition NEW_VALUE prev_partition

SELECT  'P'||TO_CHAR(sysdate,'YYYYMM') curr_partition from dual;

SELECT  'P'||TO_CHAR(ADD_MONTHS(sysdate,-1),'YYYYMM') prev_partition from dual;

PROMPT  Creating CONSUMER_REVENUE_SUMM_TEMP table

CREATE TABLE consumer_revenue_summ_temp
TABLESPACE revenue_data
AS
SELECT  *
FROM consumer_revenue_summ partition (&curr_partition)
UNION
SELECT  prev.*
FROM    consumer_revenue_summ partition (&prev_partition) prev
        ,consumer_revenue_summ partition (&curr_partition) curr
WHERE   prev.univ_acct_id = curr.univ_acct_id(+)
AND     curr.univ_acct_id is null;

PROMPT  CONSUMER_REVENUE_SUMM_TEMP Table Created

QUIT;
