/*
Loading bgt csv files into monetdb (first create_tables)
*/

COPY OFFSET 2 INTO bgt_waterdeel FROM ('/tmp/waterdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_onbegroeidterreindeel_2d FROM ('/tmp/onbegroeidterreindeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_begroeidterreindeel_2d FROM ('/tmp/begroeidterreindeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_pand_2d FROM ('/tmp/pand_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
