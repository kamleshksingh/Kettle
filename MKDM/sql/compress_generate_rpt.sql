-------------------------------------------------------------------------------
-- Program         :  compress_generate_rpt.sql
--
-- Original Author :  dxpanne
--
-- Description     :  To generate the report
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


SET VERIFY OFF;
SET NEWPAGE 0;
SET SPACE 0;
SET LINESIZE 200;
SET TERM OFF;
SET PAGESIZE 0;
SET ECHO OFF;
SET FEEDBACK OFF;
SET HEADING OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

spool &1;

SELECT ' ' from dual;
SELECT '*-----------------------------------------------------------------------*' FROM dual;
SELECT ' ' from dual;
SELECT '         COMPRESS PARTITION REPORT FOR ' || TRUNC(SYSDATE) FROM dual;
SELECT ' ' from dual;
SELECT '*-----------------------------------------------------------------------*' FROM dual;
SELECT ' ' from dual;

SELECT 'TABLE NAME                    '
    || 'PARTITION NAME                '
    || 'MODULE CODE         '
    || 'STATUS                        ' 
FROM dual;

SELECT '*-----------------------------------------------------------------------*' FROM dual;

SELECT ' ' from dual;
SELECT 
 RPAD(partition_table_nm,30)
,RPAD(partition_nm,30)
,RPAD(module_cd,20)
,RPAD(DECODE(partn_compress_status_cd,'C','Complete','E', 'Error', 'Error while rebuilding indexes'),30)
FROM dmart_partn_status_ref;

spool off;
