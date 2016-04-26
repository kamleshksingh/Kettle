--*****************************************************************************
--** Program         :  mkdm_del_hist_data.sql
--**
--** Original Author :  
--**
--** Description     :  Delete the records from non partitioned tables.
--**                    
--**
--** Revision History:  Please do not stray from the example provided.
--**
--** Modfied    User
--** Date       ID      Description
--** MM/DD/YYYY CUID
--** ---------- -------- ------------------------------------------------
--** 11/13/2007  kraman  Intial Checkin
--*****************************************************************************


WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

--SET ECHO ON;

PROMPT Deleting records from non-partioned tables
PROMPT **********************************

DECLARE 

   sql_statement   VARCHAR2(400);
   err_num         NUMBER;
   run_date        DATE  := sysdate ;
   QueryColumn    VARCHAR2(400);

BEGIN
   FOR tablist IN (SELECT a.table_name,b.hist_month_keep_qty,b.hist_roll_column_nm
		     FROM user_tables a, dmart_partition_ref b
                    WHERE  a.table_name = UPPER(b.partition_table_nm)
		      AND UPPER(b.module_cd) = UPPER('&1')
		      AND b.partition_ind='N')
   LOOP
      QueryColumn:=NULL;
          QueryColumn:= 'TO_CHAR('||tablist.hist_roll_column_nm||', ''YYYYMM'')<=TO_CHAR(ADD_MONTHS(SYSDATE, -'|| tablist.hist_month_keep_qty ||'), ''YYYYMM'')';
      IF QueryColumn is NOT NULL  THEN
         DBMS_OUTPUT.PUT_LINE(tablist.table_name || ',' || tablist.hist_month_keep_qty);
         sql_statement:='DELETE FROM ' || tablist.table_name || ' WHERE ' || QueryColumn;
         
         DBMS_OUTPUT.PUT_LINE(sql_statement);
         EXECUTE IMMEDIATE sql_statement;
      END IF;

   END LOOP;
END;
/
exit;
