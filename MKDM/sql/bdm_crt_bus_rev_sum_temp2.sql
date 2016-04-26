-------------------------------------------------------------------------------
-- Program         :  bdm_crt_bus_rev_sum_temp2.sql
--
-- Original Author :  sxlank2
--
-- Description     :  Create table BUSINESS_REVENUE_SUMM_TEMP2  with records from 
--                    BUSINESS_REVENUE_SUMM_TEMP and cl_id from CUST_LOCN_ACCT_XERF
--                    
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 04/28/2009 sxlank2  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

PROMPT Dropping BUSINESS_REVENUE_SUMM_TEMP2 table

DROP TABLE business_revenue_summ_temp2;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE business_revenue_summ_temp2
NOLOGGING
TABLESPACE BREV_SUMM_CUR_TS
PARALLEL 5
AS
SELECT 
 BLG_ACCT_ID  
,BLG_TO_BLG_ACCT_ID  
,SCE_SYS_CD  
,CL_ID  
,CUR_MO_DSL_TOT_AMT  
,CUR_MO_HICAP_DATA_SPEND  
,CUR_MO_RECURRING_AMT  
,CUR_MO_LD_TOT_AMT  
,CUR_MO_LD_RECURRING_AMT  
,CUR_MO_LD_BNDL_AMT  
,CUR_MO_LD_TOT_MOU_QTY  
,CUR_MO_LD_INTRALATA_AMT  
,CUR_MO_LD_INTRALATA_MOU_QTY  
,CUR_MO_LD_INTERLATA_AMT  
,CUR_MO_LD_INTERLATA_MOU_QTY  
,CUR_MO_LD_DOMESTIC_AMT  
,CUR_MO_LD_DOMESTIC_MOU_QTY  
,CUR_MO_LD_INTL_AMT  
,CUR_MO_LD_INTL_MOU_QTY  
,CUR_MO_LD_TOT_USG_AMT  
,CUR_MO_WIRELESS_TOT_AMT  
,CUR_MO_WIRELESS_MOU  
,CUR_MO_WIRELESS_RECURRING_AMT  
,CUR_MO_WIRELESS_BNDL_AMT  
,CUR_MO_WIRELINE_TOT_AMT  
,CUR_MO_WIRELINE_RECURRING_AMT  
,CUR_MO_WIRELINE_BNDL_AMT  
,CUR_MO_VIDEO_TOT_AMT  
,CUR_MO_QWEST_VIDEO_RECUR_AMT  
,CUR_MO_VIDEO_BNDL_AMT  
,CUR_MO_IPTV_AMT  
,CUR_MO_IA_AMT  
,CUR_MO_IA_RECURRING_AMT  
,CUR_MO_VOIP_AMT  
,CUR_MO_VOIP_RECURRING_AMT  
,CUR_MO_PACKAGE_AMT  
,CUR_MO_PACKAGE_BNDL_AMT  
,CUR_MO_TOT_BNDL_AMT  
,CUR_MO_TOT_BNDL_DISC_AMT  
,CUR_MO_TOT_REV_AMT  
,CUR_MO_TOT_MOU_QTY  
,AVG3MO_DSL_TOT_AMT  
,AVG3MO_HICAP_DATA_SPEND  
,AVG3MO_RECURRING_AMT  
,AVG3MO_LD_TOT_AMT  
,AVG3MO_LD_RECURRING_AMT  
,AVG3MO_VIDEO_TOT_AMT  
,AVG3MO_VIDEO_RECURRING_AMT  
,AVG3MO_WIRELESS_TOT_AMT  
,AVG3MO_WIRELESS_MOU  
,AVG3MO_WIRELESS_RECURRING_AMT  
,AVG3MO_WIRELINE_TOT_AMT  
,AVG3MO_WIRELINE_RECURRING_AMT  
,AVG3MO_IPTV_AMT  
,AVG3MO_IA_AMT  
,AVG3MO_IA_RECURRING_AMT  
,AVG3MO_VOIP_AMT  
,AVG3MO_VOIP_RECURRING_AMT  
,AVG3MO_PACKAGE_AMT  
,AVG3MO_TOT_BNDL_AMT  
,AVG3MO_TOT_BNDL_DSCNT_AMT  
,AVG3MO_TOT_REV_AMT  
,BILL_MO  
,BILL_DT  
,LOAD_DT  
,ACCT_ESTAB_DT  
,FIRST_BILL_IND  
,CUR_MO_DSL_RECURRING_AMT 
FROM 
(
SELECT /*+ PARALLEL(temp,4) PARALLEL(xref,4) PARALLEL(locn,4) */
temp.*,
xref.cl_id,
ROW_NUMBER() OVER (PARTITION BY temp.blg_acct_id ORDER BY locn.dmnt_cl_indr desc,
locn.LOCN_ESTAB_DAT ASC ) as no_del
FROM 
business_revenue_summ_temp temp,
cust_locn_acct_xref xref,
cust_locn locn
WHERE
temp.blg_acct_id=xref.blg_acct_id(+)
and xref.cl_id = locn.cl_id(+)
) where no_del = 1;


PROMPT  BUSINESS_REVENUE_SUMM_TEMP2 Table Created
