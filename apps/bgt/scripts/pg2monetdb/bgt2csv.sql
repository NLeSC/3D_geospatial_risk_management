/*
Getting the BGT out of postgis into csv files
*/
COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_type,plus_type 
FROM bgt_import2.waterdeel_2d) TO '/tmp/waterdeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_fysiekvoorkomen,plus_fysiekvoorkomen, CASE WHEN onbegroeidterreindeeloptalud  = true THEN 'true' ELSE 'false' END AS onbegroeidterreindeeloptalud 
FROM bgt_import2.onbegroeidterreindeel_2d) TO '/tmp/onbegroeidterreindeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status,bgt_fysiekvoorkomen,plus_fysiekvoorkomen, CASE WHEN begroeidterreindeeloptalud  = true THEN 'true' ELSE 'false' END AS onbegroeidterreindeeloptalud 
FROM bgt_import2.begroeidterreindeel_2d) TO '/tmp/begroeidterreindeel_2d.csv'  WITH DELIMITER '|' CSV HEADER;

COPY (SELECT ogc_fid,ST_AsText(wkb_geometry) wkt,namespace,lokaalid,objectbegintijd,objecteindtijd,tijdstipregistratie,eindregistratie,lv_publicatiedatum,bronhouder,CASE WHEN inonderzoek = true THEN 'true' ELSE 'false' END AS inonderzoek,relatievehoogteligging,bgt_status,plus_status, identificatiebagpnd 
FROM bgt_import2.pand_2d) TO '/tmp/pand_2d.csv'  WITH DELIMITER '|' CSV HEADER;
