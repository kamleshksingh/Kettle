-------------------------------------------------------------------------------
-- Program         :  crt_idx_rowid_tmp_tbl.sql
--
-- Original Author :  nbeneve
--
-- Description     :  Create index on row_id
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID      Description
-- MM/DD/YYYY CUID
-- ---------- -------- -------------------------------------------------------
-- 06/05/2008 nbeneve Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET ECHO ON
SET TIMING ON

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR CONTINUE

DROP INDEX &1._rtmp_idx;

WHENEVER SQLERROR EXIT FAILURE

CREATE INDEX &1._rtmp_idx ON &1._rtmp(row_id) TABLESPACE &2 PARALLEL 5 NOLOGGING;

EXIT;
