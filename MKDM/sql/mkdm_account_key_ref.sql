-------------------------------------------------------------------------------
-- Program         : mkdm_account_key_ref.sql 
--
-- Original Author : Sanjeev
--
-- Description     : load the account data from stg_account_cris and 
--                   stg_network_cris. 
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
--  06/21/2004  schaudh Initial Checkin
--  08/02/2006  dxkumar  changed script to load unique WTN's
--  10/30/2007  ddamoda  Changed the population of blg_acct_id
--  02/07/2008  dxpanne  Modified thesource from stg_account_cris to CSBAN10V
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

   SET FEEDBACK ON;

   WHENEVER OSERROR EXIT FAILURE
   WHENEVER SQLERROR EXIT FAILURE

   PROMPT Loading account_key_ref table table in MKDM

   SET TRANSACTION USE ROLLBACK SEGMENT &2 ;
 
INSERT /*+ APPEND NOGLOGGING */ INTO account_key_ref
   ( sce_sys_cd,
     blg_acct_id,
     acct_id ,
     acct_seq_no,
     btn ,
     btn_cust_cd,
     btn_st_cd,
     btn_sfx ,
     btn_sort_cd,
     ban ,
     ban_cust_cd ,
     master_customer_id  ,
     stat_cd  ,
     acct_typ ,
     wtn,
     pri_adrs_id,
     secy_adrs_id)
  SELECT 
  	'CRIS' ,
  	blg_acct_id,
  	acct_id ,
	acct_seq_no,
	btn ,
	btn_cust_cd,
	btn_st_cd,
	btn_sfx ,
	btn_sort_cd,
	ban ,
	ban_cust_cd ,
	master_customer_id  ,
	stat_cd  ,
	acct_typ ,
	wtn,
	pri_adrs_id,
  secy_adrs_id from (
	SELECT /*+ PARALLEL(a,5) PARALLEL(b,5) */  DISTINCT
        TRIM(a.btn||a.btn_cust_cd||RPAD(NVL(a.btn_sort_cd, ' '), 1) ||RPAD(NVL(a.btn_sfx, ' '), 4) ||RPAD(NVL(a.btn_st_cd, ' '), 1)) AS blg_acct_id,	
	a.acct_id acct_id,
	a.acct_seq_no acct_seq_no,
	a.btn btn,
	a.btn_cust_cd btn_cust_cd,
	a.btn_st_cd btn_st_cd,
	a.btn_sfx btn_sfx,
	a.btn_sort_cd btn_sort_cd,
	null ban,
	null ban_cust_cd,
	null master_customer_id,
	a.acct_stat_cd stat_cd,
	DECODE(acct_mkt_un_id,'D','B','C','B','L','B','V','B','I','B','S','B','R','B','G','B','F','B','P','B','W','B','O','B','H','C',NULL,'C',NULL ) acct_typ,
	TO_NUMBER( SUBSTR(b.ntwk_acc_id, 1,10)) wtn,
	b.pri_adrs_id pri_adrs_id,
	b.secy_adrs_id secy_adrs_id,
	ROW_NUMBER()
	OVER(PARTITION BY TO_NUMBER( SUBSTR(b.ntwk_acc_id, 1,10))
	ORDER BY        decode(TO_NUMBER( SUBSTR(b.ntwk_acc_id, 1,10)),a.btn, 1, 0) desc,
                        ACCT_ESTAB_DAT desc,
                        a.acct_id desc,
                        a.btn||a.btn_cust_cd desc,
                        b.pri_adrs_id desc
) seq
FROM stg_network_cris b, csban10v@&3 a
WHERE a.acct_id = b.acct_id
AND   a.acct_seq_no = b.acct_seq_no
AND   length(a.btn)=10
AND   b.ntwk_acc_typ  in ('0','1','2','3','4','5','6','7','8','9')
AND   (a.acct_mkt_un_id IN ('D','C','L','V','I','S','R','G','F','P','W','O','H') 
or a.acct_mkt_un_id is null)
AND   a.acct_stat_cd in ('L','S')) where seq=1;

COMMIT;

EXIT;
