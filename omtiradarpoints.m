function omtiradarpoints(omtidir,radarfilename,outdirbase)
% This function will create a directory of images that are the original
% omti images without interpolation as seen from the fish eye lens. The
% radar data is then overlayed as color points that reflect the magnitude
% of the parameter being plotted.
%% Set Parameters
% Pick start and end times
starttime = [2012,02,20,02,00,00];
StartTime = datenum(starttime);
endtime = [2012,02,20,08,00,00];
EndTime = datenum(endtime);
% pick alt
plasmaAlt = 340; % in km

choices = {1,'Ne';1,'Ti';2,'Ne';2,'Ti';1,'Te';2,'Te';};

omtivec = {'C61',558;'C62',630;'C64',777};
for ich = 1:size(choices,1);
    
    % Pick wavelength
    curomti = choices{ich,1};
    omtype = omtivec{curomti,1};%C61: 558nm, C62:630nm, C64:777nm,C66: Sodium
    omtiWL = omtivec{curomti,2};
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
    [rData, Az, El, Alt, Range, T1, T2, mtime, utime, timefortitle] = loadData(StartTime,EndTime,radarfilename,param);

    [numAlt,numBeam] = size(Alt);


    altInd = zeros(1,numBeam);
    for i = 1:numBeam
        [~,altInd(1,i)] = min(abs(minus(Alt(:,i),plasmaAlt)));
    end

    rDataNew = zeros(1,numBeam);

    datetime30s = 1/2880;

    %% main loop
    for iradar=(T1:T2)  
        % Find omti in 
        rDataIndex = iradar-(T1-1);    
        timelog = (omtitimes>=mtime(1,iradar))&(omtitimes<mtime(2,iradar));
        listcell = {omtilist(timelog).name};
        omtimesred = omtitimes(timelog);
        hvec = plotOMTI(omtidir,listcell);

        for ivec = 1:length(hvec)
            figure(hvec(ivec));
            
            freezeColors
            [~,curomtiname,~] = fileparts(listcell{ivec});
            curtime = datestr(omtimesred(ivec),'yymmddHHMMSS');
            curtimestr = datestr(omtimesred(ivec),'HH:MM:SS');
            curtimeend = datestr(omtimesred(ivec)+datetime30s,'HH:MM:SS');
            for i = 1:numBeam
                rDataNew(i) = rData(altInd(i),i,rDataIndex);
            end
            ElAzPlot = PlotElAz(Az,El,rDataNew,param);
            axis([0 233 0 230])
            stimeHour = num2str(floor(timefortitle(1,iradar)));
            stimeMinute = num2str((floor(((timefortitle(1,iradar))-(floor(timefortitle(1,iradar))))*60)));
            if (str2num(stimeMinute)<10)
                stimeMinute = ['0' stimeMinute];
            end
            etimeHour = num2str(floor(timefortitle(2,iradar)));
            etimeMinute = num2str((floor(((timefortitle(2,iradar))-(floor(timefortitle(2,iradar))))*60)));
            if (str2num(etimeMinute)<10)
                etimeMinute = ['0' etimeMinute];
            end
            %titleh = title({['OMTI w/ RISR Radar Points -- Plasma Parameter: ' param ' @ ' num2str(plasmaAlt) ' km'];['Date:' num2str(starttime(2)) '/' num2str(starttime(3)) '/' num2str(starttime(1)) ' -- Time (UT hours): ' stimeHour ':' stimeMinute ' to ' etimeHour ':' etimeMinute];[]},'fontsize',10,'fontweight','bold');
            title({['OMTI w/ RISR Radar Points -- Plasma Parameter: ',...
                param ' @ ' num2str(plasmaAlt) ' km'];...
                ['Date:' num2str(starttime(2)) '/' num2str(starttime(3)) ...
                '/' num2str(starttime(1)) ' - Radar: ' stimeHour ':' ...
                stimeMinute ' - ' etimeHour ':' etimeMinute,' OMTI: ',curtimestr,' - ',...
                curtimeend];[]},'fontsize',10,'fontweight','bold');

            ylim=get(gca,'YLim');
            xlim=get(gca,'XLim');
            textb = text(xlim(2)*.5,.05*ylim(2),['OMTI ' num2str(omtiWL) ' nm (R)'],'fontsize',12,'HorizontalAlignment','center','VerticalAlignment','bottom','fontweight','light','color','w'); 
            figtitle = [param,omtype,num2str(plasmaAlt),'km',curtime];
            set(hvec(ivec),'Position',[520   666   800   600],'Color',[1,1,1])
            saveas(hvec(ivec),fullfile(outdir,figtitle),'fig');
            saveas(hvec(ivec),fullfile(outdir,figtitle),'png');
            close(hvec(ivec))
        end

    end
    videoname = [param,omtype,num2str(plasmaAlt),'km.avi'];
    figdir2movie(outdir,videoname);
end