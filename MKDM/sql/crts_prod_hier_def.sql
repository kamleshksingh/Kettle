truncate table crts_prod_hier_def;

INSERT INTO crts_prod_hier_def 
SELECT 
             bus_ln_nm,
             prod_gr_nm,
             prod_tier_nm,
             asgnmt_fmly_typ_cd,
             fmly_prod_cd,
             eff_dat,
             end_dat,
             acty_dat
FROM crtsb575v@&1;

COMMIT;

EXIT 0;
