-------------------------------------------------------------------------------
-- Program 		:	bdm_crt_cur_months_data.sql
--
-- Original Author 	:	mmuruga
--
-- Description 		:	Create table business_rev_sum_temp2 by adding current
--  			 	month data from business_rev_sum_temp1 with previous week's 
--			 	revenue of current month from business_REV_SUM table
-- Revision History	:	Please do not stray from the example provided.
--
-- ModfiedUser
-- Date   ID   Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/23/2007 rananto  Performance Tuning
-- 05/17/2007 urajend  Added load_dt column.
-- 07/10/2007 ddamoda  Changed the column name cur_mo_video_recurring_amt to
--                     cur_mo_quest_recurring_amt
-- 07/23/2007 ddamoda  Changed the column name  cur_mo_quest_recurring_amt to
--                     cur_mo_qwest_video_recur_amt.           
-- 09/27/2007 ssagili  Added the column cur_mo_dsl_recurring_amt
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE business_rev_sum_temp2;

WHENEVER SQLERROR EXIT FAILURE;


PROMPT Creating table business_REV_SUM_TEMP2

CREATE TABLE business_rev_sum_temp2
TABLESPACE &2
NOLOGGING
PARALLEL 4
AS
SELECT 
  dtl.blg_acct_id
 ,dtl.blg_to_blg_acct_id
 ,dtl.blg_sce_sys_cd
 ,dtl.jnl_blg_dt
 ,dtl.cur_mo_dsl_tot_amt+ NVL(sum.cur_mo_dsl_tot_amt ,0)  as cur_mo_dsl_tot_amt
 ,dtl.cur_mo_ld_bndl_amt+ NVL(sum.cur_mo_ld_bndl_amt ,0)  as cur_mo_ld_bndl_amt
 ,dtl.cur_mo_ld_rcrg_amt+ NVL(sum.cur_mo_ld_recurring_amt,0)  as cur_mo_ld_rcrg_amt
 ,dtl.cur_mo_ld_tot_amt+ NVL(sum.cur_mo_ld_tot_amt ,0)  as cur_mo_ld_tot_amt
 ,dtl.cur_mo_ld_tot_mou_qty+ NVL(sum.cur_mo_ld_tot_mou_qty ,0)  as cur_mo_ld_tot_mou_qty
 ,dtl.cur_mo_ld_intralata_amt+ NVL(sum.cur_mo_ld_intralata_amt ,0) as  cur_mo_ld_intralata_amt
 ,dtl.cur_mo_ld_intralata_mou_qty+ NVL(sum.cur_mo_ld_intralata_mou_qty,0)  as cur_mo_ld_intralata_mou_qty
