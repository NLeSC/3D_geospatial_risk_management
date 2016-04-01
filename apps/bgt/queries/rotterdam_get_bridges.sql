-- #Get everything in the area of rotterdam which is classified
-- #drop table result_2;
--create table result_2 as select b."L1" as bgt_type, b.gml_id, a.x, a.y, a.z from rotterdam b, ahn3 a where a.x between st_xmin(st_envelope(b.kmlgeometry)) and st_xmax(st_envelope(b.kmlgeometry)) and y between st_ymin(st_envelope(b.kmlgeometry)) and st_ymax(st_envelope(b.kmlgeometry)) with data;

-- #Get everything in the area of rotterdam which is classified
-- #remove false positives
--drop table result_3;
--create table result_3 as select b."L1" as bgt_type, b.gml_id, a.x, a.y, a.z from rotterdam b, ahn3 a where a.x between st_xmin(st_envelope(b.kmlgeometry)) and st_xmax(st_envelope(b.kmlgeometry)) and y between st_ymin(st_envelope(b.kmlgeometry)) and st_ymax(st_envelope(b.kmlgeometry)) and contains(b.kmlgeometry, x, y) with data;

-- #Get only bgt_bridgeconstructionelement in the area of rotterdam
-- #remove false positives and speci
drop table result_4;
create table result_4 as select b."L1" as bgt_type, b.gml_id, a.x, a.y, a.z from rotterdam b, ahn3 a where b."L1" like 'bgt_bridgeconstructionelement' and a.x between st_xmin(st_envelope(b.kmlgeometry)) and st_xmax(st_envelope(b.kmlgeometry)) and y between st_ymin(st_envelope(b.kmlgeometry)) and st_ymax(st_envelope(b.kmlgeometry)) and contains(b.kmlgeometry, x, y) with data;
