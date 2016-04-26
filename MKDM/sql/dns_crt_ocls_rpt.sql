-------------------------------------------------------------------------------
-- Program         : dns_crt_ocls_rpt.sql
-- Original Author : kwillet
--
-- Description     : Spool the report to stagedir by joining dns_cdw_dnc_dne_temp 
--         i         to CSBAN10V table on cdw to get bill number and bill name
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User     
-- Date       ID       Description
-- MM/DD/YYYY CUID         
-- ---------- -------- ------------------------------------------------
-- 10/02/2006 kwillet  Initial Checkin 
-- 09/01/2013 kxsing3 remove the DB link hardcode value
-------------------------------------------------------------------------------

                                        
-- Start Date & Time
select sysdate as run_date 
from dual
/

set verify off;
set newpage 0;
set space 0;
set linesize 200;
set term off;
set pagesize 0;
set echo off;
set feedback off;
set heading off;

WHENEVER SQLERROR EXIT FAILURE;
WHENEVER OSERROR EXIT FAILURE;

COLUMN btn              FORMAT A10
COLUMN btn_cust_cd      FORMAT A03
COLUMN blg_nm_ln1       FORMAT A32 
COLUMN ind              FORMAT a03

COLUMN file_name NEW_VALUE f_nm

select '$STAGEDIR/DNCL' || to_char(sysdate ,'mmdd') || '1.dns' as file_name from dual;

select to_char(sysdate ,'mmdd') as f_dt from dual;

-- SPOOL &f_nm

SPOOL &1
				  
select a.btn
      ,substr(a.blg_nm_ln1,1,32) blg_nm_ln1
      ,decode(b.restrict_cd,'OCLS','002','OFEM','004','999') ind
      ,a.btn_cust_cd
from csban10v@&2 a
    ,ocls_ofem_accts b
where  a.acct_id = b.acct_id
  and  a.acct_seq_no = b.acct_seq_no
  and  b.restrict_cd in ('OCLS','OFEM')
group by a.btn
        ,a.blg_nm_ln1
        ,decode(b.restrict_cd,'OCLS','002','OFEM','004','999')
        ,a.btn_cust_cd
order by a.btn
;

spool off;

EXIT;
