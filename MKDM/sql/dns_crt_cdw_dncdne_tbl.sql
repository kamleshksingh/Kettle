-------------------------------------------------------------------------------
-- Program         : dns_crt_cdw_dncdne_tbl.sql
-- Original Author : kwillet
--
-- Description     :  Create dns_cdw_dnc_dne_temp table from  from CPLST10V
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
WHENEVER SQLERROR EXIT FAILURE

create table dns_cdw_dnc_dne_temp 
tablespace &1
NOLOGGING
PARALLEL 4
AS
select c.acct_id
      ,c.acct_seq_no
      ,c.tel_no
      ,c.ocls_ind    OCLS
      ,c.omt_fr_email_ind  OFEM
      ,c.non_pub_ind
from cplst10v@&2 c
where (c.ocls_ind = 'N' and c.non_pub_ind = 'N')
  and c.tel_no <> 0
  and exists (select d.tn from dns_dnc_dne_temp d
              where c.tel_no = d.tn)
group by c.acct_id
        ,c.acct_seq_no
        ,c.tel_no
        ,c.ocls_ind
        ,c.omt_fr_email_ind
        ,c.non_pub_ind  		 
;

exec dbms_stats.gather_table_stats ('MKDM','DNS_CDW_DNC_DNE_TEMP',estimate_percent => 5,cascade=>true); 

EXIT;
