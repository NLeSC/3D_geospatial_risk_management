#Attach and load AHN3 into MonetDB

1. Fill in the configs for the monetdb and ahn3.
```
vim 3D_geospatial_risk_management/configs/monetdb.cfg

vim 3D_geospatial_risk_management/configs/ahn3.cfg
```

2. Generate the DDLs files and follow the outputed instructions.
```
./gen_load_data.sh
```
