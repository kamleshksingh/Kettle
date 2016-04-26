-------------------------------------------------------------------------------
-- Program         : dns_crt_dnc_dne_indx.sql
-- Original Author : kwillet
--
-- Description     :  Create index on dns_dnc_dne_temp (tn) dns_dnc_dne_pk1 
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

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR CONTINUE

PROMPT Dropping indexes on DNS_DNC_DNE_TEMP table

DROP INDEX dns_dnc_dne_idx1;

PROMPT Creating index dns_dnc_dne_idx1

CREATE INDEX dns_dnc_dne_idx1 
       ON    dns_dnc_dne_temp(tn)
TABLESPACE &1
NOLOGGING
PARALLEL 4;


EXIT;
