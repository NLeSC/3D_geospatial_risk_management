#Installation notes for LiDAR libraries.

1. LASzip 2.1.0 is the one used on our experiments. To install follow the following steps:
```
wget http://download.osgeo.org/laszip/laszip-2.1.0.tar.gz
tar -xzf laszip-2.1.0.tar.gz
cd laszip-2.1.0
./configure --prefix=`pwd`
make -j
make -j install
export LASZIP_HOME=`pwd`
export LASZIP_LIBRARY=$LASZIP_HOME/lib
export LASZIP_INCLUDE_DIR=$LASZIP_HOME/include

```


2. Boost 1.55.0 is the version used on our work. A light pre-compiled version can be rquested from NLeSC. Once installed do the following:
```
cd boost_1_55_0
export BOOST_HOME=`pwd`
export BOOST_ROOT=$BOOST_HOME
```

3. LibLAS 1.7.0 is the one used on our work. To install follow the following steps:
```
wget http://download.osgeo.org/liblas/libLAS-1.7.0.tar.gz
tar -xzf libLAS-1.7.0.tar.gz
cd libLAS-1.7.0

export LIBLAS_HOME=`pwd`
export CMAKE_MODULE_PATH=$LASZIP_HOME:${CMAKE_MODULE_PATH}
export LD_RUN_PATH=$BOOST_HOME/lib:$LASZIP_HOME/lib:$LIBLAS_HOME/lib:$LD_RUN_PATH
export LD_LIBRARY_PATH=$BOOST_HOME/lib:$LASZIP_HOME/lib:$LIBLAS_HOME/lib:$LD_LIBRAYR_PATH
export LIBRARY_PATH=$BOOST_HOME/lib:$LASZIP_HOME/lib:$LIBLAS_HOME/lib:$LIBRARY_PATH

export LDFLAGS="${LDFLAGS} -L$LASZIP_HOME/lib -L$BOOST_HOME/lib"

mkdir makefiles
cd makefiles
cmake  -DCMAKE_FIND_ROOT_PATH=$LASZIP_HOME -DWITH_LASZIP=ON -DCMAKE_INSTALL_PREFIX=$LIBLAS_HOME -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../
make -j
make -j install
```

4. Set the paths to their installation (liblas_home, laszip_home, and boost_home) in monetdb.cfg.
```
cd 3D_geospatial_risk_management/configs
vim monetdb.cfg
```
