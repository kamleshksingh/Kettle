-------------------------------------------------------------------------------
-- Program         :    bdm_crt_business_rev_sum_temp.sql
--
-- Original Author :    mmuruga
--
-- Description     :    Create structure for table business_rev_sum_temp1
--                      Revenue Details.
--
-- Revision History:    Please do not stray from the example provided.
--
-- Modfied    User
-- Date       ID       Description
-- MM/DD/YYYY CUID
-- ---------- -------- --------------------------------------------------------
-- 01/24/2007 mmuruga  Initial Checkin
-- 11/18/2011 txmx    Replaced the finedw tables by ccdw_cons_prod_hier,bundle_ref
-------------------------------------------------------------------------------


WHENEVER SQLERROR CONTINUE

DROP TABLE business_rev_sum_temp1;

DECLARE
   sql_str_mn      LONG;
   sql_str_drp     LONG;
   sql_str         VARCHAR2 (16000);
   sql_str2        VARCHAR2 (100);
   v_tabl_nm       VARCHAR2 (50);
   v_join_cond     VARCHAR2 (50);
   v_join_cond1    VARCHAR2 (50);
   

   CURSOR dyn_rev
   IS
      SELECT DISTINCT group_no, MAX (logical_join_val) logical_join_val
                 FROM business_revenue_summ_ctl
             GROUP BY group_no
             ORDER BY group_no;

   CURSOR dyn_cur_1 (ingrpnm IN VARCHAR2)
   IS
      SELECT   *
          FROM business_revenue_summ_ctl
         WHERE group_no = LOWER (ingrpnm)
      ORDER BY group_seq_no;

   dyn_cur_1_rec   dyn_cur_1%ROWTYPE;
BEGIN

   sql_str_mn :=
      'CREATE TABLE business_rev_sum_temp1  
       TABLESPACE &1 
       NOLOGGING
       PARALLEL 4
       AS 
       SELECT /*+ parallel(cdt,4) parallel(ctd,4) parallel(b,4) parallel(c,4) parallel(d,4)*/
              cdt.blg_acct_id,
              max(cdt.blg_to_blg_acct_id) as blg_to_blg_acct_id,
	      cdt.blg_sce_sys_cd,
              max(cdt.bill_mo) as bill_mo,
              max(cdt.jnl_blg_dt) as jnl_blg_dt';
   
   FOR dyn_rev_rec IN dyn_rev
   LOOP
      sql_str := '';

      OPEN dyn_cur_1 (dyn_rev_rec.group_no);

      FETCH dyn_cur_1
       INTO dyn_cur_1_rec;

      IF LOWER (dyn_rev_rec.logical_join_val) = 'sum'
      THEN
         sql_str := sql_str || ', ' || '
                    sum(';
      ELSE
         sql_str :=
                   sql_str || ', ' || '
                    sum(CASE WHEN (';
      END IF;

      WHILE dyn_cur_1%FOUND
      LOOP
         IF dyn_cur_1_rec.table_nm = 'CCDW_CONS_PROD_HIER'
         THEN
            v_tabl_nm := 'cpd';
         ELSIF dyn_cur_1_rec.table_nm = 'BUS_WEEK_DTL_TEMP'
         THEN
            v_tabl_nm := 'cdt';
         ELSIF dyn_cur_1_rec.table_nm = 'BUNDLE_REF'
         THEN
            v_tabl_nm := 'b';
         ELSIF dyn_cur_1_rec.table_nm = 'TMP_BLLD_PROD_CD_ACCT'
         THEN
            v_tabl_nm := 'c';
         ELSIF dyn_cur_1_rec.table_nm = 'TMP_BLLD_USOC_ACCT'
         THEN
            v_tabl_nm := 'd';
         END IF;

         v_join_cond := LOWER (dyn_cur_1_rec.logical_join_val);

         IF LOWER (dyn_cur_1_rec.logical_join_val) = 'or'
         THEN
            sql_str := sql_str || ' (';
         END IF;

         sql_str :=
                   sql_str || v_tabl_nm || '.' || dyn_cur_1_rec.condition1_txt;

         IF dyn_cur_1_rec.join_condition_val = 'Y'
         THEN
            sql_str := sql_str || '=';
         ELSIF dyn_cur_1_rec.join_condition_val = 'N'
         THEN
            sql_str := sql_str || '!=';
         ELSE
            sql_str := sql_str || ' ' || dyn_cur_1_rec.join_condition_val;
         END IF;

         sql_str2 := ' ';

         IF     v_join_cond1 = 'or'
            AND NVL (LOWER (dyn_cur_1_rec.logical_join_val), 1) <> 'or'
         THEN
            sql_str2 := ' )';
         END IF;

         IF    dyn_cur_1_rec.join_condition_val = '<'
            OR dyn_cur_1_rec.join_condition_val = '>'
            OR UPPER (dyn_cur_1_rec.join_condition_val) LIKE '%IS%'
         THEN
            sql_str :=
                  sql_str
               || dyn_cur_1_rec.condition2_txt
               || sql_str2
               || ' '
               || dyn_cur_1_rec.logical_join_val
               || ' ';
         ELSIF LOWER (dyn_cur_1_rec.logical_join_val) = 'sum'
         THEN
            sql_str := sql_str || ' ';
         ELSE
            sql_str :=
                  sql_str
               || ''''
               || dyn_cur_1_rec.condition2_txt
               || ''''
               || sql_str2
               || ' '
               || dyn_cur_1_rec.logical_join_val
               || ' ';
         END IF;

         v_join_cond1 := v_join_cond;

         FETCH dyn_cur_1
          INTO dyn_cur_1_rec;
      END LOOP;

      IF LOWER (dyn_cur_1_rec.logical_join_val) = 'sum'
      THEN
         sql_str := sql_str || ') ';
      ELSIF LOWER (dyn_cur_1_rec.column_nm) LIKE '%mou_qty'
      THEN
         sql_str := sql_str || ') THEN cdt.minutes_of_use ELSE 0 END) ';
      ELSE
         sql_str := sql_str || ') THEN cdt.rev_amt ELSE 0 END) ';
      END IF;

      sql_str := sql_str || dyn_cur_1_rec.column_nm;
      sql_str_mn := sql_str_mn || sql_str;

      CLOSE dyn_cur_1;
   END LOOP;

   sql_str_mn :=
           sql_str_mn
      || ' FROM BUS_WEEK_DTL_TEMP cdt,CCDW_CONS_PROD_HIER  cpd,BUNDLE_REF b,
                TMP_BLLD_PROD_CD_ACCT c,TMP_BLLD_USOC_ACCT d 
   WHERE 1=2';
   sql_str_mn := sql_str_mn || ' GROUP BY cdt.blg_acct_id,cdt.blg_sce_sys_cd';
   put_long_line (sql_str_mn);

   EXECUTE IMMEDIATE sql_str_mn;
EXCEPTION
   WHEN OTHERS
   THEN
      IF dyn_cur_1%ISOPEN
      THEN
         CLOSE dyn_cur_1;
      END IF;

      raise_application_error (-20001, SQLERRM);
END;
/

QUIT;
