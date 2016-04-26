-------------------------------------------------------------------------------
-- Program         : 
--
-- Original Author :
--
-- Description     :
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
--  
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON;

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

   CREATE INDEX acct_svc_idx
   ON           acct_svc_temp (component_group_cd,component_grp_val)
   TABLESPACE &1 NOLOGGING;

   EXIT;
