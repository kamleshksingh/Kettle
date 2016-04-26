-------------------------------------------------------------------------------
-- Program         : dns_tndmp_rsor.sql
-- Original Author : kwillet
--
-- Description     : Create RSORTN.dat file from DO_NOT_SOLICIT
--		     
--
-- Revision History: Please do not stray from the example provided.
--
-- Modfied    User     
-- Date       ID      Description
-- MM/DD/YYYY CUID         
-- ---------- -------- ------------------------------------------------
-- 02/02/2006 kwillet  Initial Checkin 
-- 10/05/2007 jananma  Changed the DB_LINK as part of DNS Rehost
-------------------------------------------------------------------------------
set serveroutput on
set trims on
set pages 0
set term off
set heading off
set feedback off
set linesize 10
set trimspool off
set verify off


PROMPT DECLARING RUN_DATE
COLUMN  run_date new_value run_date
COLUMN  plus_date new_value plus_date
                                        
-- Start Date & Time
select to_char(add_months(sysdate, -2), 'YYYYMM') as plus_date
from dual
/

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

spool $DATADIR/RSORTN.dat
select distinct tn 
from dns_tn_mstr@&1
where STATE_CD IN ('AZ','CO','IA','ID','MN','MT','ND','NE','NM','OR','UT','SD','WA','WY')
  and length(ltrim(tn, ' ')) = 10
/
spool off
set heading on

quit
