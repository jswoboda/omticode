function [rData,az,el,Altitude,Range,T1,T2,mtime,utime,timeunits] = loadData(StartTime,EndTime,file_name,parameter)
%loadData.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Description:
%Reads in data from specified file, and for specified time interval, and
%returns plasma parameters used in various types of plots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SYNTAX:
%   [rData,az,el,Altitude] =
%   loadData(StartTime,EndTime,file_name,parameter)
%
%example:
%[rData,az,el,Altitude]=readdata(StartTime,EndTime,file_name,'Ne');
%
%Inputs:
%     StartTime   - Is in the format of serial date number, given by e.g. 
%                   StartTime = datenum(2012,01,24,11,03,00); for 24
%                   January 2012, at 11:03:00
%     EndTime     - Is in the format of serial date number, given by e.g. 
%                   EndTime = datenum(2012,01,24,11,05,00); for 24
%                   January 2012, at 11:05:00
%     file_name   - is the h5-file with uncalibrated data, such as
%                   file_name =
%                   'E:/20120122.001_lp_2min-Ne.h5';
%     parameter   - The parameter that you want to read. The options are:
%                   'Ne'    - electron density
%                   'dNe'   - error on fitted electron density
%                   'Te'    - electron temperature
%                   'dTe'   - error on electron temperature
%                   'Ti'    - ion temperature
%                   'dTi'   - error on ion temperature
%
%   OUTPUT:
% [rData,az,el,Altitude]
%     rData        - This is a 3 dimensional array,[NxMxT] dimension N is 
%                   range, dimension M is beams, and dimension T is 
%                   time.
%     az          - A 1xM array that holds the azimuth angle for each of 
%                   the beams.
%     el          - A 1xM array that holds the elevation angle for each of 
%                   the beams.
%     Altitude    - A 1xN array that holds the altitude values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load radar file.
%%Reading the data from the h5 file
Range = hdf5read(file_name,'/FittedParams/Range')/1000.;
Altitude = hdf5read(file_name,'/FittedParams/Altitude')/1000.;

if (strcmp(parameter,'Ne') == 1)
    rData = hdf5read(file_name,'/FittedParams/Ne');
elseif (strcmp(parameter,'dNe') == 1)
    rData = hdf5read(file_name,'/FittedParams/dNe');
elseif (strcmp(parameter,'Te') == 1)
    Fits = hdf5read(file_name,'/FittedParams/Fits');
    Te=Fits(2,end,:,:,:);
    rData=reshape(Te,size(Fits,3),size(Fits,4),size(Fits,5));
elseif (strcmp(parameter,'Ti') == 1)
    Fits = hdf5read(file_name,'/FittedParams/Fits');
    Ti=Fits(2,1,:,:,:);
    rData=reshape(Ti,size(Fits,3),size(Fits,4),size(Fits,5));
elseif (strcmp(parameter,'dTe') == 1)
    FitsError = hdf5read(file_name,'/FittedParams/Errors');
    dTe=FitsError(2,2,:,:,:);
    rData=reshape(dTe,size(FitsError,3),size(FitsError,4),size(FitsError,5));
elseif (strcmp(parameter,'dTi') == 1)
    FitsError = hdf5read(file_name,'/FittedParams/Errors');
    dTi=FitsError(2,1,:,:,:);
    rData=reshape(dTi,size(FitsError,3),size(FitsError,4),size(FitsError,5));
else
    error('provide correct parameter (e.g. ''Ne'')')
end
utime = hdf5read(file_name,'/Time/UnixTime');
bco   = hdf5read(file_name,'BeamCodes');
timeunits = hdf5read(file_name,'/Time/dtime');
%%
%Converting the time from unix time to matlab time
l=size(utime);
mtime = zeros(l(1),l(2));
for i1 = 1:l(1),
for i2 = 1:l(2),
mtime(i1,i2) = datenum([1970 1 1 0 0 double(utime(i1,i2))]); 
end
end
%% Align Start and End times to corresponding mtime boundaries.
T1 = find(mtime(1,:) >= StartTime, 1, 'first');
T2 = find(mtime(2,:) >= EndTime,   1, 'first');

rData=rData(:,:,T1:T2);
 %Making all NaNs 0
  rData(isnan(rData))=1;

%% Azimuth and elevation in degrees
az = bco(2,:);
el = bco(3,:);