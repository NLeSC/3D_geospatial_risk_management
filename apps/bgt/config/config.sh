export LASTOOLS_HOME=/scratch/goncalve/NLeSc/NLeSC_Collaboration/packets/lastools
export LIBLAS_HOME=/scratch/goncalve/NLeSc/NLeSC_Collaboration/packets/libLAS/libLAS-1.7.0
export LASZIP_HOME=/scratch/goncalve/NLeSc/NLeSC_Collaboration/packets/lasZIP/laszip-2.1.0
export BOOST_HOME=/scratch/goncalve/sandbox/boost/boost_1_55_0
export GDAL_HOME=/scratch/goncalve/sandbox/gdal-trunk

export LD_LIBRARY_PATH=$LASTOOLS_HOME/lib:$BOOST_HOME/lib:$LIBLAS_HOME/lib:$LASZIP_HOME/lib:$GDAL_HOME/build/lib:$LD_LIBRARY_PATH
export PATH=$LASTOOLS_HOME/bin:$GDAL_HOME/bin:$PATH
export PYTHONPATH=$LIBLAS_HOME/python:$GDAL_HOME/lib64/python2.7/site-packages:$GDAL_HOME/swig/python/scripts:$GDAL_HOME/swig/python:$LIBLAS_HOME/lib/python2.7/site-packages:$GDAL_HOME/build/lib64/python2.7/site-packages:${PYTHONPATH}
export C_INCLUDE_PATH=/usr/include/libxml2:$C_INCLUDE_PATH

