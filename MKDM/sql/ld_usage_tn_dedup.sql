-------------------------------------------------------------------------------
-- Program         : ld_usage_tn_dedup.sql
--
-- Original Author : jkading
--
-- Revision History:  Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 07/14/2004 jkading  Initial Checkin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET ECHO ON

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

PROMPT Deleting duplicates from ld_usage_tn
PROMPT *************************************
DELETE FROM ld_usage_tn
 WHERE ROWID IN (
    SELECT v_rowid FROM
       (
        SELECT
           ROW_NUMBER() OVER(PARTITION BY wtn ORDER BY wtn DESC ) AS no_del,
           ROWID AS v_rowid
          FROM ld_usage_tn
       )
     WHERE no_del != 1
    );

COMMIT;
QUIT
