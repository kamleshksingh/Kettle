---------------------------------------------------------------  
-- Program         :  crt_so_from_pans.sql                   
-- Original Author :                                             
--                                                               
-- Description     :  Creates the so_from_pans table 
--                    this table contains the account level PANS data   
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

DROP TABLE so_from_pans;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLE so_from_pans
TABLESPACE &1
as SELECT  
   r.sostate,
   r.soptnind,
   r.soordnum,
   r.soentdt,
   r.soenttm,
   r.somtn, 
   r.socusnam,
   r.sodd,
   r.somu, 
   r.soordsta, 
   r.soslscd,
   r.soappdt,
   r.socursfx,
   r.lastupd pans_date,         
   r.sfslss,
   r.sfcus,
   r.socd,
   r.sfcanc,
   r.sondd
FROM rsorso_y@to_pans r  
WHERE  r.lastupd > '&2'
; 

quit;
