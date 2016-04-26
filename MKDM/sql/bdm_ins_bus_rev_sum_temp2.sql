-------------------------------------------------------------------------------
-- Program         :  bdm_ins_bus_rev_sum_temp2.sql
--
-- Original Author :  urajend
--
-- Description     :  Insert the existing records not existing in the current
--                    week pull from corresponding partition of BUSINESS_REVENUE_SUMM
--                    table in BUSINESS_REV_SUM_TEMP2 table.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 05/17/2007 urajend  Initial Checkin.
-- 07/12/2007 ddamoda  Changed the column cur_mo_video_recurring_amt 
--                     to cur_mo_qwest_recurring_amt. 
-- 07/23/2007 ddamoda  Changed the column cur_mo_qwest_recurring_amt to 
--                     cur_mo_qwest_video_recur_amt.
-- 09/27/2007 ssagili  Added the column cur_mo_dsl_recurring_amt
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

INSERT INTO BUSINESS_REV_SUM_TEMP2
(blg_acct_id
,blg_to_blg_acct_id
,blg_sce_sys_cd
,jnl_blg_dt
,cur_mo_dsl_tot_amt
,cur_mo_ld_bndl_amt
,cur_mo_ld_rcrg_amt
,cur_mo_ld_tot_amt
,cur_mo_ld_tot_mou_qty
,cur_mo_ld_intralata_amt
,cur_mo_ld_intralata_mou_qty
,cur_mo_ld_interlata_amt
,cur_mo_ld_interlata_mou_qty
,cur_mo_ld_domestic_amt
,cur_mo_ld_domestic_mou_qty
,cur_mo_ld_intl_amt
,cur_mo_ld_intl_mou_qty
,cur_mo_ld_tot_usg_amt
,cur_mo_wireless_bndl_amt
,cur_mo_wireless_rcrg_amt
,cur_mo_wireless_tot_amt
,cur_mo_wireline_bndl_amt
,cur_mo_wireline_rcrg_amt
,cur_mo_wireline_tot_amt
,cur_mo_video_bndl_amt
,cur_mo_qwest_video_recur_amt
,cur_mo_video_tot_amt
,cur_mo_iptv_amt
,cur_mo_voip_amt
,cur_mo_package_bndl_amt
,cur_mo_package_tot_amt
,cur_mo_tot_bndl_dscnt_amt
,cur_mo_tot_bndl_amt
,cur_mo_tot_rev_amt
,cur_mo_tot_mou_qty
,cur_mo_voip_recurring_amt
,cur_mo_ia_amt
,cur_mo_ia_recurring_amt
,cur_mo_wireless_mou
,cur_mo_recurring_amt
,cur_mo_hicap_data_spend
,cur_mo_dsl_recurring_amt
,bill_mo
,load_dt
)
SELECT /*+ PARALLEL(sum,4) */
 sum.blg_acct_id
,sum.blg_to_blg_acct_id
,sum.sce_sys_cd
,trunc(sum.bill_dt)
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
,sum.cur_mo_dsl_recurring_amt
,sum.bill_mo
,sum.load_dt
FROM  BUS_REV_SUM_WKLY_TEMP sum;


COMMIT;

QUIT;
