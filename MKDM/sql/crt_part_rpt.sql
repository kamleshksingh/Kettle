-------------------------------------------------------------------------------
-- Program         :    mkdm_crt_part_rpt.sql 
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This script spools the report for corresponding module
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID        Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 12/11/2007 kraman    Initial check-in   
-------------------------------------------------------------------------------

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;


SET SERVEROUTPUT ON;
SET FEEDBACK OFF;
SET VERIFY OFF;

spool &1



DECLARE

  CURSOR rpt_cursor  is
     SELECT a.partition_table_nm,
            a.last_partition_create_dt,
            b.owner,
            DECODE(a.partition_error_cd,
                   'PE','Error Creating Partition',
                   'XP','Partition Already Exists',
                   'IE','Error Rebuilding Index',
                   'YY','Partition Created',
                   'EE','Error',
                   'NN'
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
                               || rpad(rpt_val.owner,7,' ') ||'|'
                               || rpad(rpt_val.last_partition_create_dt,13,' ') ||'|'
                               || rpad(rpt_val.status,24,' ')
                               ||' *');
  END IF;

END LOOP;

END;
/
QUIT;
