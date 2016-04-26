-------------------------------------------------------------------------------
-- Program         : dns_crt_dnc_dne_tbl.sql
-- Original Author : kwillet
--
-- Description     :  Create dns_dnc_dne_temp table from  from DNS_RESTRICT and DNS_TN_MSTR
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

create table dns_dnc_dne_temp 
tablespace &1
NOLOGGING
PARALLEL 4
AS
  select distinct
         a.source_cd
        ,a.restrict_cd
        ,b.tn from
  dns_restriction@&2 a
 ,dns_tn_mstr@&2 b
where a.restr_mstr_id = b.tn_mstr_id
  and a.source_cd in ('WEB')
  and a.restrict_cd in ('DNC', 'DNE')  
  and b.tn <> 0;

exec dbms_stats.gather_table_stats ('MKDM','DNS_DNC_DNE_TEMP',estimate_percent => 5,cascade=>true);

EXIT;
