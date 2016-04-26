-------------------------------------------------------------------------------
-- Program         : ld_ris_3mon_avg_temp.sql
--
-- Original Author : dpannee
--
-- Revision History: Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 03/30/2006 dpannee  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE 
WHENEVER SQLERROR CONTINUE

DROP TABLE ris_3mon_avg_temp;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE ris_3mon_avg_temp
TABLESPACE WORK_TEMP
NOLOGGING PARALLEL 5 AS
SELECT /*+ parallel (a,6) */ distinct
       tn
      ,ceil(avg(tot_dom_mou)
           OVER(PARTITION BY tn))    avg_dom_mou
      ,round(avg(tot_dom_rev)
           OVER(PARTITION BY tn),2)  avg_dom_rev
      ,ceil(avg(tot_int_mou)
           OVER(PARTITION BY tn))    avg_int_mou
      ,round(avg(tot_int_rev)
           OVER(PARTITION BY tn),2)  avg_int_rev
      ,ceil(avg(tot_can_mou)
           OVER(PARTITION BY tn))    avg_can_mou
      ,round(avg(tot_can_rev)
           OVER(PARTITION BY tn),2)  avg_can_rev
      ,ceil(avg(tot_mex_mou)
           OVER(PARTITION BY tn))    avg_mex_mou
      ,round(avg(tot_mex_rev)
           OVER(PARTITION BY tn),2)  avg_mex_rev
  FROM ris_3mon_sum_temp a;

QUIT
