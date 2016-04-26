truncate table crts_prod_family_def;

INSERT INTO crts_prod_family_def 
SELECT 
             prod_cd,
             asgnmt_fmly_typ_cd,
             fmly_prod_cd,
             eff_dat,
             end_dat,
             fmly_prod_desc,
             acty_dat
FROM crtsb574v@&1;

COMMIT;

EXIT 0;
