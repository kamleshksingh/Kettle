-------------------------------------------------------------------------------
-- Program         :    bdm_crt_consol_data.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create a table to contain the consolidated current
--                      and 3 Months average revenue.
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/23/2007 rananto  Performance Tuning
-- 05/17/2007 urajend  Added load_dt column.
-- 07/12/2007 ddamoda  Changed the column cur_mo_video_recurring_amt 
--                     to cur_mo_qwest_recurring_amt.
-- 07/23/2007 ddamoda  Changed the column cur_mo_qwest_recurring_amt to 
--                     cur_mo_qwest_video_recur_amt.
-- 09/27/2007 ssagili  Added the column cur_mo_dsl_recurring_amt
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO ON;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE &1;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT  Creating table &1

CREATE  TABLE &1
TABLESPACE &2
NOLOGGING
PARALLEL 4
AS
SELECT  dtl.blg_acct_id
,dtl.blg_to_blg_acct_id
,dtl.blg_sce_sys_cd
,trunc(dtl.jnl_blg_dt) as bill_dt
,sum.avg3mo_dsl_tot_amt
,sum.avg3mo_hicap_data_spend
,sum.avg3mo_recurring_amt
,sum.avg3mo_ld_tot_amt
,sum.avg3mo_ld_rcrg_amt
,sum.avg3mo_qwest_video_recur_amt
,sum.avg3mo_video_tot_amt
,sum.avg3mo_wireless_mou
,sum.avg3mo_wireless_tot_amt
,sum.avg3mo_wireless_rcrg_amt
,sum.avg3mo_wireline_rcrg_amt
,sum.avg3mo_wireline_tot_amt
,sum.avg3mo_voip_amt
,sum.avg3mo_voip_rcrg_amt
,sum.avg3mo_iptv_amt
,sum.avg3mo_ia_amt
,sum.avg3mo_ia_recurring_amt
,sum.avg3mo_package_amt
,sum.avg3mo_tot_rev_amt
,sum.avg3mo_tot_bndl_amt
,sum.avg3mo_tot_bndl_dscnt_amt
,decode(sum.no_of_records,1,'Y','N')as first_bill_ind
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
,dtl.cur_mo_tot_bndl_amt
,dtl.cur_mo_tot_bndl_dscnt_amt
,dtl.cur_mo_tot_rev_amt
,dtl.cur_mo_tot_mou_qty
,dtl.cur_mo_voip_recurring_amt
,dtl.cur_mo_ia_amt
,dtl.cur_mo_ia_recurring_amt
,dtl.cur_mo_wireless_mou
,dtl.cur_mo_recurring_amt
,dtl.cur_mo_hicap_data_spend
,dtl.cur_mo_dsl_recurring_amt
,dtl.bill_mo
,dtl.load_dt
FROM business_rev_sum_temp2 dtl,
bus_rev_avg_temp sum
WHERE dtl.blg_acct_id=sum.blg_acct_id
;

PROMPT  Table &1 created

QUIT;
