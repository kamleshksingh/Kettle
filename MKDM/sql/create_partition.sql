-------------------------------------------------------------------------------
-- Program         :    mkdm_create_partition.sql
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This SQL creates the partition for tables present in 
--                      the reference table of corresponding module
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID        Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 12/11/2007 kraman    Initial check-in
-- 11/29/2012 kxsing3   timestamp handling done   
-- 16/01/2014 arpatel   Added If-ELSE-End If block, against HD00006749724 to add next-to-next month partition
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

PROMPT CREATING PARTITIONS FOR THE TABLES
PROMPT **********************************


DECLARE

   sql_statement   VARCHAR2(400);
   err_num         NUMBER;
   part_col_datatype      varchar2(50);
   new_part_name          varchar2(36);
   part_range             varchar2(6);
   part_date              varchar2(8);
   flag_error             varchar2(2);
   existing_partition    EXCEPTION;
   PRAGMA EXCEPTION_INIT(existing_partition,-14074);

-----------------------------------------------
-- Error Code For The Indicators To Be Put In
--  the partition_error_cd column
--
-- PE -> Error At Creating Partition.
-- XP  -> Partititon Already Existing
-- YY -> Partition Created
------------------------------------------------

   CURSOR part_cursor IS
      SELECT
         partition_table_nm,
         partition_tablespace_nm,
         last_partition_create_dt,
         decode(partition_prefix_cd, null,'P' ,'P','P' ,partition_prefix_cd || '_') partition_prefix_cd,
         partition_format_cd,
         partition_split_ind,
         split_partition_nm,
         rowid
      FROM dmart_partition_ref 
      WHERE last_partition_create_dt < TO_DATE(TO_CHAR(sysdate,'YYYYMMDD'),'YYYYMMDD')
      AND UPPER(module_cd)=UPPER('&1')
      AND partition_ind='Y';
    
   PROCEDURE updateproc(flag IN VARCHAR2,tbl_name IN  VARCHAR2,row_id IN varchar2)
     IS
        BEGIN
          IF flag = 'YY' THEN
             UPDATE dmart_partition_ref
                SET partition_error_cd = flag,
                    last_partition_create_dt = sysdate
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
    
          FOR cpart in part_cursor
          LOOP
          flag_error:='PE';
    
          SELECT b.data_type into part_col_datatype
          FROM user_part_key_columns a,user_tab_columns b
          WHERE a.column_name=b.column_name
          and a.name=b.table_name
          and a.name=upper(cpart.partition_table_nm);
    
          new_part_name := cpart.partition_prefix_cd || to_char(add_months(sysdate,1), cpart.partition_format_cd);
          part_date     := to_char(trunc(add_months(sysdate,2), 'MM'),'YYYYMMDD');
          part_range    := to_char(trunc(add_months(sysdate,2), 'MM'),'YYYYMM');
    
          IF ( cpart.partition_split_ind = 'Y' ) then
             sql_statement:=
                ' ALTER TABLE ' || cpart.partition_table_nm ||
                ' SPLIT PARTITION ' || cpart.split_partition_nm ||
                ' AT (to_date (''' || part_date || ''',''YYYYMMDD''))'  ||
                ' INTO ( PARTITION ' || new_part_name ||
                ' , PARTITION ' || cpart.split_partition_nm || ')' ||
                ' PARALLEL 6 ' ;
          ELSIF ( part_col_datatype = 'DATE' OR substr(part_col_datatype,1,9) = 'TIMESTAMP' ) then
              sql_statement:=
                ' ALTER TABLE ' || cpart.partition_table_nm ||
                ' ADD PARTITION ' || new_part_name ||
                ' VALUES LESS THAN (to_date (''' || part_date || ''',''YYYYMMDD''))' ||
                ' TABLESPACE ' || cpart.partition_tablespace_nm ;
          ELSE
             sql_statement:=
                ' ALTER TABLE ' || cpart.partition_table_nm ||
                ' ADD PARTITION ' || new_part_name ||
                ' VALUES LESS THAN (' || part_range || ')' ||
                ' TABLESPACE ' || cpart.partition_tablespace_nm ;
          END IF;
    

          DBMS_OUTPUT.PUT_LINE(sql_statement);

          BEGIN
             EXECUTE IMMEDIATE sql_statement;  

             flag_error:='YY';
             updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);

          EXCEPTION

             WHEN existing_partition THEN
             flag_error:='XP';
             DBMS_OUTPUT.PUT_LINE('Partition Was Already Existing For The Month ' || new_part_name ||' For Table '||cpart.partition_table_nm);
             updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);
            WHEN OTHERS THEN
              err_num:=SQLCODE;
              IF flag_error = 'PE'
              THEN
              DBMS_OUTPUT.PUT_LINE('Partition Not Created For Table ' || cpart.partition_table_nm ||' Due to Error ' || err_num);
              ELSIF flag_error = 'IE'
              THEN
              DBMS_OUTPUT.PUT_LINE('Index for the table '|| cpart.partition_table_nm || 'Not Rebuilt.');
              ELSE
              flag_error:= 'EE';
              DBMS_OUTPUT.PUT_LINE('Error Occured '||err_num);
              END IF;
              updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);
           END;

---- This below If -End-If part is taking care for creation of future month partition ,against HD00006749724

        If ( cpart.partition_table_nm = 'BUSINESS_REVENUE_DET' OR cpart.partition_table_nm = 'CONSUMER_REVENUE_DET') Then
          new_part_name := cpart.partition_prefix_cd || to_char(add_months(sysdate,2), cpart.partition_format_cd);
          part_date     := to_char(trunc(add_months(sysdate,3), 'MM'),'YYYYMMDD');
          part_range    := to_char(trunc(add_months(sysdate,3), 'MM'),'YYYYMM');

		  IF ( cpart.partition_split_ind = 'Y' ) then
		     sql_statement:=
			' ALTER TABLE ' || cpart.partition_table_nm ||
			' SPLIT PARTITION ' || cpart.split_partition_nm ||
			' AT (to_date (''' || part_date || ''',''YYYYMMDD''))'  ||
			' INTO ( PARTITION ' || new_part_name ||
			' , PARTITION ' || cpart.split_partition_nm || ')' ||
			' PARALLEL 6 ' ;
			--DBMS_OUTPUT.PUT_LINE('Testing part4');
		  ELSIF ( part_col_datatype = 'DATE' OR substr(part_col_datatype,1,9) = 'TIMESTAMP') then
		      sql_statement:=
			' ALTER TABLE ' || cpart.partition_table_nm ||
			' ADD PARTITION ' || new_part_name ||
			' VALUES LESS THAN (to_date (''' || part_date || ''',''YYYYMMDD''))' ||
			' TABLESPACE ' || cpart.partition_tablespace_nm ;
			-- DBMS_OUTPUT.PUT_LINE('Testing part5');
		  ELSE
		     sql_statement:=
			' ALTER TABLE ' || cpart.partition_table_nm ||
			' ADD PARTITION ' || new_part_name ||
			' VALUES LESS THAN (' || part_range || ')' ||
			' TABLESPACE ' || cpart.partition_tablespace_nm ;
			-- DBMS_OUTPUT.PUT_LINE('Testing part6');
		  END IF;


		DBMS_OUTPUT.PUT_LINE(sql_statement);

		 BEGIN
		     EXECUTE IMMEDIATE sql_statement;

		     flag_error:='YY';
		     updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);

		 EXCEPTION

		     WHEN existing_partition THEN
		     flag_error:='XP';
		     DBMS_OUTPUT.PUT_LINE('Partition Was Already Existing For The Month ' || new_part_name ||' For Table '||cpart.partition_table_nm);
		     updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);
		    WHEN OTHERS THEN
		      err_num:=SQLCODE;
		      IF flag_error = 'PE'
		      THEN
		      DBMS_OUTPUT.PUT_LINE('Partition Not Created For Table ' || cpart.partition_table_nm ||' Due to Error ' || err_num);
		      ELSIF flag_error = 'IE'
		      THEN
		      DBMS_OUTPUT.PUT_LINE('Index for the table '|| cpart.partition_table_nm || 'Not Rebuilt.');
		      ELSE
		      flag_error:= 'EE';
		      DBMS_OUTPUT.PUT_LINE('Error Occured '||err_num);
		      END IF;
		      updateproc(flag_error,cpart.partition_table_nm,cpart.rowid);
		 END;
           
        End If;
     ----------------------End here HD00006749724
   END LOOP;

END;
/

EXIT;
