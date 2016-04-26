-------------------------------------------------------------------------------
-- Program         :    bdm_crt_tmp_blld_usoc_acct.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create a temporary tmp_blld_usoc_acct table 
--                      Which contains the Products other than long Distance 
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 07/13/2006 mmuruga Initial Checkin
-- 04/26/2007 lnarasi Changed where condition to exclude VDSL and WIRELESS products.
-- 12/09/2011 txmx    Replaced the finedw tables by ccdw_cons_prod_hier,bundle_ref
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

DROP TABLE tmp_blld_usoc_acct;

WHENEVER SQLERROR EXIT FAILURE;

PROMPT	Creating table TMP_BLLD_USOC_ACCT

CREATE TABLE tmp_blld_usoc_acct
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
SELECT DISTINCT blg_acct_id, lec_usoc FROM
bus_week_dtl_temp a, ccdw_cons_prod_hier b, bundle_ref c
WHERE a.prod_cd = b.prod_leaf_cd
AND a.sub_plan_id = c.sub_plan_id
AND b.prod_layer_2 <> 'LD'
AND b.prod_layer_5 <> 'LEGACY_WRLS'
AND b.prod_layer_6 <> 'VDSL';


PROMPT	Table TMP_BLLD_USOC_ACCT created

QUIT;


