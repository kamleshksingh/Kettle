-------------------------------------------------------------------------------
-- Program         : ld_usage_tn.sql
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
-- 02/23/2005 bsyptak  add in new columns from ris_3mon_avg_can_mex_temp table
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

TRUNCATE TABLE ld_usage_tn;

PROMPT Inserting into table ld_usage_tn
PROMPT *********************************

INSERT /*+ PARALLEL(a,4) PARALLEL(b,4) PARALLEL(c,4) */
INTO ld_usage_tn
(    btn
    ,btn_cust_cd
    ,wtn
    ,avg3mo_dom_mou
    ,avg3mo_dom_rvn_amt
    ,avg3mo_inrnatl_mou
    ,avg3mo_inrnatl_rvn_amt
    ,avg3mo_can_ld_mou
    ,avg3mo_can_rvn_amt
    ,avg3mo_mex_ld_mou
    ,avg3mo_mex_rvn_amt
    ,dominate_country_cd
    ,load_date
)
SELECT
     a.btn
    ,a.btn_cust_cd
    ,b.tn
    ,b.avg_dom_mou
    ,b.avg_dom_rev
    ,b.avg_int_mou
    ,b.avg_int_rev
    ,b.avg_can_mou
    ,b.avg_can_rev
    ,b.avg_mex_mou
    ,b.avg_mex_rev
    ,c.term_country_cd
    ,trunc(SYSDATE)
FROM account_key_ref a
    ,ris_3mon_avg_temp b
    ,(SELECT tn,term_country_cd
        FROM (SELECT DISTINCT tn,term_country_cd
                    ,RANK()
                        OVER (PARTITION BY tn ORDER BY high_cntry desc) as seq
                FROM (SELECT DISTINCT tn,term_country_cd
                            ,SUM(DECODE(term_country_cd,'MEX',2,'CAN',1,0))
                                OVER (PARTITION BY  tn, term_country_cd) high_cntry
                        FROM ris_3mon_dom_temp 
                     )
             )
       WHERE seq=1
      ) c
WHERE a.WTN = b.TN
  AND b.tn = c.tn;

COMMIT;
QUIT
