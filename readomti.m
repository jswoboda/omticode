function outdata = readomti(filename)
% readomti.m
% By John Swoboda
% This function will read the .abs data
fid=fopen(filename, 'rb');
fseek(fid,8,'bof');% seek ahead to remove the header
% use uint16, seems like it works
curdata=fread(fid,[256,256],'uint16=>uint16'); 
fclose(fid);
% Do a bishift, can also be divide by 4 and a floor command if double.
curdata = bitshift(curdata,-2);
% Do a leftright flip and then a 270 deg rotation
outdata =imrotate(fliplr(double(curdata)),270);
