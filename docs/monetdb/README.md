How to install MonetDB
======================

1. Install yum dependencies
```
yum install pcre pcre-devel ant bison bison-devel openssl openssl-devel gettext-devel libtool hg readline readline-devel unixODBC unixODBC-devel
```

2. Add the file .monetdb into your home directory with the following content:
```
user=monetdb
password=monetdb
```

3. Clone monetdb.
```
mkdir ~/MonetDB/
cd MonetDB
hg clone http://dev.monetdb.org/hg/MonetDB current
```

4. To apply the changes to MonetDB you should do the following:
```
#Edit your ~/MonetDB/current/.hg/hgrc and add the following line:
[ui]
username = Your Name <your@mail>
```

5. Fill in the configuration monetdb configuration file.
```
cd geodan-collaboration/configs
vim monetdb.cfg
```

6. Install monetdb.
```
#To know the installation options run:
./geodan-collaboration/apps/monetdb/scripts/monet
```

7. To start mserver.
```
#To know mserver options run:
./geodan-collaboration/apps/monetdb/scripts/mserver
```

8. To start a mclient.
```
#To know mmclient options run:
./geodan-collaboration/apps/monetdb/scripts/mclient

#Example: to execute a SQL file
./geodan-collaboration/apps/monetdb/scripts/mclient debug sql < your_file.sql
```
