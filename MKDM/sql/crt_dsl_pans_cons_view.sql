---------------------------------------------------------------
-- Program         :  create_dsl_pans_cons_view.sql       
-- Original Author :                                           
--                                                             
-- Description     :  Creates the dsl_pans_cons view
--                    This view contains all consumer DSL PANS service order 
--                    data. The process this was designed for uses accounts 
--                    where the dvdp field is null. This view was not created 
--                    that way so it could potentially be used for future 
--                    analysis.  
--                                                                   
-- Revision History:  Please do not stray from the example provided. 
--                                                                   
-- Modfied    User                       
-- Date       ID       Description       
                                         
-- ---------- -------- ------------------
-- 10/05/2004 vewalke  Initial Checkin   
---------------------------------------------------------------------
-- SQLPlus Set Parameters                                            
---------------------------------------------------------------------
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE VIEW dsl_pans_cons 
AS SELECT
       state,
       ordnum, 
       so_slscd,
       tn,     
       name, 
       duedat,
       usoc,
       dvdp,
       pans_date            
 FROM pans_data r
WHERE      
           NVL(substr(somu,1,1),'H') = 'H'
  AND      soordsta in ('AO','AC','RL','PD')
  AND      slact = 'I'
  AND     ( usoc like 'GRL%'
    OR      usoc like 'GPR%'
    OR      usoc like 'G5L%')
GROUP BY state,
         ordnum,
         so_slscd,
         tn,     
         name, 
         duedat,
         usoc,
         dvdp,
         pans_date     
;


select count(*) from dsl_pans_cons;

quit;
