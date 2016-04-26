------------------------------------------------------------------------------
-- Program         :   bdm_crt_bus_rev_summ_locn_view.sql
--
-- Original Author :   sxlank2
--
-- Description     :   create view on BUSINESS_REVENUE_SUMM_LOCN table
--                     with distinct cl_ids.The cl_id with greater CUR_MO_TOT_REV_AMT
--                     is selected.
--
-- Revision History:   Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- ------------------------------------------------
-- 04/28/2009 sxlank2  Initial checkin.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SQLPlus Set Parameters
-------------------------------------------------------------------------------
SET TIMING ON
SET TIME ON
SET ECHO ON


WHENEVER OSERROR  EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;

CREATE OR REPLACE VIEW BUSINESS_REVENUE_SUMM_LOCN
AS 
 SELECT * FROM  BUSINESS_REVENUE_SUMM_CUR
 WHERE ROWID IN (
  SELECT v_rowid FROM
               (
                 SELECT ROW_NUMBER() OVER(PARTITION BY cl_id ORDER BY CUR_MO_TOT_REV_AMT DESC)
                 as no_del,ROWID as v_rowid 
                 FROM BUSINESS_REVENUE_SUMM_CUR WHERE cl_id IS NOT NULL
                )
          WHERE no_del = 1
                      ) ;

QUIT

