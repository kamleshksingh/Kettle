-------------------------------------------------------------------------------
-- Program         :  bdm_bus_crt_rev_sum_wkly_temp.sql
--
-- Original Author :  mmuruga
--
-- Description     :  Insert the existing records not existing in the current
--                    week pull from corresponding partition of BUSINESS_REVENUE_SUMM
--                    table in BUS_REV_SUM_WKLY_TEMP table.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 08/22/2006 mmuruga  Initial Checkin
-- 05/17/2007 urajend  Finding out the records from current partition not existing
--                     in the current month's data.
-- 07/10/2007 ddamoda  Changed the column name cur_mo_video_recurring_amt to
--                     cur_mo_quest_recurring_amt
-- 07/23/2007 ddamoda  Changed the column name cur_mo_quest_recurring_amt to
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
WHENEVER SQLERROR CONTINUE

PROMPT  Dropping BUS_REV_SUM_WKLY_TEMP table

DROP TABLE BUS_REV_SUM_WKLY_TEMP;

WHENEVER SQLERROR EXIT FAILURE

COLUMN partition_name NEW_VALUE partition_name

SELECT  'P'||substr('&1',LENGTH('&1')-5) partition_name FROM dual;

PROMPT  Creating BUS_REV_SUM_WKLY_TEMP table

CREATE TABLE BUS_REV_SUM_WKLY_TEMP
TABLESPACE &2
NOLOGGING
PARALLEL 4
AS
SELECT  /*+ PARALLEL(sum)
            PARALLEL(dtl)
        */
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
,sum.cur_mo_dsl_recurring_amt
,sum.bill_mo
,sum.load_dt
FROM    BUSINESS_REVENUE_SUMM partition (&partition_name) sum
       ,BUSINESS_REV_SUM_TEMP2 dtl
WHERE   sum.blg_acct_id = dtl.blg_acct_id(+)
AND     dtl.blg_acct_id is null;

PROMPT  Table BUS_REV_SUM_WKLY_TEMP created
QUIT;
