-------------------------------------------------------------------------------
-- Program         :    bdm_crt_cur_week_dtl_temp.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Extract the records from BUSINESS_REVENUE_DET which are
--			populated after last week's BDMREVSUM Job Run into
--			BUS_WEEK_DTL_TEMP table 
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE BUS_WEEK_DTL_TEMP;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table BUS_WEEK_DTL_TEMP

CREATE	TABLE BUS_WEEK_DTL_TEMP
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT	
  dtl.jnl_blg_dt
  ,dtl.cust_account_id AS blg_acct_id   
  ,dtl.blg_to_cust_acct_id  as blg_to_blg_acct_id
  ,dtl.blg_sce_sys_cd
  ,dtl.sub_plan_id
  ,dtl.prod_cd
  ,dtl.lec_usoc
  ,dtl.bus_acty_cd
  ,dtl.rev_typ_cd
  ,dtl.usage_typ_cd
  ,dtl.svc_typ_cd
  ,dtl.orig_st_for_prvnc_cd
  ,dtl.term_st_for_prvnc_cd
  ,dtl.term_country_cd
  ,dtl.inter_intra_ind
  ,dtl.nlec_intra_lata_ind
  ,dtl.nlec_usage_type_cd
  ,dtl.minutes_of_use
  ,dtl.rev_amt
  ,dtl.load_control_key
  ,dtl.bill_last_dt
  ,TO_CHAR(dtl.jnl_blg_dt,'YYYYMM') AS bill_mo
FROM	business_revenue_det dtl
WHERE   to_char(dtl.load_dt,'YYYYMMDD') > to_char(to_date('&2'),'YYYYMMDD')
and to_char(dtl.load_dt,'YYYYMMDD') <= to_char(sysdate,'YYYYMMDD')
;

PROMPT	Table BUS_WEEK_DTL_TEMP created

QUIT;
