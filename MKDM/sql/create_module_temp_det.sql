-------------------------------------------------------------------------------
-- Program         :    mkdm_create_module_temp_det.sql
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This SQL creates temp table for storing module list
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
WHENEVER SQLERROR CONTINUE;

DROP TABLE module_det_temp;


WHENEVER SQLERROR EXIT FAILURE;

CREATE TABLE 
module_det_temp(module_nm varchar2(20), status varchar2(1));


EXIT;
