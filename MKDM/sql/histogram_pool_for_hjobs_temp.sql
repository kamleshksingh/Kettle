-------------------------------------------------------------------------------
-- Program         :  histogram_pool_for_hjobs_temp.sql
--
-- Original Author :  Praveen 
--
-- Description     :  This script creates histogram intervals
--                    using CUR_WEEK_DTL_TEMP table for running hjobs in background.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 03/16/2006 pxthiru  Initial Checkin
-- 12/05/2007 urajend  Modified to use CON_REV_MONTHLY_DTL_TEMP table 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER SQLERROR EXIT FAILURE;
WHENEVER OSERROR EXIT FAILURE  ;

SET SERVEROUTPUT ON ;

TRUNCATE TABLE hjobs_histogram_pool REUSE STORAGE  ;

DECLARE
v_count_acct_cur NUMBER ;
v_loop_count NUMBER ;
v_num_of_histogram_jobs NUMBER := &1  ;  /* this variable tells number of inetervals */
v_chunk_size  NUMBER ;
previous_acct_id NUMBER ;
current_acct_id  NUMBER  ;
job_id NUMBER ;
error_no NUMBER ;
error_text VARCHAR2(100) ;

CURSOR account_histogram (p_chunk_size NUMBER,p_count_acct_cur NUMBER ) is
SELECT acct_id,position FROM (
 SELECT acct_id,rownum as position  FROM (
     SELECT /*+ FULL(a) PARALLEL(a,6) */ DISTINCT acct_id FROM CON_REV_MONTHLY_DTL_TEMP a
              ORDER BY acct_id
                           ) )
WHERE MOD(position , p_chunk_size ) = 0
  OR position = 1                 --  TO Get Min ACCT_ID
  OR position = p_count_acct_cur  --- TO Get Max ACCT_ID
  ORDER BY acct_id ;

BEGIN

error_text := 'Selecting count from CON_REV_MONTHLY_DTL_TEMP table' ;

SELECT /*+ FULL(a)  PARALLEL(a,6) */ COUNT(DISTINCT acct_id)
   INTO v_count_acct_cur
FROM CON_REV_MONTHLY_DTL_TEMP a ;

  v_chunk_size := CEIL(v_count_acct_cur/v_num_of_histogram_jobs) ;

v_loop_count := 0 ;
previous_acct_id := 0 ;
current_acct_id := 0 ;
job_id := 0 ;
error_text := ' Before For Loop ' ;

FOR account_histogram_rec IN account_histogram(v_chunk_size,v_count_acct_cur) LOOP
v_loop_count := v_loop_count + 1 ;
previous_acct_id := current_acct_id ;
current_acct_id := account_histogram_rec.acct_id ;

IF v_loop_count = 2 THEN
 previous_acct_id := previous_acct_id - 1  ;
 END IF ;

 IF v_loop_count > 1  THEN
INSERT INTO  hjobs_histogram_pool ( job_id,begin_acct_id,end_acct_id,run_date)
              VALUES(v_loop_count - 1  , previous_acct_id + 1 ,current_acct_id , sysdate ) ;
dbms_output.put_line(v_loop_count - 1||'   '||(previous_acct_id+1)||'  '||current_acct_id) ;

 END IF ;

END LOOP ;

COMMIT ;
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM) ;
DBMS_OUTPUT.PUT_LINE('error text is '||' '||error_text) ;
RAISE_APPLICATION_ERROR(-20220,'Run Time Error Occured While Preparing Histogram Pool') ;
END ;
/
QUIT
