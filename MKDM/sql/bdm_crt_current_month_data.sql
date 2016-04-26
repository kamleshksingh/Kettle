-------------------------------------------------------------------------------
-- Program              :       bdm_crt_current_month_data.sql
--
-- Original Author      :       mmuruga
--
-- Description          :       This script calculates the current week's revenue
--                              from cur_week_dtl_temp,ccdw_cons_prod_hier and 
--                              bundle_ref
-- Revision History     :       Please do not stray from the example provided.
--
-- ModfiedUser
-- Date   ID   Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 04/26/2007 lnarasi  Changed conditions to populate CUR_MO_VIDEO_BNDL_AMT 
--                     and CUR_MO_WIRELESS_BNDL_AMT.
-- 07/12/2007 ddamoda  Changed the column cur_mo_video_recurring_amt to
--                     cur_mo_qwest_recurring_amt. 
-- 07/23/2007 ddamoda  Changed then column cur_mo_qwest_recurring_amt to 
--                     cur_mo_qwest_video_recur_amt.
-- 09/27/2007 ssagili  Added the column cur_mo_dsl_recurring_amt
-- 12/09/201  txmx     Replaced the finedw tables by ccdw_cons_prod_hier,bundle_ref
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO ON;
SET AUTOTRACE ON;
SET FEEDBACK ON;

alter session set "_COMPLEX_VIEW_MERGING"=false;
alter session set "_unnest_subquery" = false;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

drop TABLE business_rev_sum_temp1_&3;

WHENEVER SQLERROR EXIT FAILURE;

COLUMN min_acct NEW_VALUE min_acct;
COLUMN max_acct NEW_VALUE max_acct;

select trim(begin_acct_id) min_acct from bdm_hjobs_histogram_pool where job_id = &3; 
select trim(end_acct_id) max_acct from bdm_hjobs_histogram_pool where job_id = &3;

CREATE TABLE business_rev_sum_temp1_&3
       TABLESPACE  &1
       NOLOGGING
       PARALLEL 4
       AS
       SELECT /*+ parallel(cdt,8) */
cdt.blg_acct_id,
max(cdt.blg_to_blg_acct_id) as blg_to_blg_acct_id,
cdt.blg_sce_sys_cd,
max(cdt.bill_mo) as bill_mo,
max(cdt.jnl_blg_dt) as jnl_blg_dt,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='HIGH_SPEED_INTERNET') 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_DSL_TOT_AMT,
SUM(CASE WHEN (cpd.PROD_LEAF_CD ='V0004') 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_IPTV_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.SUB_PLAN_ID IS NULL 
     AND c.BLG_ACCT_ID IS NOT NULL AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
     THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_BNDL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' 
    AND cdt.USAGE_TYP_CD!='I' AND (cdt.NLEC_INTRA_LATA_IND!='Y' OR cdt.INTER_INTRA_IND!='5')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_INTERLATA_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.USAGE_TYP_CD!='I' 
    AND (cdt.NLEC_INTRA_LATA_IND!='Y'  or cdt.INTER_INTRA_IND!='5' )  ) 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_LD_INTERLATA_MOU_QTY,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' and cdt.NLEC_USAGE_TYPE_CD='I')
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_INTL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.NLEC_USAGE_TYPE_CD='I') 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_LD_INTL_MOU_QTY,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.USAGE_TYP_CD!='I' 
    AND (cdt.NLEC_INTRA_LATA_IND='Y'  or cdt.INTER_INTRA_IND='5' )  ) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_INTRALATA_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.USAGE_TYP_CD!='I'  
    AND (cdt.NLEC_INTRA_LATA_IND='Y'  or cdt.INTER_INTRA_IND='5' )  ) 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_LD_INTRALATA_MOU_QTY,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_RCRG_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD') THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_TOT_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.USAGE_TYP_CD!='I') 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_DOMESTIC_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG' AND cdt.USAGE_TYP_CD!='I') 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_LD_DOMESTIC_MOU_QTY,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG') 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_LD_TOT_MOU_QTY,
