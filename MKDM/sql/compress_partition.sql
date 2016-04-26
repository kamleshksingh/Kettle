-------------------------------------------------------------------------------
-- Program         :  compress_partition.sql
--
-- Original Author :  dxpanne
--
-- Description     :  To compress the partitions
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID      Description
-- MM/DD/YYYY CUID
------------- -------- --------------------------------------------------------
-- 07/25/2008 dxpanne Initial check in
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET FEEDBACK ON
SET SERVEROUTPUT ON

WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

PROMPT To compress partitions 

DECLARE
sql_statement  VARCHAR2(4000);
sql_statement1 VARCHAR2(4000);
flag_err       VARCHAR2(2);
mod_code       VARCHAR2(20):='&1';

-----------------------------------------------
-- Status Code For The Indicators To Be Put In
--  the partition_error_cd column
--
-- C --> Partition compressed successfully
-- E --> Error while compressing partition
-----------------------------------------------

CURSOR table_list IS
SELECT ref.partition_table_nm, usr.partition_position-ref.no_partition_qty position
FROM dmart_partn_compress_ref ref,
(SELECT table_name, MAX(partition_position) partition_position  FROM user_tab_partitions
GROUP BY table_name) usr
WHERE usr.table_name=ref.partition_table_nm
AND ref.module_cd = '&1';

CURSOR part_list (tbl_nm IN VARCHAR2, pos IN NUMBER)
IS
SELECT table_name, partition_name FROM user_tab_partitions usr
WHERE usr.table_name=tbl_nm
AND usr.partition_position <= pos
AND upper(usr.compression)='DISABLED';
part_list_rec part_list%ROWTYPE;

PROCEDURE updateproc(tbl_name IN  VARCHAR2,part_name IN varchar2, mod_cd IN VARCHAR2,flag IN VARCHAR2)
IS
BEGIN
 INSERT INTO dmart_partn_status_ref(partition_table_nm, partition_nm, module_cd,
   partn_compress_status_cd) VALUES (tbl_name, part_name, mod_cd, flag);
 COMMIT;
  
  UPDATE dmart_partn_compress_ref SET 
   last_compress_dt=TRUNC(SYSDATE)
  ,partition_nm=part_name
  ,compress_error_cd=flag
  WHERE partition_table_nm=tbl_name
  AND   module_cd=mod_cd;
  COMMIT;
  
END;

BEGIN
FOR rec IN table_list
LOOP
	OPEN part_list(rec.partition_table_nm, rec.position);
	LOOP
		FETCH part_list INTO part_list_rec;
		EXIT WHEN part_list%NOTFOUND;
		
		sql_statement:='ALTER TABLE ' || part_list_rec.table_name || ' MODIFY PARTITION ' ||
				part_list_rec.partition_name || ' UNUSABLE LOCAL INDEXES';
		DBMS_OUTPUT.PUT_LINE(sql_statement);

		sql_statement1:='ALTER TABLE ' || part_list_rec.table_name || ' MOVE PARTITION ' ||
				 part_list_rec.partition_name || ' COMPRESS';
		DBMS_OUTPUT.PUT_LINE(sql_statement1);

		BEGIN
			EXECUTE IMMEDIATE sql_statement;
			EXECUTE IMMEDIATE sql_statement1;
			
			flag_err:='C';
			updateproc(part_list_rec.table_name, part_list_rec.partition_name,mod_code, flag_err);
			
			EXCEPTION
			WHEN OTHERS THEN
			flag_err:='E';
			updateproc(part_list_rec.table_name, part_list_rec.partition_name,mod_code, flag_err);
                END;
			
	END LOOP;
	CLOSE part_list;
END LOOP;
END;
/
