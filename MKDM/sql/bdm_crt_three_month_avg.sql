-------------------------------------------------------------------------------
-- Program         :    bdm_crt_three_month_avg.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create a table for 3 Months average revenue
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 07/10/2007 ddamoda  Changed the column name cur_mo_video_recurring_amt to
                       cur_mo_quest_recurring_amt
-- 07/23/2007 ddamoda  Changed the column name cur_mo_quest_recurring_amt to
                       cur_mo_qwest_video_recur_amt. 
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO ON;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE bus_rev_avg_temp;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table BUS_REV_AVG_TEMP 

CREATE	TABLE bus_rev_avg_temp
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT
     blg_acct_id
,count(*) as no_of_records
,round(avg(cur_mo_dsl_tot_amt),2) as avg3mo_dsl_tot_amt
,round(avg(cur_mo_hicap_data_spend),2) as avg3mo_hicap_data_spend
,round(avg(cur_mo_recurring_amt),2) as avg3mo_recurring_amt
,round(avg(cur_mo_ld_tot_amt),2)       as avg3mo_ld_tot_amt
,round(avg(cur_mo_ld_rcrg_amt),2) as avg3mo_ld_rcrg_amt
,round(avg(cur_mo_qwest_video_recur_amt),2)as avg3mo_qwest_video_recur_amt
,round(avg(cur_mo_video_tot_amt),2) as avg3mo_video_tot_amt
,round(avg(cur_mo_iptv_amt),2) as avg3mo_iptv_amt
,round(avg(cur_mo_wireless_mou),2) as avg3mo_wireless_mou
,round(avg(cur_mo_wireless_tot_amt),2) as avg3mo_wireless_tot_amt
,round(avg(cur_mo_wireless_rcrg_amt),2) as avg3mo_wireless_rcrg_amt
,round(avg(cur_mo_wireline_rcrg_amt),2) as avg3mo_wireline_rcrg_amt
,round(avg(cur_mo_wireline_tot_amt),2) as avg3mo_wireline_tot_amt
,round(avg(cur_mo_voip_amt),2) as avg3mo_voip_amt
,round(avg(cur_mo_voip_recurring_amt),2) as avg3mo_voip_rcrg_amt
,round(avg(cur_mo_package_tot_amt),2) as avg3mo_package_amt
,round(avg(cur_mo_tot_rev_amt),2) as avg3mo_tot_rev_amt
,round(avg(cur_mo_tot_bndl_amt),2) as avg3mo_tot_bndl_amt
,round(avg(cur_mo_tot_bndl_dscnt_amt),2) as avg3mo_tot_bndl_dscnt_amt
,round(avg(cur_mo_ia_amt),2) as avg3mo_ia_amt
,round(avg(cur_mo_ia_recurring_amt),2) as avg3mo_ia_recurring_amt
FROM 
  business_three_months_rev 
GROUP BY 
blg_acct_id,blg_sce_sys_cd;

PROMPT	Table BUS_REV_AVG_TEMP created

QUIT;
