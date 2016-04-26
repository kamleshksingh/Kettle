-------------------------------------------------------------------------------
-- Program         : dns_crt_oclsofem_accts.sql
-- Original Author : kwillet
--
-- Description     : Create two temp tables OFEM_ACCTS and OCLS_ACCTS
--                   This will have accts and seqq no's with restriction 
--                   code that will be joined to CDW CSBAN10V. 
--         
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User     
-- Date       ID       Description
-- MM/DD/YYYY CUID         
-- ---------- -------- ------------------------------------------------
-- 10/02/2006 kwillet  Initial Checkin 
-------------------------------------------------------------------------------

                                        
-- Start Date & Time
select sysdate as run_date 
from dual
/
SET ECHO OFF;
SET TIMING ON;

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

PROMPT Creating the OCLS_OFEM_ACCTS table

CREATE table ocls_ofem_accts 
TABLESPACE &1
NOLOGGING
PARALLEL 4
AS
select distinct
       b.acct_id
      ,b.acct_seq_no
      ,'OCLS' restrict_cd
 from dns_cdw_dnc_dne_temp b
     ,dns_dnc_dne_temp c
where  b.TEL_NO = c.tn
and c.restrict_cd = 'DNC'
;

PROMPT Inserting the OFEM ACCTS nto ocls_ofem_accts table 
PROMPT *************************************************

insert into ocls_ofem_accts
select distinct
       a.acct_id
      ,a.acct_seq_no
      ,'OFEM' restrict_cd
 from dns_cdw_dnc_dne_temp a
     ,dns_dnc_dne_temp b
where  a.tel_no = b.tn
  and b.restrict_cd = 'DNE'
  and not exists (select 1 from ocls_ofem_accts c
                where a.acct_id = c.acct_id
                  and a.acct_seq_no = c.acct_seq_no) 
;

EXIT;
