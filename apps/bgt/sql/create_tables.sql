create table bgt_auxiliarytrafficarea (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	func string,
	surfaceMat string,
	ondersteun integer,
	plus_fysie string,
	kmlgeometry geometry
);

create table bgt_bak (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	namespace string,
	lokaalID string,
	bronhouder string,
	bgt_status string,
	plus_statu string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_bord (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_bridgeconstructionelement (
	gml_id string,
	creationDa date,
	inOnderzoe integer,
	relatieveH integer,
	LV_publica timestamp,
	tijdstipRe timestamp,
	namespace string,
	lokaalID string,
	bgt_status string,
	bronhouder string,
	class string,
	overbruggi integer,
	hoortBijTy string,
	kmlgeometry geometry
);

create table bgt_buildinginstallation (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_buildingpart (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	identifica bigint,
	kmlgeometry geometry
);

create table bgt_funceelgebied (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	bgt_type string,
	plus_type string,
	naam string,
	kmlgeometry geometry
);

create table bgt_installatie (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bronhouder string,
	bgt_status string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_kast (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_kunstwerkdeel (
	gml_id string,
	creationDa date,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	LV_publica timestamp,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	bgt_type string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_mast (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_onbegroeidterreindeel (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	bgt_fysiek string,
	onbegroeid integer,
	plus_fysie string,
	kmlgeometry geometry
);

--Supporting water
create table bgt_ondersteunendwaterdeel (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	class string,
	kmlgeometry geometry
);

--unclassified object
create table bgt_ongeclassificeerdobject (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	bronhouder string,
	kmlgeometry geometry
);

--Public space tag
create table bgt_openbareruimtelabel (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bronhouder string,
	bgt_status string,
	plus_statu string,
	identifica bigint,
	tekst string,
	openbareRu string,
	kmlgeometry geometry
);

--Other construction
create table bgt_overigbouwwerk (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	bgt_type string,
	plus_type string,
	kmlgeometry geometry
);

--Other seperation
create table bgt_overigescheiding (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	plus_type string,
	kmlgeometry geometry
);

--pole pool
create table bgt_paal (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	func string,
	plus_type string,
	hectometer string,
	kmlgeometry geometry
);

create table bgt_plaatsbepalingspunt (
	gml_id string,
	namespace string,
	lokaalID string,
	nauwkeurig integer,
	datumInwin date,
	inwinnende string,
	inwinnings string,
	kmlgeometry geometry
);

create table bgt_plantcover (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	class string,
	begroeidTe integer,
	plus_fysie string,
	kmlgeometry geometry
);

create table bgt_put (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_railway (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	func string,
	plus_funct string,
	kmlgeometry geometry
);

create table bgt_scheiding (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	bgt_type string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_sensor (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_solitaryvegetationobject (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	LV_publica timestamp,
	relatieveH integer,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	plus_statu string,
	bronhouder string,
	class string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_straatmeubilair (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_trafficarea (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	bronhouder string,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_statu string,
	func string,
	surfaceMat string,
	wegdeelOpT integer,
	plus_fysie string,
	plus_funct string,
	kmlgeometry geometry
);

create table bgt_tunnelpart (
	gml_id string,
	creationDa date,
	namespace string,
	lokaalID string,
	relatieveH integer,
	LV_publica timestamp,
	inOnderzoe integer,
	tijdstipRe timestamp,
	bgt_status string,
	bronhouder string,
	kmlgeometry geometry
);

create table bgt_waterdeel (
	gml_id string,
	creationDa date,
	tijdstipRe timestamp,
	relatieveH integer,
	inOnderzoe integer,
	LV_publica timestamp,
	bronhouder string,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_statu string,
	class string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_waterinrichtingselement (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);

create table bgt_weginrichtingselement (
	gml_id string,
	creationDa date,
	LV_publica timestamp,
	tijdstipRe timestamp,
	inOnderzoe integer,
	relatieveH integer,
	namespace string,
	lokaalID string,
	plus_statu string,
	bgt_status string,
	bronhouder string,
	func string,
	plus_type string,
	kmlgeometry geometry
);
