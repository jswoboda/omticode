function [xkm,ykm] = getcoords(latfile,lonfile,height,omtishape) 


% RISR position
lon0=-94.90576;
lat0=74.72955;  
h0=145;

height = height*1e3;
% height = h0;
latlongheight = [lat0,lon0,h0];

lat = load(latfile);
lat=reshape(lat,omtishape(1),omtishape(2));
lat=imrotate(lat,270);

lon = load(lonfile);
lon=reshape(lon,256,256);
lon=imrotate(lon,270);

nanpoint = find(lat<-998 | lon <-998);
lat(nanpoint) = NaN;
lon(nanpoint) = NaN;
lon = lon-360;
hmat = height*ones(size(lon));
hmat(nanpoint) = NaN;
ECEF = wgs2ecef([lat(:),lon(:),hmat(:)]);
latlongheightmat = repmat(latlongheight,size(ECEF,2),1)';
ENU = ecef2enu(ECEF,latlongheightmat);
% enu is in meters
xkm = reshape(ENU(1,:),omtishape)/1e3;
ykm = reshape(ENU(2,:),omtishape)/1e3;