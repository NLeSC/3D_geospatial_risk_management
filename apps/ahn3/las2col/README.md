#las2col

1. Dowload las2col
```
git clone https://github.com/NLeSC/pointcloud-benchmark

cd pointcloud-benchmark/lasnlesc
```

2. To install follow the instructions in the [INSTALL document](https://github.com/NLeSC/pointcloud-benchmark/blob/master/lasnlesc/INSTALL).

3. Update [ahn3.cfg](https://github.com/NLeSC/3D_geospatial_risk_management/blob/master/configs/ahn3.cfg) with the path where lasnlesc is located, as an example:
```
ahn3_data_dir="/scratch/goncalve/data/geo_data/ahn3/tileslaz"
lasnlec_dir="/scratch/goncalve/NLeSC/pointcloud-benchmark/lasnlesc"
```

4. To generate the data.
```
./run.sh
```

5. To load the data follow the instructions located [here](https://github.com/NLeSC/3D_geospatial_risk_management/blob/master/apps/ahn3/sql/README.md).





