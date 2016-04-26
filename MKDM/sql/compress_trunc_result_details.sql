-------------------------------------------------------------------------------
-- Program         :  compress_trunc_result_details.sql
--
-- Original Author :  dxpanne
--
-- Description     :  To truncate table dmart_partn_status_ref
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

WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

PROMPT To truncate table dmart_partn_status_ref

TRUNCATE TABLE dmart_partn_status_ref;
