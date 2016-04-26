-------------------------------------------------------------------------------
-- Program         :    bdm_crt_three_months_data.sql
--
-- Original Author :    mmuurga
--
-- Description     :    Create table business_three_months_rev by taking current
--                      month data from CUR_WEEK_DTL_TEMP and previous month's 
--			revenue from BUSINESS_REV_SUM table
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ----------------------------------------------------- 
-- 01/24/2007 mmuurga  Initial Checkin
-- 04/23/2007 ranato   Performance Tuning. 
-- 07/10/2007 ddamoda  Changed the column name cur_mo_video_recurring_amt to
                       cur_mo_quest_recurring_amt
-- 07/23/2007 ddamoda  Changed the column name cur_mo_quest_recurring_amt to 
                       cur_mo_qwest_video_recur_amt. 
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE business_three_months_rev;

WHENEVER SQLERROR EXIT FAILURE;

COLUMN one_months_prior NEW_VALUE one_months_prior;
COLUMN two_months_prior NEW_VALUE two_months_prior;

SELECT  'P'||TO_CHAR(add_months(to_date(&1,'YYYYMM'),-1),'YYYYMM') one_months_prior,
	'P'||TO_CHAR(add_months(to_date(&1,'YYYYMM'),-2),'YYYYMM') two_months_prior
  FROM  dual;

PROMPT	Creating table BUSINESS_THREE_MONTHS_REV

CREATE	TABLE business_three_months_rev
TABLESPACE &2
NOLOGGING
PARALLEL 4
AS
SELECT	
   dtl.blg_acct_id
,dtl.blg_to_blg_acct_id
,dtl.blg_sce_sys_cd
,trunc(dtl.jnl_blg_dt) as BILL_DT
,dtl.cur_mo_dsl_tot_amt
,dtl.cur_mo_ld_bndl_amt
,dtl.cur_mo_ld_rcrg_amt
,dtl.cur_mo_ld_tot_amt
,dtl.cur_mo_ld_tot_mou_qty
,dtl.cur_mo_ld_intralata_amt
,dtl.cur_mo_ld_intralata_mou_qty
,dtl.cur_mo_ld_interlata_amt
,dtl.cur_mo_ld_interlata_mou_qty
,dtl.cur_mo_ld_domestic_amt
,dtl.cur_mo_ld_domestic_mou_qty
,dtl.cur_mo_ld_intl_amt
,dtl.cur_mo_ld_intl_mou_qty
,dtl.cur_mo_ld_tot_usg_amt
,dtl.cur_mo_wireless_bndl_amt
,dtl.cur_mo_wireless_rcrg_amt
,dtl.cur_mo_wireless_tot_amt
,dtl.cur_mo_wireline_bndl_amt
,dtl.cur_mo_wireline_rcrg_amt
,dtl.cur_mo_wireline_tot_amt
,dtl.cur_mo_video_bndl_amt
,dtl.cur_mo_qwest_video_recur_amt
,dtl.cur_mo_video_tot_amt
,dtl.cur_mo_iptv_amt
,dtl.cur_mo_voip_amt
,dtl.cur_mo_package_bndl_amt
,dtl.cur_mo_package_tot_amt
,dtl.cur_mo_tot_bndl_dscnt_amt
,dtl.cur_mo_tot_bndl_amt
,dtl.cur_mo_tot_rev_amt
,dtl.cur_mo_tot_mou_qty
,dtl.cur_mo_voip_recurring_amt
,dtl.cur_mo_ia_amt
,dtl.cur_mo_ia_recurring_amt
,dtl.cur_mo_wireless_mou
,dtl.cur_mo_recurring_amt
,dtl.cur_mo_hicap_data_spend
,dtl.bill_mo
FROM business_rev_sum_temp2 dtl
UNION
SELECT 
 sum.blg_acct_id
