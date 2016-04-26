-------------------------------------------------------------------------------
-- Program         :  bdm_hist_pool_for_hjobs_temp.sql
--
-- Original Author :  mmuruga 
--
-- Description     :  This script creates histogram intervals
--                    using BUS_WEEK_DTL_TEMP table for running hjobs in background.
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 02/22/2007 mmuruga  Initial Checkin
-- 10/25/2007 mmuruga  Modified the maximum acct_id.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR EXIT FAILURE  ;
WHENEVER SQLERROR CONTINUE;

DROP TABLE bdm_hjobs_histogram_pool;

WHENEVER SQLERROR EXIT FAILURE;

CREATE TABLE bdm_hjobs_histogram_pool
 (JOB_ID        NUMBER(3)
  ,BEGIN_ACCT_ID  VARCHAR2(20)
  ,END_ACCT_ID    VARCHAR2(20)
  ,RUN_DATE       DATE  ) tablespace work_perm;

SET SERVEROUTPUT ON ;

DECLARE
v_count_acct_cur NUMBER ;
v_loop_count NUMBER ;
v_num_of_histogram_jobs NUMBER := &1  ;  /* this variable tells number of inetervals */
v_chunk_size  NUMBER ;
previous_acct_id VARCHAR2(20);
current_acct_id  VARCHAR2(20);
job_id NUMBER ;
error_no NUMBER ;
error_text VARCHAR2(100) ;

CURSOR account_histogram (p_chunk_size NUMBER,p_count_acct_cur NUMBER ) is
SELECT blg_acct_id,position FROM (
 SELECT blg_acct_id,rownum as position  FROM (
     SELECT /*+ FULL(a) PARALLEL(a,6) */ DISTINCT blg_acct_id FROM BUS_WEEK_DTL_TEMP a
              ORDER BY blg_acct_id
                           ) )
WHERE MOD(position , p_chunk_size ) = 0
  OR position = 1                 --  TO Get Min ACCT_ID
  OR position = p_count_acct_cur  --- TO Get Max ACCT_ID
  ORDER BY blg_acct_id ;

BEGIN

error_text := 'Selecting count from BUS_WEEK_DTL_TEMP table' ;

SELECT /*+ FULL(a)  PARALLEL(a,6) */ COUNT(DISTINCT blg_acct_id)
   INTO v_count_acct_cur
FROM BUS_WEEK_DTL_TEMP a ;

  v_chunk_size := CEIL(v_count_acct_cur/v_num_of_histogram_jobs) ;

v_loop_count := 0 ;
previous_acct_id := 0 ;
current_acct_id := 0 ;
job_id := 0 ;
error_text := ' Before For Loop ' ;

FOR account_histogram_rec IN account_histogram(v_chunk_size,v_count_acct_cur) LOOP
v_loop_count := v_loop_count + 1 ;
previous_acct_id := current_acct_id ;
current_acct_id := account_histogram_rec.blg_acct_id ;

IF v_loop_count = 11 THEN
current_acct_id := 'ZZZZZZZZZZZZZZZZZZZ';
END IF;

 IF v_loop_count > 1  THEN
INSERT INTO  bdm_hjobs_histogram_pool ( job_id,begin_acct_id,end_acct_id,run_date)
              VALUES(v_loop_count - 1  , previous_acct_id  ,current_acct_id , sysdate ) ;
dbms_output.put_line(v_loop_count - 1||'   '||(previous_acct_id)||'  '||current_acct_id) ;

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
