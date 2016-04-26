-------------------------------------------------------------------------------
-- Program         : dns_drp_cdw_dncdne_tbl.sql
-- Original Author : kwillet
--
-- Description     :  Drop dns_drp_dnc_dne_all_tbl table 
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


PROMPT DECLARING RUN_DATE
                                        
-- Start Date & Time
select sysdate as run_date 
from dual
/

set echo off;
set timing on;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR CONTINUE;

PROMPT Truncating dns_cdw_dnc_dne_temp TABLE
PROMPT *************************************

truncate table dns_cdw_dnc_dne_temp;

PROMPT Dropping dns_cdw_dnc_dne_temp TABLE
PROMPT *************************************

drop table dns_cdw_dnc_dne_temp;

PROMPT Truncating dns_dnc_dne_temp TABLE
PROMPT *************************************

truncate table dns_dnc_dne_temp;

PROMPT Dropping dns_dnc_dne_temp TABLE
PROMPT *************************************

drop table dns_dnc_dne_temp;


exit;
