/*
	Getting the BGT out of postgis into csv files
	(only polygons so far...)
*/

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_type,plus_type 
FROM bgt_import2.waterdeel_2d) TO '/tmp/waterdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_fysiekvoorkomen,plus_fysiekvoorkomen, CASE WHEN onbegroeidterreindeeloptalud  = true THEN 'true' ELSE 'false' END AS onbegroeidterreindeeloptalud 
FROM bgt_import2.onbegroeidterreindeel_2d) TO '/tmp/onbegroeidterreindeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_fysiekvoorkomen,plus_fysiekvoorkomen, CASE WHEN begroeidterreindeeloptalud  = true THEN 'true' ELSE 'false' END AS onbegroeidterreindeeloptalud 
FROM bgt_import2.begroeidterreindeel_2d) TO '/tmp/begroeidterreindeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, identificatiebagpnd 
FROM bgt_import2.pand_2d) TO '/tmp/pand_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, bgt_type, plus_type 
FROM bgt_import2.ondersteunendwaterdeel_2d) TO '/tmp/ondersteunendwaterdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, bgt_functie, plus_functie, bgt_fysiekvoorkomen, plus_fysiekvoorkomen,CASE WHEN ondersteunendwegdeeloptalud  = true THEN 'true' ELSE 'false' END AS ondersteunendwegdeeloptalud 
FROM bgt_import2.ondersteunendwegdeel_2d) TO '/tmp/ondersteunendwegdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, typeoverbruggingsdeel, hoortbijtypeoverbrugging, CASE WHEN overbruggingisbeweegbaar = true THEN 'true' ELSE 'false' END AS overbruggingisbeweegbaar  
FROM bgt_import2.overbruggingsdeel_2d) TO '/tmp/overbruggingsdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, bgt_type, plus_type 
FROM bgt_import2.overigbouwwerk_2d) TO '/tmp/overigbouwwerk_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, bgt_type, plus_type 
FROM bgt_import2.scheiding_2d) TO '/tmp/scheiding_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status 
FROM bgt_import2.tunneldeel_2d) TO '/tmp/tunneldeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

/* Still a problem with wegdeel since it has curvey geometries */
COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_fysiekvoorkomen,plus_fysiekvoorkomen, CASE WHEN wegdeeloptalud  = true THEN 'true' ELSE 'false' END AS wegdeeloptalud 
FROM bgt_import2.wegdeel_2d) TO '/tmp/wegdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;
