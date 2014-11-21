function [image] = vanrhijncorrection(xkm,ykm,im,height)
%
%Function that corrects an OMTI image for the van Rhijn effect as well as
%atmospheric extinction, following the paper by Kubota et al., 2001
%(Characteristics of medium- and large-scale TIDs over Japan derived from
%OI 630-nm nightglow observation)

%Correcting for van rhijn effect:
% display('Correcting for van Rhijn')
RE=6370;

r=sqrt(xkm.^2 + ykm.^2);
%where is r smallest (where's Resolute Bay)
[value, index] = min(reshape(r, numel(r), 1));
[i,j] = ind2sub(size(r), index);

%what is the value of image here?
%Icenter = im(i,j);

%zenith angle
theta = atan(r./height);
%correction factor for van Rhijn
V = (1 - (RE/(RE+height))^2 .* (sin(theta)).^2).^(-1/2);
%finding the values that are not NaN
nonanind1=find(~isnan(V));

image=im;
image(nonanind1) = im(nonanind1)./V(nonanind1);

image2=image;

%Correction for atmospheric extinction
% display('Correcting for atmospheric extinction')
F = (cos(theta) + 0.15 .* (93.885-theta.*180/pi).^(-1.253)).^(-1);

factor = 10.^(-0.4*0.4.*F);
nonanind2=find(~isnan(factor));

image(nonanind2) = image(nonanind2)./factor(nonanind2);

end