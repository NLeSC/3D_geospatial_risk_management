create table bgt_auxiliarytrafficarea (
	WKT geometry,
	gml_id string,
	creationDate string,
	terminationDate string,
	namespace string,
	lokaalID string,
	relatieveHoogteligging integer,
	LV_publicatiedatum timestamp,
	inOnderzoek integer,
	tijdstipRegistratie timestamp,
	eindRegistratie string,
	bgt_status string,
	plus_status string,
	bronhouder string,
	"function" string,
	surfaceMaterial string,
	ondersteunendWegdeelOpTalud integer,
	plus_fysiekVoorkomenOndersteunendWegdeel string
);

create table bgt_bak (
	WKT geometry,
	gml_id string,
	creationDate string,
	LV_publicatiedatum timestamp,
	relatieveHoogteligging integer,
	inOnderzoek integer,
	tijdstipRegistratie timestamp,
	namespace string,
	lokaalID string,
	bronhouder string,
	bgt_status string,
	plus_status string,
	"function" string,
	plus_type string,
	eindRegistratie string,
	terminationDate string
);

create table bgt_bord (
	WKT geometry,
	gml_id string,
	creationDate string,
	LV_publicatiedatum timestamp,
	tijdstipRegistratie timestamp,
	inOnderzoek integer,
	relatieveHoogteligging integer,
	namespace string,
	lokaalID string,
	bgt_status string,
	plus_status string,
	bronhouder string,
	"function" string,
	plus_type string,
	eindRegistratie string,
	terminationDate string
);

create table bgt_bridgeconstructionelement (
WKT geometry,
gml_id string,
creationDate string,
inOnderzoek integer,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
tijdstipRegistratie timestamp,
namespace string,
lokaalID string,
bgt_status string,
bronhouder string,
"class" string,
overbruggingIsBeweegbaar integer,
hoortBijTypeOverbrugging string,
eindRegistratie string,
terminationDate string
);

create table bgt_buildinginstallation (
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
inOnderzoek integer,
tijdstipRegistratie timestamp,
plus_status string,
bgt_status string,
bronhouder string,
"function" string,
plus_typeGebouwInstallatie string,
terminationDate string,
eindRegistratie string
);

create table bgt_buildingpart (
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
inOnderzoek integer,
tijdstipRegistratie timestamp,
bgt_status string,
plus_status string,
bronhouder string,
identificatieBAGPND bigint,
tekst string,
hoek string,
identificatieBAGVBOLaagsteHuisnummer string,
eindRegistratie string,
identificatieBAGVBOHoogsteHuisnummer string,
terminationDate string
);

create table bgt_funceelgebied (
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
inOnderzoek integer,
tijdstipRegistratie timestamp,
plus_status string,
bgt_status string,
bronhouder string,
bgt_type string,
plus_type string,
naam string,
eindRegistratie string,
terminationDate string
);

create table bgt_installatie (
WKT geometry,
gml_id string,
creationDate string,
LV_publicatiedatum timestamp,
tijdstipRegistratie timestamp,
inOnderzoek integer,
relatieveHoogteligging integer,
namespace string,
lokaalID string,
plus_status string,
bronhouder string,
bgt_status string,
"function" string,
plus_type string,
terminationDate string,
eindRegistratie string
);

create table bgt_kast (
WKT geometry,
gml_id string,
creationDate string,
LV_publicatiedatum timestamp,
tijdstipRegistratie timestamp,
inOnderzoek integer,
relatieveHoogteligging integer,
namespace string,
lokaalID string,
bgt_status string,
plus_status string,
bronhouder string,
"function" string,
plus_type string,
terminationDate string,
eindRegistratie string
);

create table bgt_kunstwerkdeel (
WKT geometry,
gml_id string,
creationDate string,
tijdstipRegistratie timestamp,
inOnderzoek integer,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
namespace string,
lokaalID string,
bgt_status string,
plus_status string,
bronhouder string,
bgt_type string,
plus_type string,
terminationDate string,
eindRegistratie string
);

create table bgt_mast (

	WKT geometry,
gml_id string,
creationDate string,
LV_publicatiedatum timestamp,
tijdstipRegistratie timestamp,
inOnderzoek integer,
relatieveHoogteligging integer,
namespace string,
lokaalID string,
plus_status string,
bgt_status string,
bronhouder string,
"function" string,
plus_type string,
terminationDate string,
eindRegistratie string
);

create table bgt_onbegroeidterreindeel (
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
LV_publicatiedatum timestamp,
relatieveHoogteligging integer,
inOnderzoek integer,
tijdstipRegistratie timestamp,
bgt_status string,
plus_status string,
bronhouder string,
bgt_fysiekVoorkomen string,
onbegroeidTerreindeelOpTalud integer,
plus_fysiekVoorkomen string,
eindRegistratie string,
terminationDate string
);

--Supporting water
create table bgt_ondersteunendwaterdeel (
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
LV_publicatiedatum timestamp,
relatieveHoogteligging integer,
inOnderzoek integer,
tijdstipRegistratie timestamp,
bgt_status string,
plus_status string,
bronhouder string,
"class" string,
eindRegistratie string,
terminationDate string
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
WKT geometry,
gml_id string,
creationDate string,
namespace string,
lokaalID string,
relatieveHoogteligging integer,
LV_publicatiedatum timestamp,
tijdstipRegistratie timestamp,
inOnderzoek integer,
bgt_status string,
plus_status string,
bronhouder string,
"class" string,
begroeidTerreindeelOpTalud integer,
plus_fysiekVoorkomen string,
terminationDate string,
eindRegistratie string
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