,dtl.cur_mo_ld_interlata_amt+ NVL(sum.cur_mo_ld_interlata_amt ,0) as  cur_mo_ld_interlata_amt
,dtl.cur_mo_ld_interlata_mou_qty+ NVL(sum.cur_mo_ld_interlata_mou_qty,0) as  cur_mo_ld_interlata_mou_qty
,dtl.cur_mo_ld_domestic_amt+ NVL(sum.cur_mo_ld_domestic_amt ,0) as  cur_mo_ld_domestic_amt
,dtl.cur_mo_ld_domestic_mou_qty+ NVL(sum.cur_mo_ld_domestic_mou_qty ,0) as  cur_mo_ld_domestic_mou_qty
,dtl.cur_mo_ld_intl_amt+ NVL(sum.cur_mo_ld_intl_amt ,0) as  cur_mo_ld_intl_amt
,dtl.cur_mo_ld_intl_mou_qty+ NVL(sum.cur_mo_ld_intl_mou_qty ,0) as  cur_mo_ld_intl_mou_qty
,dtl.cur_mo_ld_tot_usg_amt+ NVL(sum.cur_mo_ld_tot_usg_amt ,0) as   cur_mo_ld_tot_usg_amt
,dtl.cur_mo_wireless_bndl_amt+ NVL(sum.cur_mo_wireless_bndl_amt ,0) as   cur_mo_wireless_bndl_amt
,dtl.cur_mo_wireless_rcrg_amt+ NVL(sum.cur_mo_wireless_recurring_amt,0)as   cur_mo_wireless_rcrg_amt
,dtl.cur_mo_wireless_tot_amt+ NVL(sum.cur_mo_wireless_tot_amt ,0)as   cur_mo_wireless_tot_amt
,dtl.cur_mo_wireline_bndl_amt+ NVL(sum.cur_mo_wireline_bndl_amt ,0)as  cur_mo_wireline_bndl_amt
,dtl.cur_mo_wireline_rcrg_amt+ NVL(sum.cur_mo_wireline_recurring_amt,0)as   cur_mo_wireline_rcrg_amt
,dtl.cur_mo_wireline_tot_amt+ NVL(sum.cur_mo_wireline_tot_amt ,0)as  cur_mo_wireline_tot_amt
,dtl.cur_mo_video_bndl_amt+ NVL(sum.cur_mo_video_bndl_amt ,0)as   cur_mo_video_bndl_amt
,dtl.cur_mo_qwest_video_recur_amt+ NVL(sum.cur_mo_qwest_video_recur_amt,0)as  cur_mo_qwest_video_recur_amt 
,dtl.cur_mo_video_tot_amt+ NVL(sum.cur_mo_video_tot_amt ,0)as   cur_mo_video_tot_amt
,dtl.cur_mo_iptv_amt+ NVL(sum.cur_mo_iptv_amt ,0)as   cur_mo_iptv_amt
,dtl.cur_mo_voip_amt+ NVL(sum.cur_mo_voip_amt ,0) as  cur_mo_voip_amt
,dtl.cur_mo_package_bndl_amt+ NVL(sum.cur_mo_package_bndl_amt ,0)as  cur_mo_package_bndl_amt
,dtl.cur_mo_package_tot_amt+ NVL(sum.cur_mo_package_amt ,0) as  cur_mo_package_tot_amt
,dtl.cur_mo_tot_bndl_dscnt_amt + NVL(sum.cur_mo_tot_bndl_disc_amt,0) as  cur_mo_tot_bndl_dscnt_amt
,dtl.cur_mo_tot_bndl_amt+ NVL(sum.cur_mo_tot_bndl_amt ,0) as   cur_mo_tot_bndl_amt
,dtl.cur_mo_tot_rev_amt+ NVL(sum.cur_mo_tot_rev_amt ,0) as  cur_mo_tot_rev_amt
,dtl.cur_mo_tot_mou_qty+ NVL(sum.cur_mo_tot_mou_qty,0) as  cur_mo_tot_mou_qty
,dtl.cur_mo_voip_recurring_amt+NVL(sum.cur_mo_voip_recurring_amt,0) as cur_mo_voip_recurring_amt
,dtl.cur_mo_ia_amt+NVL(sum.cur_mo_ia_amt,0) as cur_mo_ia_amt
,dtl.cur_mo_ia_recurring_amt+NVL(sum.cur_mo_ia_recurring_amt,0) as cur_mo_ia_recurring_amt
,dtl.cur_mo_wireless_mou+NVL(sum.cur_mo_wireless_mou,0) as cur_mo_wireless_mou
,dtl.cur_mo_hicap_data_spend+NVL(sum.cur_mo_hicap_data_spend,0) as cur_mo_hicap_data_spend
,dtl.cur_mo_recurring_amt+NVL(sum.cur_mo_recurring_amt,0) as cur_mo_recurring_amt
,dtl.cur_mo_dsl_recurring_amt+NVL(sum.cur_mo_dsl_recurring_amt,0) as cur_mo_dsl_recurring_amt
,dtl.bill_mo
,trunc(sysdate) as load_dt
FROM business_rev_sum_temp1@&3 dtl,
     business_revenue_summ PARTITION (&1) sum
WHERE dtl.blg_acct_id=sum.blg_acct_id(+);

PROMPT  Table business_rev_sum_temp2 created

QUIT;


