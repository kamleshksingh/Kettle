---------------------------------------------------------------   
-- Program         :  crt_ln_from_pans.sql.sql                           
-- Original Author :                                              
--                                                                
-- Description     :  Creates the ln_from_pans table                 
--                    this table contains the USOC level PANS data      
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

DROP TABLE ln_from_pans;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE ln_from_pans
TABLESPACE &1
as SELECT                        
            l.sostate,
            l.soptnind,     
            l.soordnum,       
            l.soentdt,   
            l.soenttm,     
            l.slusoc,  
            l.slact,
            l.slqty,
            l.sltn,      
            l.sldvdp,
            l.slslscd,
            l.lastupd pans_date
FROM rsorln_y@to_pans l     
WHERE  l.lastupd > '&2'
;

quit;
