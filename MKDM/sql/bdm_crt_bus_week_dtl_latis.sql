-------------------------------------------------------------------------------
-- Program         :    bdm_ins_cur_week_dtl_temp.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Extract latis records from BUSINESS_REVENUE_DET which are
--			populated after last week's BDMREVSUM Job Run into
--			BUS_WEEK_DTL_LATIS table 
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
WHENEVER SQLERROR CONTINUE

DROP TABLE bus_week_dtl_latis;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table BUS_WEEK_DTL_LATIS

CREATE TABLE bus_week_dtl_latis
TABLESPACE &1
PARALLEL 5
NOLOGGING
AS
SELECT /*+ PARALLEL(dtl,4) PARALLEL(bus,4) */	
   DISTINCT
   dtl.jnl_blg_dt
  ,dtl.cust_account_id 
  ,dtl.blg_to_cust_acct_id  
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
  ,dtl.rowid as v_rowid
FROM  business_rev_det_latis dtl
     ,business_revenue_det bus
WHERE
    bus.blg_sce_sys_cd='CRIS'
    AND bus.cust_account_id = dtl.blg_to_cust_acct_id
    AND to_char(bus.load_dt,'YYYYMMDD') > to_char(to_date('&2'),'YYYYMMDD')
    AND to_char(bus.load_dt,'YYYYMMDD') <= to_char(sysdate,'YYYYMMDD')
UNION 
SELECT /*+ PARALLEL(dtl,4) PARALLEL(bus,4) */	
  DISTINCT
  dtl.jnl_blg_dt
  ,dtl.cust_account_id 
  ,dtl.blg_to_cust_acct_id  
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
  ,dtl.rowid as v_rowid
FROM  business_rev_det_latis dtl
     ,business_revenue_det bus
WHERE
    dtl.blg_to_cust_acct_id = bus.cust_account_id(+) 
    AND to_char(dtl.load_dt,'YYYYMMDD') < to_char((sysdate-10),'YYYYMMDD') 
    AND bus.cust_account_id is null
;

COMMIT;


QUIT;
