/* 
	Create tables in monetdb, according to NLExtract setup for postgis
	(only polygons so far...)
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
create table bgt_ondersteunendwaterdeel_2d (
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

create table bgt_ondersteunendwegdeel_2d (
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
        ondersteunendwegdeeloptalud boolean
);

create table bgt_overbruggingsdeel_2d (
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
        ypeoverbruggingsdeel string, 
        hoortbijtypeoverbrugging string, 
        ondersteunendwegdeeloptalud boolean
);


create table bgt_overigbouwwerk_2d (
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

create table bgt_scheiding_2d (
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

create table bgt_tunneldeel_2d (
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
        plus_status string
  
);

create table bgt_wegdeel_2d (
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
        bgt_functie string,
        plus_functie string,
        bgt_fysiekvoorkomen string,
        plus_fysiekvoorkomen string,
        wegdeeloptalud boolean
);
