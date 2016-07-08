-- A26147564D850222EE0532B0B5B0AACAA
-- 2014-06-12
-- NL.IMGeo
-- G1711.5c60ee8a999f471d8b53a73ccc864d3a
-- -1
-- 2015-09-11T19:33:02.000
-- 0
-- 2014-11-14T11:45:58.000
-- bestaand
-- G1711
-- "<Polygon><outerBoundaryIs><LinearRing><coordinates>5.85405161581606 51.0715382966137 5.85404741870535 51.0715366505594 5.85402137103233 51.0715793538906 5.85398633077401 51.0716427769097 5.85396559199871 51.0716799935981 5.85396455519123 51.0716818674658 5.85396346441411 51.071684047174 5.8539679503407 51.0716860336477 5.85405161581606 51.0715382966137</coordinates></LinearRing></outerBoundaryIs></Polygon>"

drop table bgt_tunnelpart;

create table bgt_tunnelpart (gml_id string, createDa date, namespace string, lokaalID string, relatieveH integer, LV_publica timestamp, inOnderzoe integer, tijdstipRe timestamp, bgt_status string, bronhouder string, kmlgeometry string); 

COPY INTO bgt_tunnelpart FROM ('//data24r1/goncalve/data/geo_data/bgt/sql/test.csv') USING DELIMITERS ',','\n';

select * from bgt_tunnelpart;
