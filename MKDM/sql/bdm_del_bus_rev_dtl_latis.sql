-------------------------------------------------------------------------------
-- Program         :    bdm_del_bus_rev_dtl_latis.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Deletes records from business_rev_det_latis tables 
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 04/24/2007 mmuruga  Initial Checkin
-------------------------------------------------------------------------------
SET TIMING ON;
SET ECHO OFF;

WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;


DELETE FROM  business_rev_det_latis dtl
WHERE EXISTS (SELECT v_rowid from bus_week_dtl_latis bus
	      WHERE  bus.v_rowid = dtl.rowid)
;

COMMIT;


QUIT;
