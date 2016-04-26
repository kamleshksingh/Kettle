-------------------------------------------------------------------------------
-- Program         :    compress_rebuild_unusable_indexes.sql
--
-- Original Author :    dxpanne
--
-- Description     :    This SQL rebuilds indexes for tables present in 
--                      the reference table of  corresponding module
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID        Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 07/28/2008 dxpanne    Initial check-in   
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER SQLERROR EXIT FAILURE;
WHENEVER OSERROR EXIT FAILURE;

SET SERVEROUTPUT ON SIZE 1000000;
SET LINES 200;
SET TIMING ON;

-- Bind Variable To Get Proper Exit Status For The Code
VARIABLE status number;

DECLARE
  sql_statement VARCHAR2(800);
  flag_error   VARCHAR2(10);

CURSOR non_part_indexes IS
(
  SELECT
          i.index_name AS index_name
         ,i.table_name AS table_name
         ,i.status     AS status
         ,i.tablespace_name AS  tablespace_name
         ,c.rowid       AS row_id
    FROM
      user_indexes i,
      dmart_partn_compress_ref c
      WHERE
            UPPER(c.partition_table_nm) = i.table_name
        AND lower(i.status) = 'unusable'
        AND c.module_cd = '&1'
 MINUS
  SELECT DISTINCT
          ip.index_name AS index_name
         ,t.table_name  AS table_name
         ,ip.status     AS status
         ,ip.tablespace_name AS tablespace_name
         ,c.rowid       AS row_id
    FROM
         user_part_indexes p,
         user_tab_partitions t,
         user_ind_partitions ip,
         dmart_partn_compress_ref c
      WHERE
        UPPER(c.partition_table_nm) = p.table_name 
        AND p.table_name = t.table_name
        AND ip.index_name = p.index_name
        AND lower(ip.status)='unusable'
        AND c.module_cd = '&1'
 );

CURSOR part_indexes IS
  SELECT DISTINCT
          ip.index_name AS index_name
         ,ip.partition_name AS partition_name
         ,t.table_name AS table_name
         ,ip.tablespace_name AS tablespace_name
         ,p.locality AS locality
         ,ip.status     AS status
         ,c.rowid       AS row_id
    FROM
         user_part_indexes p,
         user_tab_partitions t,
         user_ind_partitions ip,
         dmart_partn_compress_ref c
      WHERE
        UPPER(c.partition_table_nm) = p.table_name
        AND p.table_name = t.table_name
        AND ip.index_name = p.index_name
        AND lower(ip.status)='unusable'
        AND c.module_cd = '&1';

   PROCEDURE updateproc(flag IN VARCHAR2,tbl_name IN  VARCHAR2,row_id IN varchar2)
     IS
        BEGIN
             UPDATE dmart_partn_compress_ref
                SET compress_error_cd = flag
              WHERE UPPER(partition_table_nm) = UPPER(tbl_name)
                AND rowid = row_id;
             COMMIT;
    END;    


BEGIN

  :status :=0;

  FOR x IN part_indexes LOOP
   BEGIN
    flag_error:='IE';
    IF ( x.locality = 'LOCAL') then

     DBMS_OUTPUT.PUT_LINE ('LOCAL INDEX -> ' || x.index_name || ' Partition -> ' ||x.partition_name);

     /* Local Index -> Re-Build Index for the particular unusable index in partition */

      sql_statement:='ALTER TABLE ' || x.table_name || ' MODIFY PARTITION ' || x.partition_name;
      sql_statement:= sql_statement || ' REBUILD UNUSABLE LOCAL INDEXES ';

      DBMS_OUTPUT.PUT_LINE ( sql_statement );

      EXECUTE IMMEDIATE (sql_statement);

    END IF;


   EXCEPTION
     WHEN OTHERS THEN
        IF flag_error = 'IE' THEN
              DBMS_OUTPUT.PUT_LINE('Index for the table Not Rebuilt.');
        ELSE
              flag_error:= 'EE';
              DBMS_OUTPUT.PUT_LINE('Error Occured ');
        END IF;
       updateproc(flag_error,x.table_name,x.row_id);
       :status:=1;
  END;
 END LOOP;



  FOR z IN non_part_indexes LOOP

  BEGIN
   /* Non-partition_ind Index Normal Re-Build */
   flag_error:='IE';
   DBMS_OUTPUT.PUT_LINE ('NON-partition_ind INDEX -> ' || z.index_name || ' Tablespace -> ' || z.tablespace_name);

   sql_statement:=' ALTER INDEX ' || z.index_name || ' REBUILD TABLESPACE ' || z.tablespace_name ;

   DBMS_OUTPUT.PUT_LINE ( sql_statement );

   EXECUTE IMMEDIATE (sql_statement);


  EXCEPTION
    WHEN OTHERS THEN
       IF flag_error = 'IE' THEN
            DBMS_OUTPUT.PUT_LINE('Index for the table Not Rebuilt.');
       ELSE 
      	    flag_error:= 'EE';
	    DBMS_OUTPUT.PUT_LINE('Error Occured ');
       END IF;
       updateproc(flag_error,z.table_name,z.row_id);
       :status:=1;
  END;
  END LOOP;

END;
/

PRINT :status

