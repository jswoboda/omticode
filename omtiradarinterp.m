function omtiradarinterp(omtidir,radarfilename,coordfolder,outdirbase)
% This function will create a directory of images and make a video. These
% images will have an omti image with a contour plot of radar parameters
% over it.
%% Location of data
%CHANGE
% omtidir = '/home/swoboj/DATA/20120220/omti';
% 
% %CHANGE
% radardir = '/home/swoboj/Documents/MATLAB/RISR.Allsky.Analysis/MATLABCode';
% radarfile = '20120219.001_lp_2min.h5';%20120219.001_lp_5min.h5
% 
% radarfilename = fullfile(radardir,radarfile);
% % coordinates
% coordfolder = fullfile(pwd,'coordfolder');
% %output
% outdirbase = '/home/swoboj/DATA/20120220/omtiradarfusioninterp2';
%% Set Time and Altitude
% Pick start and end times
starttime = [2012,02,20,05,00,00];
StartTime = datenum(starttime);
endtime = [2012,02,20,08,00,00];
EndTime = datenum(endtime);
% pick alt
plasmaAlt = 340; % in km

%% Set Info associated with parameters
choices = {1,'Ne',1,'Ne (m^-3)';1,'Ti',2,'Ti (K)';...
    2,'Ne',1,'Ne (m^-3)';2,'Ti',2,'Ti (K)';...
    1,'Te',2,'Te (K)';2,'Te',2,'Te (K)';};
cvecshell = {[5e10,4e11],[0,3e3]};
omtivec = {'C61',558;'C62',630;'C64',777};
omtiheight = [140,260,500]; % I don't think the 777nm light is the right height
omtisize = [256,256];
radarsize = [64,64];
%Interpolate
xout = linspace(-400,400,radarsize(2));
yout = linspace(-200,550,radarsize(1));
[Xout,Yout] = meshgrid(xout,yout);
Zout = plasmaAlt*ones(size(Xout));
datetime30s = 1/2880;
%% Color set up
pmin = 200;
pmax = 1000;
[co_row,~]=size(gray);
cm1 = gray;
cm2 = jet;

