-------------------------------------------------------------------------------
-- Program         :    bdm_ins_current_month_data.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Insert into table business_rev_sum_temp1
--                      Revenue Details.
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------

SET TIMING ON
SET ECHO ON
SET FEEDBACK ON

WHENEVER OSERROR EXIT FAILURE ;
WHENEVER SQLERROR EXIT FAILURE ;


INSERT INTO business_rev_sum_temp1
SELECT /*+ parallel(tmp,4) */  * FROM business_rev_sum_temp1_&1 tmp;

select sum(cur_mo_tot_rev_amt) total_amount from business_rev_sum_temp1_&1;
select sum(cur_mo_ld_tot_amt) total_ld_amount from business_rev_sum_temp1_&1;

COMMIT;

TRUNCATE TABLE business_rev_sum_temp1_&1; 
DROP TABLE business_rev_sum_temp1_&1;

QUIT;
