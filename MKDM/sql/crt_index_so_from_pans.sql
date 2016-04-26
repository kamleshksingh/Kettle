---------------------------------------------------------------  
-- Program         :  crt_index_so_from_pans.sql                   
-- Original Author :                                             
--                                                               
-- Description     :  Creates the so_from_pans table index
--                                                                   
--                                                                   
-- Modfied    User                                                   
-- Date       ID       Description                                   
-- ---------- -------- ------------------                             
-- 10/06/2004 vewalke  Initial Checkin                                
--------------------------------------------------------------------- 
-- SQLPlus Set Parameters                                             
--------------------------------------------------------------------- 
WHENEVER SQLERROR CONTINUE

DROP INDEX so_from_pansx;

WHENEVER SQLERROR EXIT FAILURE

CREATE INDEX so_from_pansx on so_from_pans
(sostate,soptnind,soordnum,soentdt,soenttm)
TABLESPACE &1
;


quit ;