for ich = 1:size(choices,1)
    
    % Pick wavelength
    curomti = choices{ich,1};
    omtype = omtivec{curomti,1};%C61: 558nm, C62:630nm, C64:777nm,C66: Sodium
    omtiWL = omtivec{curomti,2};
    omtih = omtiheight(curomti);
    curcvec = cvecshell{choices{ich,3}};
    cbarlabel = choices{ich,4};
    latfile = fullfile(coordfolder,['omti_glat_',num2str(omtih),'km.dat']);
    lonfile = fullfile(coordfolder,['omti_glon_',num2str(omtih),'km.dat']);

    [xkm,ykm] = getcoords(latfile,lonfile,omtih,omtisize); 

    omtilist = dir(fullfile(omtidir,['*',omtype,'*.abs']));
    omtitimes = zeros(1,length(omtilist));

    for iomti = 1:length(omtilist)
        omtitimes(iomti) = datenum(omtilist(iomti).name(5:16),'yymmddHHMMSS');
    end


    % Pick parameter
    param =  choices{ich,2};
    % make the out directory
    outdir = fullfile(outdirbase,[param,omtype]);
    if ~exist(outdir,'dir')
        mkdir(outdir);
    end
    %% Get radar data
    [rData, Az, El, Alt, Range, T1, T2, mtime, utime, timefortitle] =...
        loadData(StartTime,EndTime,radarfilename,param);
    
    [numAlt,numBeam] = size(Alt);
    Azmat = repmat(Az,numAlt,1);
    Elmat = repmat(El,numAlt,1);
    % remove nans from range
    rngkeep = ~isnan(Range(:));
    Range = Range(rngkeep);
    Azmat = Azmat(rngkeep);
    Elmat = Elmat(rngkeep);
    
     fprintf('Data set %d of %d\n',ich,size(choices,1))
    %% main loop
    for iradar=(T1:T2)  
        % Find omti in 
        rDataIndex = iradar-(T1-1);    
        timelog = (omtitimes>=mtime(1,iradar))&((omtitimes+datetime30s)<mtime(2,iradar));
        if ~any(timelog)
            continue;
        end
        listcell = {omtilist(timelog).name};
        omtimesred = omtitimes(timelog);
        %omtiout = interpomti( listcell,omtidir,omtih,xkm,ykm,Xout,Yout );
        % interpolate the radar data
        [xrad,yrad,zrad] = sphere2cart(Range(:),Azmat(:)*pi/180,Elmat(:)*pi/180);

        rDatacur = squeeze(rData(:,:,rDataIndex));
        
        F = scatteredInterpolant(xrad(:),yrad(:),zrad(:),rDatacur(rngkeep),'natural','none');
        rDataout = reshape(F(Xout(:),Yout(:),Zout(:)),size(Xout));
        
        
        radartimebeg = datestr(mtime(1,iradar),'HH:MM:SS');
        radartimeend = datestr(mtime(2,iradar),'HH:MM:SS');
        curdate = datestr(mtime(1,iradar),'mm/dd/yyyy');
        fprintf('\tRadar time %d of %d\n',rDataIndex,T2-(T1-1))
        for ivec = 1:length(listcell)
            fprintf('\t\t OMTI %d of %d\n',ivec,length(listcell))
            file = fullfile(omtidir,listcell{ivec});
            im = readomti(file);
            % interpolate image
            [image] = vanrhijncorrection(xkm,ykm,im,omtih);

            hcur = figure('position',[520   484   800   600]);
            colormap(gray);
            
            h1 = pcolor(xkm,ykm,image);
            caxis([pmin,pmax])
            Cdatacur = h1.CData;
            Cdatanew = zeros([size(Cdatacur),3]);
            % freeze colors
            idx = ceil( (double(Cdatacur) -pmin) / (pmax-pmin) *co_row);
            idx(idx<1) = 1;
            idx(idx>co_row)=co_row;
            shading flat
            for i = 1:3
                C = cm1(idx,i);
                C = reshape(C,size(Cdatacur));
                Cdatanew(:,:,i) = C;
            end
            h1.CData =Cdatanew;
          
            set(hcur,'renderer','zbuffer')
           
            hold on            
            
            % plot radar data
            colormap(cm2);
            [~,h2] = contour(xout,yout,rDataout,10,'LineWidth',1.6);
            axis([min(xout) max(xout) min(yout) max(yout)])
            
            
            cbarhandle = colorbar('location','WestOutside');
            set(get(cbarhandle,'xlabel'),'String',cbarlabel);
            caxis(curcvec);
            
            
            xlabel('km east of Resolute Bay')
            ylabel('km north of Resolute Bay')
            
            [~,curomtiname,~] = fileparts(listcell{ivec});
            % omti time strings
            curtime = datestr(omtimesred(ivec),'yymmddHHMMSS');
            curtimestr = datestr(omtimesred(ivec),'HH:MM:SS');
            curtimeend = datestr(omtimesred(ivec)+datetime30s,'HH:MM:SS');
            
            
            % title
            title({['OMTI w/ RISR Radar Points -- Plasma Parameter: ',...
                param ' @ ' num2str(plasmaAlt) ' km'];...
                ['Date: ', curdate, ' - Radar: ', radartimebeg,...
                ' - ', radartimeend,' OMTI: ',curtimestr,' - ',...
                curtimeend];[]},'fontsize',10,'fontweight','bold');

            ylim=get(gca,'YLim');
            xlim=get(gca,'XLim');
            xloc = xlim(1)+.7*(xlim(2)-xlim(1));
            yloc = ylim(1)+.1*(ylim(2)-ylim(1));
            textb = text(xloc,yloc,['OMTI ' num2str(omtiWL) ' nm '],...
                'fontsize',12,'HorizontalAlignment','center','VerticalAlignment',...
                'bottom','fontweight','light','color','w'); 
            figtitle = [param,omtype,num2str(plasmaAlt),'km',curtime];
            set(hcur,'Position',[520   666   800   600],'Color',[1,1,1])
            saveas(hcur,fullfile(outdir,figtitle),'fig');
            saveas(hcur,fullfile(outdir,figtitle),'png');
            close(hcur)
        end

    end
    videoname = [param,omtype,num2str(plasmaAlt),'km.avi'];
    try
        
        figdir2movie(outdir,videoname);
    catch
        disp([videoname,' was not created.'])
    end
end