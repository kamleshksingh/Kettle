-------------------------------------------------------------------------------
-- Program         :    bdm_spool_no_jobs.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Spool the distinct no of jobs that are to be processed
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


SELECT  to_char(count(*))
FROM    bdm_hjobs_histogram_pool
/

SPOOL OFF 
EXIT

