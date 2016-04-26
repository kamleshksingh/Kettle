-------------------------------------------------------------------------------
-- Program         : mkdm_account_question_hist_delta.sql 
--
-- Original Author : Sanjeev
--
-- Description     : load account_question_hist data from ISDB (PVG) 
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
--  06/21/2004  schaudh Initial Checkin
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

   SET FEEDBACK ON;
   SET TIMING ON;
   SET VERIFY OFF;


   WHENEVER OSERROR EXIT FAILURE
   WHENEVER SQLERROR EXIT FAILURE

   PROMPT Loading account_question_hist data from ISDB (PVG) 

   SET TRANSACTION USE ROLLBACK SEGMENT &1;

   INSERT /*+ APPEND */ INTO account_question_hist  
   (
     BTN    ,
     BTN_CUST_CD,
     CAPTURE_DAT,
     USER_NM   ,
     PVG_QUESTION_ID,
     PVG_ANSWER_TEXT,
     PVG_ANSWER_ID,
    QA_GROUP_ID
   ) 
   SELECT  
     BTN    ,
     BTN_CUST_CD,
     CAPTURE_DAT,
     USER_NM   ,
     PVG_QUESTION_ID,
     PVG_ANSWER_TEXT,
     PVG_ANSWER_ID,
    QA_GROUP_ID
   FROM account_question_hist@&2 
   WHERE capture_dat  BETWEEN  TO_DATE('&3', 'mm:dd:yyyy:hh24:mi:ss') AND TRUNC(SYSDATE)   ;


   COMMIT;

   EXIT;
