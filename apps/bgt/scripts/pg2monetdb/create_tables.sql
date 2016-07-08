/* 
	Create tables in monetdb, according to NLExtract setup for postgis
*/

create table bgt_waterdeel_2d (
        ogc_fid string,
        wkt geometry,
        namespace string,
        lokaalid string,
        objectbegintijd timestamp,
        objecteindtijd timestamp,
        tijdstipregistratie timestamp,
        eindregistratie timestamp,
        lv_publicatiedatum timestamp,
        bronhouder string,
        inonderzoek boolean,
        relatievehoogteligging integer,
        bgt_status string,
        plus_status string,
        bgt_type string,
        plus_type string
);

create table bgt_onbegroeidterreindeel_2d (
        ogc_fid string,
        wkt geometry,
        namespace string,
        lokaalid string,
        objectbegintijd timestamp,
        objecteindtijd timestamp,
        tijdstipregistratie timestamp,
        eindregistratie timestamp,
        lv_publicatiedatum timestamp,
        bronhouder string,
        inonderzoek boolean,
        relatievehoogteligging integer,
        bgt_status string,
        plus_status string,
        bgt_fysiekvoorkomen string,
        plus_fysiekvoorkomen string,
        onbegroeidterreindeeloptalud boolean
);

create table bgt_begroeidterreindeel_2d (
        ogc_fid string,
        wkt geometry,
        namespace string,
        lokaalid string,
        objectbegintijd timestamp,
        objecteindtijd timestamp,
        tijdstipregistratie timestamp,
        eindregistratie timestamp,
        lv_publicatiedatum timestamp,
        bronhouder string,
        inonderzoek boolean,
        relatievehoogteligging integer,
        bgt_status string,
        plus_status string,
        bgt_fysiekvoorkomen string,
        plus_fysiekvoorkomen string,
        begroeidterreindeeloptalud boolean
);
create table bgt_pand_2d (
        ogc_fid string,
        wkt geometry,
        namespace string,
        lokaalid string,
        objectbegintijd timestamp,
        objecteindtijd timestamp,
        tijdstipregistratie timestamp,
        eindregistratie timestamp,
        lv_publicatiedatum timestamp,
        bronhouder string,
        inonderzoek boolean,
        relatievehoogteligging integer,
        bgt_status string,
        plus_status string,
        identificatiebagpnd string
);
