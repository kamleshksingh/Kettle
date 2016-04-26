-------------------------------------------------------------------------------
-- Program         :  bdm_bus_insert_cons_rev_sum_wkly_temp.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Insert the current week records from revenue summary temp
--                    table in MKDM to corresponding revenue summary temp table
--                    in BDM.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/23/2007 rananto  Performance Tuning
-- 05/17/2007 urajend  Getting the load_dt from the monthly details table.
-- 07/12/2007 ddamoda  Changed the column video_recurring_amt to quest_recurring_amt 
-- 07/23/2007 ddamoda  Changed the column name qwest_recurring_amt to qwest_video_recur_amt 
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

ALTER SESSION ENABLE PARALLEL DML;

PROMPT  Inserting records into &1 table

INSERT /*+ APPEND */ INTO &1
NOLOGGING
(
blg_acct_id
,blg_to_blg_acct_id
,sce_sys_cd
,cur_mo_dsl_tot_amt
,cur_mo_ld_bndl_amt
,cur_mo_ld_recurring_amt
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
,cur_mo_wireless_recurring_amt
,cur_mo_wireless_tot_amt
,cur_mo_wireline_bndl_amt
,cur_mo_wireline_recurring_amt
,cur_mo_wireline_tot_amt
,cur_mo_video_bndl_amt
,cur_mo_qwest_video_recur_amt
,cur_mo_video_tot_amt
,cur_mo_iptv_amt
,cur_mo_voip_amt
,cur_mo_package_bndl_amt
,cur_mo_package_amt
,cur_mo_tot_bndl_amt
,cur_mo_tot_bndl_disc_amt
,cur_mo_tot_rev_amt
,cur_mo_tot_mou_qty
,cur_mo_voip_recurring_amt
,cur_mo_ia_amt
,cur_mo_ia_recurring_amt
,cur_mo_wireless_mou
,cur_mo_recurring_amt
,cur_mo_hicap_data_spend
,cur_mo_dsl_recurring_amt
,avg3mo_dsl_tot_amt
,avg3mo_ld_tot_amt
,avg3mo_ld_recurring_amt
,avg3mo_video_tot_amt
,avg3mo_video_recurring_amt
,avg3mo_iptv_amt
,avg3mo_voip_amt
,avg3mo_wireless_tot_amt
,avg3mo_wireless_mou
,avg3mo_wireless_recurring_amt
,avg3mo_wireline_tot_amt
,avg3mo_wireline_recurring_amt
,avg3mo_package_amt
,avg3mo_tot_bndl_amt
,avg3mo_tot_bndl_dscnt_amt
,avg3mo_tot_rev_amt
,avg3mo_hicap_data_spend
,avg3mo_recurring_amt
,avg3mo_voip_recurring_amt
,avg3mo_ia_amt
,avg3mo_ia_recurring_amt
,bill_mo
,bill_dt
,load_dt
,acct_estab_dt
,first_bill_ind
)
SELECT  /*+ DRIVING_SITE(temp) PARALLEL(temp,4) PARALLEL(cs,4) */
 temp.blg_acct_id
,temp.blg_to_blg_acct_id
,temp.blg_sce_sys_cd
,temp.cur_mo_dsl_tot_amt
,temp.cur_mo_ld_bndl_amt
,temp.cur_mo_ld_rcrg_amt
,temp.cur_mo_ld_tot_amt
,temp.cur_mo_ld_tot_mou_qty
,temp.cur_mo_ld_intralata_amt
,temp.cur_mo_ld_intralata_mou_qty
,temp.cur_mo_ld_interlata_amt
,temp.cur_mo_ld_interlata_mou_qty
,temp.cur_mo_ld_domestic_amt
,temp.cur_mo_ld_domestic_mou_qty
,temp.cur_mo_ld_intl_amt
,temp.cur_mo_ld_intl_mou_qty
,temp.cur_mo_ld_tot_usg_amt
,temp.cur_mo_wireless_bndl_amt
,temp.cur_mo_wireless_rcrg_amt
,temp.cur_mo_wireless_tot_amt
,temp.cur_mo_wireline_bndl_amt
,temp.cur_mo_wireline_rcrg_amt
,temp.cur_mo_wireline_tot_amt
,temp.cur_mo_video_bndl_amt
,temp.cur_mo_qwest_video_recur_amt
,temp.cur_mo_video_tot_amt
,temp.cur_mo_iptv_amt
,temp.cur_mo_voip_amt
,temp.cur_mo_package_bndl_amt
,temp.cur_mo_package_tot_amt
,temp.cur_mo_tot_bndl_amt
,temp.cur_mo_tot_bndl_dscnt_amt
,temp.cur_mo_tot_rev_amt
,temp.cur_mo_tot_mou_qty
,temp.cur_mo_voip_recurring_amt
,temp.cur_mo_ia_amt
,temp.cur_mo_ia_recurring_amt
,temp.cur_mo_wireless_mou
,temp.cur_mo_recurring_amt
,temp.cur_mo_hicap_data_spend
,temp.cur_mo_dsl_recurring_amt
,temp.avg3mo_dsl_tot_amt
,temp.avg3mo_ld_tot_amt
,temp.avg3mo_ld_rcrg_amt
,temp.avg3mo_video_tot_amt
,temp.avg3mo_qwest_video_recur_amt
,temp.avg3mo_iptv_amt
,temp.avg3mo_voip_amt
,temp.avg3mo_wireless_tot_amt
,temp.avg3mo_wireless_mou
,temp.avg3mo_wireless_rcrg_amt
,temp.avg3mo_wireline_tot_amt
,temp.avg3mo_wireline_rcrg_amt
,temp.avg3mo_package_amt
,temp.avg3mo_tot_bndl_amt
,temp.avg3mo_tot_bndl_dscnt_amt
,temp.avg3mo_tot_rev_amt
,temp.avg3mo_hicap_data_spend
,temp.avg3mo_recurring_amt
,temp.avg3mo_voip_rcrg_amt
,temp.avg3mo_ia_amt
,temp.avg3mo_ia_recurring_amt
,temp.bill_mo
,temp.bill_dt
,temp.load_dt
,NVL(cur.acct_estab_dat,to_date('01-JAN-1900','fmDD-MON-YYYY'))
,temp.first_bill_ind
FROM    &2 temp,
        blg_csban_btn_tmp cur
WHERE   temp.blg_acct_id=cur.blg_acct_id(+);

COMMIT;

ALTER SESSION DISABLE PARALLEL DML;

QUIT;
