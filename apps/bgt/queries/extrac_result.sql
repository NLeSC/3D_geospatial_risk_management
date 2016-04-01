--create procedure lidarexport(tname string, fname string, format string) external name lidar.export;
call lidarexport('result_4', '/scratch/goncalve/NLeSC/3D_geospatial_risk_management/apps/bgt/queries/result_4.las', 'x,y,z');
