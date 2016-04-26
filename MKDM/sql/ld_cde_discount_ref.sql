-------------------------------------------------------------------------------
-- Program         :  ld_cde_discount_ref.sql
--
-- Original Author :  nbeneve
--
-- Description     :  Loads cde_discount_ref table in CRDM/BDM from MKDM cde_discount_ref
--
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 05/05/2009 nbeneve  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------

SET TIMING ON
SET TIME ON
SET ECHO OFF

WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE 

PROMPT Truncating cde_discount_ref Table...

TRUNCATE TABLE cde_discount_ref;

PROMPT cde_discount_ref Truncated.

INSERT INTO cde_discount_ref SELECT * FROM cde_discount_ref@&1;

COMMIT;

EXIT
