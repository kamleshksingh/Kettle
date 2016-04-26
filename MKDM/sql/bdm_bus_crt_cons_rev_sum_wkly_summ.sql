-------------------------------------------------------------------------------
-- Program         :  bdm_bus_crt_cons_rev_sum_wkly_summ.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Create the revenue summary weekly temp table structure
--		      from BUSINESS_REVENUE_SUMM table.Please ensure that
--                    the columns added are exactly in the same order of
--	              BUSINESS_REVENUE_SUMM 	
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 07/10/2007 ddamoda  Changed the column name cur_mo_video_recurring_amt to 
--                     cur_mo_quest_recurring_amt 
-- 07/23/2007 ddamoda  Changed the column name cur_mo_quest_recurring_amt to
--                     cur_mo_qwest_video_recur_amt.      
-- 09/27/2007 ssagili  Added the column cur_mo_dsl_recurring_amt
---------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

DROP TABLE &1;

WHENEVER SQLERROR EXIT FAILURE

PROMPT	Creating &1 table

CREATE TABLE &1
TABLESPACE &2
NOLOGGING
PARALLEL 5
AS
SELECT	/*+ PARALLEL(summ,6) */
 summ.blg_acct_id			
 ,summ.blg_to_blg_acct_id             
 ,summ.sce_sys_cd			
 ,summ.cur_mo_dsl_tot_amt             
 ,summ.cur_mo_hicap_data_spend	
 ,summ.cur_mo_recurring_amt		
 ,summ.cur_mo_ld_tot_amt		
 ,summ.cur_mo_ld_recurring_amt	
 ,summ.cur_mo_ld_bndl_amt		
 ,summ.cur_mo_ld_tot_mou_qty          
 ,summ.cur_mo_ld_intralata_amt	
 ,summ.cur_mo_ld_intralata_mou_qty    
 ,summ.cur_mo_ld_interlata_amt	
 ,summ.cur_mo_ld_interlata_mou_qty    
 ,summ.cur_mo_ld_domestic_amt		
 ,summ.cur_mo_ld_domestic_mou_qty     
 ,summ.cur_mo_ld_intl_amt		
 ,summ.cur_mo_ld_intl_mou_qty         
 ,summ.cur_mo_ld_tot_usg_amt		
 ,summ.cur_mo_wireless_tot_amt        
 ,summ.cur_mo_wireless_mou		
 ,summ.cur_mo_wireless_recurring_amt	
 ,summ.cur_mo_wireless_bndl_amt	
 ,summ.cur_mo_wireline_tot_amt	
 ,summ.cur_mo_wireline_recurring_amt	
 ,summ.cur_mo_wireline_bndl_amt	
 ,summ.cur_mo_video_tot_amt		
 ,summ.cur_mo_qwest_video_recur_amt	
 ,summ.cur_mo_video_bndl_amt		
 ,summ.cur_mo_iptv_amt		
 ,summ.cur_mo_ia_amt			
 ,summ.cur_mo_ia_recurring_amt	
 ,summ.cur_mo_voip_amt		
 ,summ.cur_mo_voip_recurring_amt	
 ,summ.cur_mo_package_amt		
 ,summ.cur_mo_package_bndl_amt	
 ,summ.cur_mo_tot_bndl_amt		
 ,summ.cur_mo_tot_bndl_disc_amt	
 ,summ.cur_mo_tot_rev_amt		
 ,summ.cur_mo_tot_mou_qty             
 ,summ.avg3mo_dsl_tot_amt		
 ,summ.avg3mo_hicap_data_spend	
 ,summ.avg3mo_recurring_amt		
 ,summ.avg3mo_ld_tot_amt		
 ,summ.avg3mo_ld_recurring_amt	
 ,summ.avg3mo_video_tot_amt		
 ,summ.avg3mo_video_recurring_amt	
 ,summ.avg3mo_wireless_tot_amt	
 ,summ.avg3mo_wireless_mou		
 ,summ.avg3mo_wireless_recurring_amt	
 ,summ.avg3mo_wireline_tot_amt	
 ,summ.avg3mo_wireline_recurring_amt	
 ,summ.avg3mo_iptv_amt		
 ,summ.avg3mo_ia_amt			
 ,summ.avg3mo_ia_recurring_amt	
 ,summ.avg3mo_voip_amt		
 ,summ.avg3mo_voip_recurring_amt	
 ,summ.avg3mo_package_amt		
 ,summ.avg3mo_tot_bndl_amt		
 ,summ.avg3mo_tot_bndl_dscnt_amt	
 ,summ.avg3mo_tot_rev_amt		
 ,summ.bill_mo			
 ,summ.bill_dt			
 ,summ.load_dt			
 ,summ.acct_estab_dt			
 ,summ.first_bill_ind	                
 ,summ.cur_mo_dsl_recurring_amt
 FROM    business_revenue_summ summ
 WHERE   2=1;
 Quit;
