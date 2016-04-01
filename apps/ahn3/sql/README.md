#Attach and load AHN3 into MonetDB

1. Fill in the configs for the monetdb and ahn3.
```
vim geodan-collaboration/configs/monetdb.cfg

vim geodan-collaboration/configs/ahn3.cfg
```

2. Generate the DDLs files and follow the outputed instructions.
```
./gen_load_data.sh
```
