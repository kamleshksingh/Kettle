--*****************************************************************************
--** Program         :  mkdm_drop_partition.sql
--**
--** Original Author :  
--**
--** Description     :  Drops Partition for the tables in the reference table 
--** 			maintaining the history for the months specified
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

--SET ECHO ON;

PROMPT DROPPING PARTITIONS FOR THE TABLES 
PROMPT **********************************

DECLARE 

   sql_statement   VARCHAR2(400);
   err_num         NUMBER;
   history         VARCHAR2(6);
   flag_error      VARCHAR2(2) :='NN';
   run_date        DATE  := sysdate ;

   alreadydropped_partition EXCEPTION;

-----------------------------------------------------------
-- Error Codes To be set For the Indicator column partition_error_cd
-- TE -> Error At Truncate Partition.
-- DE -> Error At Dropping Partition.
-- AD -> Partititon Already Dropped.
-- IR -> Error At Index Rebuilding.
-----------------------------------------------------------

   PRAGMA EXCEPTION_INIT(alreadydropped_partition,-2149);

   CURSOR part_cursor is
	SELECT DISTINCT ref.partition_table_nm,part.partition_name,ref.rowid as row_id
        FROM dmart_partition_ref ref
             ,(SELECT distinct partition_table_nm,partition_name 
               FROM dmart_partition_ref a, all_Tab_partitions b
               WHERE b.table_name =a.partition_table_nm
               AND REGEXP_LIKE(SUBSTR(partition_name,-6,6),'[[:digit:]]{6}') 
               AND TO_CHAR(TO_DATE(SUBSTR(partition_name,-6,6),partition_format_cd),'yyyymmdd') <= TO_CHAR(ADD_MONTHS(TRUNC(sysdate,'mm'),-(hist_month_keep_qty)+1),'yyyymmdd')
               AND UPPER(module_cd)=UPPER('&1')
               AND a.partition_ind='Y') part
	WHERE ref.partition_table_nm= part.partition_table_nm(+)
        AND UPPER(module_cd)=UPPER('&1')
        AND ref.partition_ind='Y'       ;


   d_part part_cursor%ROWTYPE;

   PROCEDURE updateproc(flag IN VARCHAR2,tbl_name IN  VARCHAR2,row_id IN ROWID)
   IS
      BEGIN
           IF flag = 'YY' THEN
             UPDATE dmart_partition_ref
                SET partition_error_cd = flag,
                    last_partition_drop_dt = sysdate
              WHERE partition_table_nm = tbl_name
                AND rowid = row_id;
             COMMIT;
          ELSE
             UPDATE dmart_partition_ref
                SET partition_error_cd = flag
              WHERE partition_table_nm = tbl_name
                AND rowid = row_id;
             COMMIT;
          END IF;     
      END;

BEGIN

  OPEN part_cursor;
   LOOP

     FETCH part_cursor INTO d_part;

     EXIT WHEN part_cursor%NOTFOUND;

     DBMS_OUTPUT.PUT_LINE(d_part.partition_table_nm);
 
     IF d_part.partition_name is null Then
	DBMS_OUTPUT.PUT_LINE('Partition Not Found For The Month ' || d_part.partition_table_nm);
        flag_error:='AD';
        updateproc(flag_error,d_part.partition_table_nm,d_part.row_id);
     ELSE
-- Truncate the partition

     flag_error:='TE';
     sql_statement:=  
        ' ALTER TABLE ' || d_part.partition_table_nm ||
        ' TRUNCATE PARTITION ' || d_part.partition_name;

     DBMS_OUTPUT.PUT_LINE(sql_statement);
 
   BEGIN 
      EXECUTE IMMEDIATE sql_statement;

-- Drop Partition

      flag_error:='DE';
      sql_statement:=
        ' ALTER TABLE ' || d_part.partition_table_nm ||
        ' DROP PARTITION ' || d_part.partition_name;

      DBMS_OUTPUT.PUT_LINE(sql_statement);

      EXECUTE IMMEDIATE sql_statement;

      flag_error:='YY';
     updateproc(flag_error,d_part.partition_table_nm,d_part.row_id);

    EXCEPTION 
      WHEN alreadydropped_partition THEN
        DBMS_OUTPUT.PUT_LINE('Partition Not Found For The Month ' || d_part.partition_name);
        flag_error:='AD';
        updateproc(flag_error,d_part.partition_table_nm,d_part.row_id);
      WHEN OTHERS THEN
        err_num:=SQLCODE;
        DBMS_OUTPUT.PUT_LINE('Partition Not Dropped Due to Error ' || err_num);
        updateproc(flag_error,d_part.partition_table_nm,d_part.row_id);
   END;
  END IF; 

   END LOOP;

   CLOSE part_cursor;

END;
/

PROMPT DROPPED PARTITIONS SUCCESSFULLY !!!
PROMPT ***********************************
 
EXIT;
