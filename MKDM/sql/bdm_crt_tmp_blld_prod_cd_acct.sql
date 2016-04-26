-------------------------------------------------------------------------------
-- Program         :    bdm_crt_tmp_blld_prod_cd_acct.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create a temporary tmp_blld_prod_cd_acct table 
--                      Which contains the long Distance  Products 
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga Initial Checkin
-- 04/26/2007 lnarasi Changed the conditions to include VDSL and WIRELESS products.
-- 12/09/2011 txmx    Replaced the finedw tables by ccdw_cons_prod_hier,bundle_ref 
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE tmp_blld_prod_cd_acct;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table TMP_BLLD_PROD_CD_ACCT

CREATE TABLE tmp_blld_prod_cd_acct
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT DISTINCT blg_acct_id, b.prod_leaf_cd prod_cd
FROM bus_week_dtl_temp a, ccdw_cons_prod_hier b, bundle_ref c 
WHERE a.prod_cd = b.prod_leaf_cd
AND a.sub_plan_id = c.sub_plan_id 
AND (b.prod_layer_2='LD'
OR  b.prod_layer_5='LEGACY_WRLS'
OR  b.prod_layer_6='VDSL');

PROMPT	TABLE tmp_blld_prod_cd_acct created

QUIT;


