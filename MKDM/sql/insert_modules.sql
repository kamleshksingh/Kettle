-------------------------------------------------------------------------------
-- Program         :    mkdm_crt_part_rpt.sql 
--
-- Original Author :    Keerthana Raman
--
-- Description     :    This SQL inserts module_names in temp table
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

DECLARE
mod_count NUMBER(1);

BEGIN

SELECT count(1) into mod_count FROM module_det_temp
WHERE module_nm='&1';

if mod_count=0 then
	INSERT INTO module_det_temp VALUES('&1','N');
	COMMIT;
end if;

end;

/
