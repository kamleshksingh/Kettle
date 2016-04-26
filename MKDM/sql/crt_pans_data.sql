---------------------------------------------------------------
-- Program         :  pans_data.sql.sql       
-- Original Author :                                           
--                                                             
-- Description     :  Creates the pans_data table.
--                    This table contains the combined PANS data  
--                    from ln_from_pans and so_from_pans.
--                    This process removes today's data since it 
--                    might not be complete. The process will pick
--                    this data up tomorrow.
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

DROP TABLE pans_data;

WHENEVER SQLERROR EXIT FAILURE
CREATE TABLE pans_data
TABLESPACE &1
as SELECT                                    
          l.sostate state,  
          l.soptnind,                               
          l.soordnum ordnum,                               
          l.soentdt,                                
          l.soenttm,                                
          l.slusoc usoc,
          l.slact,                                  
          l.slqty,                                  
          l.sltn,                                   
          l.sldvdp dvdp,                                 
          l.slslscd ln_slscd, 
          r.somtn tn,                           
          r.socusnam name,                        
          r.sodd duedat,                            
          r.somu,                            
          r.soordsta,       
          r.soslscd so_slscd,                         
          r.soappdt,                         
          r.socursfx,               
          r.sfslss alt_slscd,                          
          r.sfcus cus_cd,   
          r.socd comp_date ,                                 
          r.pans_date
 FROM ln_from_pans l
     ,so_from_pans r
WHERE  
      r.sostate =  l.sostate                        
AND   r.soptnind = l.soptnind                        
AND   r.soordnum = l.soordnum                        
AND   r.soentdt =  l.soentdt                        
AND   r.soenttm =  l.soenttm   
AND   r.pans_date < trunc(sysdate) 
;

quit;
