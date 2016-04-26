-------------------------------------------------------------------------------
-- Program         :   email_campaign_cur_optout_temp.sql
--
-- Original Author :   bzachar
--
-- Description     :   Creating the temp table with latest email_campaign_cur records
--
-- Revision History:   Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 02/24/2008 bzachar  Initial checkin.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET TIME ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR CONTINUE

DROP TABLE email_campaign_cur_optout_temp;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE email_campaign_cur_optout_temp
TABLESPACE &1 
NOLOGGING
PARALLEL 6
AS 
SELECT  /*+ DRIVING_SITE(a) */ 
email_addr_id,source_cd,opt_out_flag,acct_type,univ_acct_id 
FROM email_campaign_cur where trunc(load_date)=trunc(sysdate);

QUIT;
