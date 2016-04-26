-------------------------------------------------------------------------------
-- Program         :  bdm_crt_blg_acct_id_tmp.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Creates blg_acct_id from csban, csban_iabs and prod_r
--                    Handled trim to remove traling spaces.
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
WHENEVER SQLERROR CONTINUE;

DROP TABLE blg_csban_btn_tmp;

WHENEVER SQLERROR EXIT FAILURE

ALTER SESSION ENABLE PARALLEL DML;

PROMPT	CREATES table blg_csban_btn_tmp

CREATE TABLE blg_csban_btn_tmp
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT /*+ PARALLEL(a,4) */ 
TRIM(btn||btn_cust_cd||rpad(nvl(btn_sort_cd, ' '), 1) ||rpad(nvl(btn_sfx, ' '), 4) ||rpad(nvl(btn_st_cd, ' '), 1)) AS blg_acct_id
,MIN(acct_estab_dat) AS acct_estab_dat
FROM csban a
 GROUP BY TRIM(btn||btn_cust_cd||rpad(nvl(btn_sort_cd, ' '), 1) ||rpad(nvl(btn_sfx, ' '), 4) ||rpad(nvl(btn_st_cd, ' '), 1))
UNION
SELECT /*+ PARALLEL(b,4) */
(ban||ban_cust_cd) AS blg_acct_id
,MIN(acct_estab_dat) AS acct_estab_dat
FROM 
csban_iabs b
GROUP BY ban||ban_cust_cd
UNION
SELECT /*+ PARALLEL(c,4) */
to_char(customer_acct_id) AS blg_acct_id
,orig_acct_setup_dt As acct_estab_dat
FROM
customer_acct@&2 c
;

QUIT;
