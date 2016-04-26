-------------------------------------------------------------------------------
-- Program         :  drop_rowid_tmp_tbl.sql
--
-- Original Author :  nbeneve
--
-- Description     :  Drop temp table
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

DROP TABLE &1._rtmp;

EXIT;
