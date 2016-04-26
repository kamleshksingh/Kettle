truncate table crts_prod_def;

INSERT INTO crts_prod_def 
SELECT 
             prod_cd,
             eff_dat,
             end_dat,
             prod_desc,
             acty_dat
FROM crtsb562v@&1;

COMMIT;

EXIT 0;
