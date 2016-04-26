-------------------------------------------------------------------------------
-- Program         :    bdm_ins_cur_week_dtl_temp.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Insert Latis records into bus_week_dtl_temp table.
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 04/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Inserting into table BUS_WEEK_DTL_TEMP

INSERT INTO bus_week_dtl_temp
SELECT /*+ PARALLEL(dtl,4) PARALLEL(bus,4) */	
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
FROM  
   bus_week_dtl_latis dtl
;

COMMIT;

PROMPT	Table BUS_WEEK_DTL_TEMP loaded successfully 

QUIT;
