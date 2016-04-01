Load BGT into MonetDB
=====================

#Convert GML to CSV new style
```
for f in *.gml; do ogr2ogr  -f csv  -lco GEOMETRY=AS_WKT $f.csv $f; done
```

#Convert GML to CSV

1. Copy the gml files into the directory scripts/extract.

2. Convert all the gml files in the directory extract to shape files.
```
./gml2shp.sh
```

3. Convert all the shp files in the directory outShp to csv files.
```
./gml2shp.sh
```

#Data loading

1. If monetDB is not installed, please follow the instructions in the [MonetDB README] (geodan-collaboration/docs/monetdb/README.md) and start a MonetDB mserver.

2. Create tables.
```
./geodan-collaboration/apps/monetdb/scripts/mclient optimized sql < sql/create_tables.sql
``` 

3. Load data.
```
./geodan-collaboration/apps/monetdb/scripts/mclient optimized sql < sql/load_data.sql
``` 

