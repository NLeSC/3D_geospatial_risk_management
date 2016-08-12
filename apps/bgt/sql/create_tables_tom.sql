create table bgt_begroeidterreindeel (
    ogc_fid integer,
    wkt geometry,
    namespace string,
    lokaalid string,
    objectbegintijd date,
    objecteindtijd date,
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


create table bgt_ondersteunendwaterdeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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

create table bgt_onbegroeidterreindeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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

create table bgt_ondersteunendwegdeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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
	ondersteunendwegdeeloptalud boolean
);

create table bgt_overbruggingsdeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
	tijdstipregistratie timestamp,
	eindregistratie timestamp,
	lv_publicatiedatum timestamp,
	bronhouder string,
	inonderzoek boolean,
	relatievehoogteligging integer,
	bgt_status string,
	plus_status string,
	typeoverbruggingsdeel string,
	hoortbijtypeoverbrugging string,
	overbruggingisbeweegbaar boolean
);

create table overbruggingsdeel(
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
	tijdstipregistratie timestamp,
	eindregistratie timestamp,
	lv_publicatiedatum timestamp,
	bronhouder string,
	inonderzoek boolean,
	relatievehoogteligging integer,
	bgt_status string,
	plus_status string,
	typeoverbruggingsdeel string,
	hoortbijtypeoverbrugging string,
	overbruggingisbeweegbaar boolean
);

create table bgt_overigbouwwerk (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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

create table bgt_pand (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
	tijdstipregistratie timestamp,
	eindregistratie timestamp,
	lv_publicatiedatum timestamp,
	bronhouder string,
	inonderzoek boolean,
	relatievehoogteligging integer,
	bgt_status string,
	plus_status string,
	identificatiebagpnd bigint
);


create table bgt_scheiding (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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

create table bgt_tunneldeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
	tijdstipregistratie timestamp,
	eindregistratie timestamp,
	lv_publicatiedatum timestamp,
	bronhouder string,
	inonderzoek boolean,
	relatievehoogteligging integer,
	bgt_status string,
	plus_status string
);

create table bgt_waterdeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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

create table bgt_wegdeel (
    ogc_fid integer,
	wkt geometry,
	namespace string,
	lokaalid string,
	objectbegintijd date,
	objecteindtijd date,
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
	bgt_functie string,
	plus_functie string,
	bgt_fysiekvoorkomen string,
	plus_fysiekvoorkomen string,
	wegdeeloptalud boolean
);

create table bgt_paal(
    ogc_fid integer default next value for "count",
    wkt geometry,
	gml_id string,
	creationdate date,
	namespace string,
	lokaalid string,
	relatievehoogteligging integer,
	lv_publicatiedatum timestamp,
	inonderzoek boolean,
	tijdstipregistratie timestamp,
	bgt_status string,
	plus_status string,
	bronhouder string,
	functionalitie string,
	plus_type string,
	hectometeraanduiding string
);

create table bgt_kunstwerkdeel(
    ogc_fid integer default next value for "count",
    wkt geometry,
	gml_id string,
	creationdate date,
	tijdstipregistratie timestamp,
	inonderzoek boolean,
	relatievehoogteligging integer,
	lv_publicatiedatum timestamp,
	namespace string,
	lokaalid string,
	bgt_status string,
	plus_status string,
	bronhouder string,
	bgt_type string,
	plus_type string
);