,sum.blg_to_blg_acct_id
,sum.sce_sys_cd
,sum.bill_dt
,sum.cur_mo_dsl_tot_amt
,sum.cur_mo_ld_bndl_amt
,sum.cur_mo_ld_recurring_amt
,sum.cur_mo_ld_tot_amt
,sum.cur_mo_ld_tot_mou_qty
,sum.cur_mo_ld_intralata_amt
,sum.cur_mo_ld_intralata_mou_qty
,sum.cur_mo_ld_interlata_amt
,sum.cur_mo_ld_interlata_mou_qty
,sum.cur_mo_ld_domestic_amt
,sum.cur_mo_ld_domestic_mou_qty
,sum.cur_mo_ld_intl_amt
,sum.cur_mo_ld_intl_mou_qty
,sum.cur_mo_ld_tot_usg_amt
,sum.cur_mo_wireless_bndl_amt
,sum.cur_mo_wireless_recurring_amt
,sum.cur_mo_wireless_tot_amt
,sum.cur_mo_wireline_bndl_amt
,sum.cur_mo_wireline_recurring_amt
,sum.cur_mo_wireline_tot_amt
,sum.cur_mo_video_bndl_amt
,sum.cur_mo_qwest_video_recur_amt
,sum.cur_mo_video_tot_amt
,sum.cur_mo_iptv_amt
,sum.cur_mo_voip_amt
,sum.cur_mo_package_bndl_amt
,sum.cur_mo_package_amt
,sum.cur_mo_tot_bndl_disc_amt
,sum.cur_mo_tot_bndl_amt
,sum.cur_mo_tot_rev_amt
,sum.cur_mo_tot_mou_qty
,sum.cur_mo_voip_recurring_amt
,sum.cur_mo_ia_amt
,sum.cur_mo_ia_recurring_amt
,sum.cur_mo_wireless_mou
,sum.cur_mo_recurring_amt
,sum.cur_mo_hicap_data_spend
,sum.bill_mo
FROM business_revenue_summ PARTITION (&one_months_prior) sum
,business_rev_sum_temp2 dtl2
where sum.blg_acct_id=dtl2.blg_acct_id
UNION
SELECT 
 sum.blg_acct_id
,sum.blg_to_blg_acct_id
,sum.sce_sys_cd
,sum.bill_dt
,sum.cur_mo_dsl_tot_amt
,sum.cur_mo_ld_bndl_amt
,sum.cur_mo_ld_recurring_amt
,sum.cur_mo_ld_tot_amt
,sum.cur_mo_ld_tot_mou_qty
,sum.cur_mo_ld_intralata_amt
,sum.cur_mo_ld_intralata_mou_qty
,sum.cur_mo_ld_interlata_amt
,sum.cur_mo_ld_interlata_mou_qty
,sum.cur_mo_ld_domestic_amt
,sum.cur_mo_ld_domestic_mou_qty
,sum.cur_mo_ld_intl_amt
,sum.cur_mo_ld_intl_mou_qty
,sum.cur_mo_ld_tot_usg_amt
,sum.cur_mo_wireless_bndl_amt
,sum.cur_mo_wireless_recurring_amt
,sum.cur_mo_wireless_tot_amt
,sum.cur_mo_wireline_bndl_amt
,sum.cur_mo_wireline_recurring_amt
,sum.cur_mo_wireline_tot_amt
,sum.cur_mo_video_bndl_amt
,sum.cur_mo_qwest_video_recur_amt
,sum.cur_mo_video_tot_amt
,sum.cur_mo_iptv_amt
,sum.cur_mo_voip_amt
,sum.cur_mo_package_bndl_amt
,sum.cur_mo_package_amt
,sum.cur_mo_tot_bndl_disc_amt
,sum.cur_mo_tot_bndl_amt
,sum.cur_mo_tot_rev_amt
,sum.cur_mo_tot_mou_qty
,sum.cur_mo_voip_recurring_amt
,sum.cur_mo_ia_amt
,sum.cur_mo_ia_recurring_amt
,sum.cur_mo_wireless_mou
,sum.cur_mo_recurring_amt
,sum.cur_mo_hicap_data_spend
,sum.bill_mo
FROM business_revenue_summ PARTITION (&two_months_prior) sum
,business_rev_sum_temp2 dtl2
where sum.blg_acct_id=dtl2.blg_acct_id
;

PROMPT  Table BUSINESS_THREE_MONTHS_REV created
QUIT;

