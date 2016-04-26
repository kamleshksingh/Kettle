-------------------------------------------------------------------------------
-- Program         :    drop_module_temp_det.sql 
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This SQL drops the temp table module_det_temp
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID        Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 12/11/2007 kraman    Initial check-in   
-------------------------------------------------------------------------------


WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

DROP TABLE module_det_temp;

COMMIT;

EXIT;