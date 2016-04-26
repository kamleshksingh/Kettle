-------------------------------------------------------------------------------
-- Program         :    bdm_spool_data_mo.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Spool the distinct data_months that are to be processed
--                      
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------
whenever sqlerror exit failure
whenever oserror exit failure

set tab off
set pagesize 0
set feedback off
set linesize 150
spool &1


SELECT  DISTINCT bill_mo 
FROM    bus_week_dtl_temp a
WHERE NOT EXISTS (SELECT 1 FROM bdm_data_months_log log
		  WHERE a.bill_mo=log.bill_mo)
order by bill_mo
/
SPOOL OFF
EXIT
