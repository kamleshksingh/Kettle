---------------------------------------------------------------
-- Program         :  crt_bdm_wonback_slscd_view.sql       
-- Original Author :                                           
--                                                             
-- Description     :  Creates the bdm_wonback_slscd view
--                    this view contains the consumer Wonback sales code data  
--                                                                   
-- Revision History:  Please do not stray from the example provided. 
--                                                                   
-- Modfied    User                       
-- Date       ID       Description       
                                         
-- ---------- -------- ------------------
-- 10/12/2004 vewalke  Initial Checkin   
---------------------------------------------------------------------
-- SQLPlus Set Parameters                                            
---------------------------------------------------------------------
WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE OR REPLACE VIEW bdm_wonback_slscd 
AS SELECT
d.state,                
          d.soptnind,                      
          d.ordnum,               
          d.soentdt,                       
          d.soenttm,                       
          d.tn,       
          d.cus_cd,                      
          d.comp_date,                 
          d.so_slscd,              
          NVL(d.ln_slscd,a.ln_slscd) ln_slscd,             
          d.alt_slscd,              
          d.pans_date 
FROM   pans_data   d ,
        (SELECT    state ,                         
                   soptnind ,                         
                   ordnum ,                            
                   soentdt ,                            
                   soenttm ,
                   tn,                                                
                   cus_cd,                                                
                   comp_date,                                          
                   so_slscd,                                          
                   ln_slscd,                                  
                   alt_slscd,                                         
                   pans_date 
         FROM pans_data
         WHERE usoc not in ('KSTWB','KSTWC','KSTWD','KSTWN')     
           AND   so_slscd is not null 
         GROUP BY  state ,               
                   soptnind ,                         
                   ordnum ,                            
                   soentdt ,                            
                   soenttm ,                                 
                   tn,                                                
                   cus_cd,        
                   comp_date,                                          
                   so_slscd,                                          
                   ln_slscd,                                  
                   alt_slscd,                                         
                   pans_date ) a
WHERE  d.state    = a.state (+)                         
AND    d.soptnind = a.soptnind (+)                         
AND    d.ordnum   = a.ordnum  (+)                           
AND    d.soentdt  = a.soentdt (+)                            
AND    d.soenttm  = a.soenttm (+)                               
AND   substr(d.somu,1,1) in ('S','L','F','G') 
AND   d.soordsta in ('PP','CP')                       
AND   d.slact = 'I'                                   
AND   d.usoc in ('KSTWB','KSTWC','KSTWD','KSTWN')    
GROUP BY                                              
          d.state,                
          d.soptnind,            
          d.ordnum,               
          d.soentdt,                       
          d.soenttm,                       
          d.tn,                      
          d.cus_cd,                      
          d.comp_date,      
          d.so_slscd,              
          NVL(d.ln_slscd,a.ln_slscd),              
          d.alt_slscd,              
          d.pans_date  
/

select count(*) from bdm_wonback_slscd;

exit 0;
