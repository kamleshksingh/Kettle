---------------------------------------------------------------   
-- Program         :  crt_index_ln_from_pans.sql.sql                           
-- Original Author :                                              
--                                                                
-- Description     :  Creates the index on the ln_from_pans table
--                                                                    
-- Revision History:  Please do not stray from the example provided.  
--                                                                    
-- Modfied    User                                                    
-- Date       ID       Description                                   
                                                                     
-- ---------- -------- ------------------                            
-- 10/06/2004 vewalke  Initial Checkin                               
---------------------------------------------------------------------
-- SQLPlus Set Parameters                                            
--------------------------------------------------------------------- 
WHENEVER SQLERROR CONTINUE 

DROP INDEX ln_from_pansx;

WHENEVER SQLERROR EXIT FAILURE

CREATE INDEX ln_from_pansx on ln_from_pans
(sostate,soptnind,soordnum,soentdt,soenttm)
TABLESPACE &1
;

quit;
