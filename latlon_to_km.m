function [xkm,ykm] = latlon_to_km(latitude,longitude)

%Function that unwarps OMTI data, dimensions are set up for 2012 data!
%
%INPUT: latitude array
%       longitude array
%
%OUTPUT: 
%       xkm - array of km east of Resolute Bay for each pixel
%       ykm - array of km north of Resolute Bay for each pixel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lat=latitude;
lon=longitude;

%%Geographic latitude and longitude of Resolute bay
  lon0=-(94+54/60+16/3600);
  lat0=74+43/60+46/3600;  
 RE=6370;
 
        xkm= (lon-lon0)*(pi*RE).*(sind(90-lat))/180;
        ykm= (lat-lat0)*(pi*RE)/180;    