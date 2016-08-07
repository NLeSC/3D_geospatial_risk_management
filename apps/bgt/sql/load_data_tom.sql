COPY 10000000 OFFSET 2 RECORDS INTO bgt_begroeidterreindeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_begroeidterreindeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_onbegroeidterreindeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_onbegroeidterreindeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_ondersteunendwaterdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_ondersteunendwaterdeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_ondersteunendwegdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_ondersteunendwegdeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_overbruggingsdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_overbruggingsdeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_overigbouwwerk FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_overigbouwwerk.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_pand FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_pand.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_scheiding FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_scheiding.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_tunneldeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_tunneldeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_waterdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_waterdeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_wegdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_wegdeel.csv') USING DELIMITERS '|','\n','"' NULL AS '' LOCKED;

CREATE SEQUENCE "count" as integer START WITH 1;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_paal FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_paal.csv') (wkt,gml_id,creationdate,namespace,lokaalid,relatievehoogteligging,lv_publicatiedatum,inonderzoek,tijdstipregistratie,bgt_status,plus_status,bronhouder,functionalitie,plus_type,hectometeraanduiding) USING DELIMITERS ',','\n','"' NULL AS '' LOCKED;

ALTER SEQUENCE "count" RESTART WITH 1;
COPY 10000000 OFFSET 2 RECORDS INTO bgt_kunstwerkdeel FROM ('/scratch/goncalve/data/geo_data/bgt/outs_csv/bgt_kunstwerkdeel.csv') (wkt,gml_id,creationdate,tijdstipregistratie,inonderzoek,relatievehoogteligging,lv_publicatiedatum,namespace,lokaalid,bgt_status,plus_status,bronhouder,bgt_type,plus_type) USING DELIMITERS ',','\n','"' NULL AS '' LOCKED;
