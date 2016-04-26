--*****************************************************************************
--** Program         :  mkdm_drop_part_rpt.sql
--**
--** Original Author :  
--**
--** Description     :  To Generate report for the Drop Partition Process
--**                    
--**
--** Revision History:  Please do not stray from the example provided.
--**
--** Modfied    User
--** Date       ID       Description
--** MM/DD/YYYY CUID
--** ---------- -------- ------------------------------------------------
--** 11/13/2007  kraman  Intial Checkin
--*****************************************************************************

WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

SET SERVEROUTPUT ON;
SET FEEDBACK OFF;
SET VERIFY OFF;
spool &1

DECLARE    
     
  CURSOR rpt_cursor  is
     SELECT a.partition_table_nm,
            a.last_partition_drop_dt,
            b.owner,
            DECODE(partition_error_cd,
                   'TE','Error Truncating Partition',
                   'DE','Error Dropping Partition',
	 	   'AD','Partition Already Dropped',
		   'YY','Partition Dropped',
		   'IE','Error Rebuilding Index',
    		   'NN','Error'
		  ) status
     FROM  dmart_partition_ref a,all_tables b
     WHERE UPPER(a.partition_table_nm)=UPPER(b.table_name)
     AND UPPER(a.module_cd)=UPPER('&2')
     AND a.partition_ind='Y';

BEGIN
 
FOR rpt_val in rpt_cursor LOOP

  IF rpt_val.status <> 'NN'
  THEN
    DBMS_OUTPUT.PUT_LINE('* ' ||rpad(rpt_val.partition_table_nm,28,' ') ||'|'
                               || rpad(rpt_val.owner,6,' ') ||'|'
                               || rpad(rpt_val.last_partition_drop_dt,12,' ') ||'|'
                               || rpad(rpt_val.status,26,' ')
                               ||' *');
  END IF;

END LOOP;

END;
/
QUIT;
