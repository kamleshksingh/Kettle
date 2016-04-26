-------------------------------------------------------------------------------
-- Program         : ld_3mon_dom_temp.sql
--
-- Original Author : jkading
--
-- Revision History:  Please do not stray from the example provided.
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

DROP TABLE ris_3mon_dom_temp;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE ris_3mon_dom_temp
TABLESPACE WORK_TEMP
NOLOGGING PARALLEL 5 AS
SELECT tn
      ,term_country_cd
  FROM ( SELECT tn
               ,term_country_cd
               ,avg_int_mou
               ,RANK() OVER (PARTITION BY tn ORDER BY avg_int_mou desc) as seq
           FROM (SELECT distinct tn
                       ,term_country_cd
                       ,AVG(tot_int_mou)
                           OVER (PARTITION BY  tn, term_country_cd) avg_int_mou
                   FROM (SELECT tn
                               ,to_char(BILL_DATE,'YYYYMM') bill_ym
                               ,SUM(DECODE(dom_int_indr,'INT',mou,'0')) tot_int_mou
                               ,term_country_cd
                           FROM ris_3mon_hist_perm_usage
                          GROUP by tn, bill_date, term_country_cd
                       )
                )
       )
 WHERE seq=1;

QUIT
