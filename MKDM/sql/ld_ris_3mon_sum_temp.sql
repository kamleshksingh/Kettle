-------------------------------------------------------------------------------
-- Program         : ld_ris_3mon_sum_temp.sql
--
-- Original Author : jkading
--
-- Revision History: Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 07/14/2004 jkading  Initial Checkin
-- 03/30/2006 dpannee  Using RIS_3MON_HIST_PERM_USAGE instead of RIS_3MON_HIST_PERM
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE 
WHENEVER SQLERROR CONTINUE

DROP TABLE ris_3mon_sum_temp;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE ris_3mon_sum_temp
TABLESPACE WORK_TEMP
NOLOGGING PARALLEL 5 AS
SELECT /*+ parallel (a,6) */ distinct
       tn
      ,TO_CHAR(bill_date,'YYYYMM') bill_ym
      ,sum(decode(dom_int_indr,'DOM',mou,'0'))
          OVER(PARTITION BY tn,bill_date) tot_dom_mou
      ,sum(decode(dom_int_indr,'DOM',revenue,'0'))
          OVER(PARTITION BY tn,bill_date) tot_dom_rev
      ,sum(decode(dom_int_indr,'INT',mou,'0'))
          OVER(PARTITION BY tn,bill_date) tot_int_mou
      ,sum(decode(dom_int_indr,'INT',Revenue,'0'))
          OVER(PARTITION BY tn,bill_date) tot_int_rev
      ,sum(decode(term_country_cd,'CAN',mou,'0'))
          OVER(PARTITION BY tn,bill_date) tot_can_mou
      ,sum(decode(term_country_cd,'CAN',revenue,'0'))
          OVER(PARTITION BY tn,bill_date) tot_can_rev
      ,sum(decode(term_country_cd,'MEX',mou,'0'))
          OVER(PARTITION BY tn,bill_date) tot_mex_mou
      ,sum(decode(term_country_cd,'MEX',revenue,'0'))
           OVER(PARTITION BY tn,bill_date) tot_mex_rev
FROM ris_3mon_hist_perm_usage;

QUIT