SUM(CASE WHEN (cpd.PROD_LAYER_2 ='LD' AND cdt.REV_TYP_CD='USG') 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_LD_TOT_USG_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_4 ='PACKAGES' AND cdt.SUB_PLAN_ID IS NULL AND 
    d.BLG_ACCT_ID IS NOT NULL AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_PACKAGE_BNDL_AMT,
SUM(cdt.REV_AMT  ) CUR_MO_TOT_REV_AMT,
sum(CASE WHEN ((cpd.PROD_LAYER_6 ='VDSL' OR cpd.PROD_LAYER_6 like 'DIRECTV_%') 
    AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_QWEST_VIDEO_RECUR_AMT,
SUM(CASE WHEN ((cpd.PROD_LAYER_6 ='VDSL' OR cpd.PROD_LAYER_6 like 'DIRECTV_%' OR  cdt.REV_TYP_CD='RIBD'))
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_VIDEO_TOT_AMT,
SUM(CASE WHEN ( ((cpd.PROD_LAYER_6 ='VDSL' AND c.BLG_ACCT_ID IS NOT NULL)
    OR (cpd.PROD_LAYER_6 like 'DIRECTV_%' AND d.BLG_ACCT_ID IS NOT NULL)) 
    AND b.SUB_PLAN_ID IS NULL 
    AND  (cdt.REV_TYP_CD='RECF'  or cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_VIDEO_BNDL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='VOIP') THEN cdt.rev_amt ELSE 0 END) CUR_MO_VOIP_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_5='LEGACY_WRLS' AND cdt.SUB_PLAN_ID IS NULL  
    AND c.BLG_ACCT_ID IS NOT NULL  AND (cdt.REV_TYP_CD='RECF'  or cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELESS_BNDL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_5='LEGACY_WRLS' AND (cdt.REV_TYP_CD='RECN' OR cdt.REV_TYP_CD='RECF')) THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELESS_RCRG_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_5='LEGACY_WRLS') THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELESS_TOT_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='LOCAL' AND cdt.SUB_PLAN_ID IS NULL  
    AND d.BLG_ACCT_ID IS NOT NULL AND (cdt.REV_TYP_CD='RECF'  or cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELINE_BNDL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='LOCAL' AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELINE_RCRG_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='LOCAL') THEN cdt.rev_amt ELSE 0 END) CUR_MO_WIRELINE_TOT_AMT,
SUM(CASE WHEN (cdt.REV_TYP_CD='USG') THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_TOT_MOU_QTY,
SUM(CASE WHEN (b.SUB_PLAN_ID IS NULL AND (c.BLG_ACCT_ID IS NOT NULL  or d.BLG_ACCT_ID IS NOT NULL) AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_TOT_BNDL_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_4 ='PACKAGES') THEN cdt.rev_amt ELSE 0 END) CUR_MO_PACKAGE_TOT_AMT,
SUM(CASE WHEN (cdt.SUB_PLAN_ID is not null) THEN cdt.rev_amt ELSE 0 END) CUR_MO_TOT_BNDL_DSCNT_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='VOIP' AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) THEN cdt.rev_amt ELSE 0 END) CUR_MO_VOIP_RECURRING_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_5='INTEGRATED_ACCESS') THEN cdt.rev_amt ELSE 0 END) CUR_MO_IA_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='LEGACY_WAN' OR cpd.PROD_LAYER_2='IP_SERVICES_MPLS' 
	      OR cpd.PROD_LAYER_3='DIAL'  
              OR cpd.PROD_LAYER_2='HOSTING'  
	      OR cpd.PROD_LAYER_5='NETB' OR cpd.PROD_LAYER_2 ='PRIV_LINE_SPEC_ACC'  
	      OR cpd.PROD_LAYER_2='ETHERNET_DWDM_WAVE')
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_HICAP_DATA_SPEND,
SUM(CASE WHEN (cpd.PROD_LAYER_5='LEGACY_WRLS' AND cdt.REV_TYP_CD='USG') 
    THEN cdt.minutes_of_use ELSE 0 END) CUR_MO_WIRELESS_MOU,
SUM(CASE WHEN ((cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN' )) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_RECURRING_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_5='INTEGRATED_ACCESS 'AND (cdt.REV_TYP_CD='RECF' or cdt.REV_TYP_CD='RECN')) THEN cdt.rev_amt ELSE 0 END) CUR_MO_IA_RECURRING_AMT,
SUM(CASE WHEN (cpd.PROD_LAYER_2='HIGH_SPEED_INTERNET' AND (cdt.REV_TYP_CD='RECF' OR cdt.REV_TYP_CD='RECN')) 
    THEN cdt.rev_amt ELSE 0 END) CUR_MO_DSL_RECURRING_AMT
FROM bus_week_dtl_temp cdt,
ccdw_cons_prod_hier cpd,
bundle_ref b,
tmp_blld_prod_cd_acct c,
tmp_blld_usoc_acct d
WHERE cdt.prod_cd = cpd.prod_leaf_cd(+)
AND  cdt.sub_plan_id = b.sub_plan_id (+)
AND  cdt.blg_acct_id = c.blg_acct_id (+)
AND  cdt.prod_cd = c.prod_cd (+)
AND  cdt.blg_acct_id = d.blg_acct_id (+)
AND  cdt.lec_usoc = d.lec_usoc (+)
AND  TO_CHAR(cdt.JNL_BLG_DT,'YYYYMM') ='&2'
AND  cdt.blg_acct_id >= '&min_acct' AND cdt.blg_acct_id < '&max_acct'
GROUP BY cdt.blg_acct_id ,cdt.blg_sce_sys_cd ;

QUIT;
