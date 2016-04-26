-------------------------------------------------------------------------------
-- Program         : dns_crt_cdw_dncdne_indx.sql
-- Original Author : kwillet
--
-- Description     :  Create index on dns_cdw_dnc_dne_temp (acct_id, acct_seq_no) 
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

SET timing on;
SET echo on;
SET term on;

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

PROMPT Dropping index on dns_cdw_dnc_dne_temp table

DROP INDEX dns_cdw_dnc_dne_temp_idx1;

PROMPT Creating index dns_cdw_dnc_dne_temp_idx1

WHENEVER SQLERROR EXIT FAILURE

CREATE INDEX dns_cdw_dnc_dne_temp_idx1 ON dns_cdw_dnc_dne_temp(acct_id,acct_seq_no) 
TABLESPACE &1
NOLOGGING
PARALLEL 4;

EXIT;
