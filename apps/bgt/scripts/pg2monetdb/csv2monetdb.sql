/*
Loading bgt csv files into monetdb (first create_tables)
(only polygons so far...)
*/

COPY OFFSET 2 INTO bgt_waterdeel FROM ('/tmp/waterdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_onbegroeidterreindeel_2d FROM ('/tmp/onbegroeidterreindeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_begroeidterreindeel_2d FROM ('/tmp/begroeidterreindeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_pand_2d FROM ('/tmp/pand_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_ondersteunendwaterdeel_2d FROM ('/tmp/ondersteunendwaterdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_ondersteunendwegdeel_2d FROM ('/tmp/ondersteunendwegdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_overbruggingsdeel_2d FROM ('/tmp/overbruggingsdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_overigbouwwerk_2d FROM ('/tmp/overigbouwwerk_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_scheiding_2d FROM ('/tmp/scheiding_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_tunneldeel_2d FROM ('/tmp/tunneldeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
COPY OFFSET 2 INTO bgt_wegdeel_2d FROM ('/tmp/wegdeel_2d.csv') USING DELIMITERS '|','\n' NULL AS '' LOCKED;
