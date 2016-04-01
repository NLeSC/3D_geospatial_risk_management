--create procedure lidarexport(tname string, fname string, format string) external name lidar.export;
call lidarexport('result_4', '/scratch/goncalve/NLeSC/geodan-collaboration/apps/bgt/queries/result_4.las', 'x,y,z');
