% analyze sleep patterns (use pre-analyzed mat-files) and export to excel
% updated 1/16/2025 by YP
%%
% ------------folder name first-------------
%folder = 'D:/Downloads/K168-2_02';
startMin=0;             %start minute of processed data, see below for auto-detection
lightseting=[7,19];     %light on and off time
% data to calculate
ztSleep = zeros(24,3);      %[wake, NREMs, REMs] in zeitgeber time (per h)
dur_perh = zeros(1,3);      %[wake, NREMS, REMS] per hour - original order
dur_24h = zeros(3,3);       %total/light/dark [wake, NREMs, REMs] in 24h
bouts = zeros(2,3);     %cumulative [bout-number;bout-duration] for each wake/NREM/REM
transit=zeros(1,5);         %transition number: W-N/N-R/N-W/R-N/R-W
%power_sleep = zeros(201,6);  %power in NREMS (0-25Hz), [original, relative, relative-log2] for NREM/REM

folder2 = fullfile(folder, '*.mat');
list = dir(folder2);
list = list(~[list.isdir]);
%sort filenames by name (default is by date-modifed)
[~,idx] = natsortfiles({list.name});
list = list(idx);

% Display the number of .mat files
numFiles = length(list);
disp(['Number of .mat files: ', num2str(numFiles)]);

% Extract time indices from filenames using regular expressions
timeIndices = zeros(numFiles, 1);
for i = 1:numFiles
    % Regular expression to extract numeric part between '_m' and '-'
    match = regexp(list(i).name, '_m(\d+)-', 'tokens', 'once');
    if ~isempty(match)
        timeIndices(i) = str2double(match{1});
    else
        error('Filename format does not match expected pattern: %s', list(i).name);
    end
end

% Sort files based on extracted time indices
[~, idx] = sort(timeIndices);
list = list(idx);

% Get the start min using the first filename (format: eeg1_mxx-xxx.mat)
if ~isempty(list)
    startMin = timeIndices(1);
end
disp(['Start Min(min): ', num2str(startMin)]);

% Display the sorted list of files
disp('Sorted list of files:');
for i = 1:numFiles
    disp(list(i).name);
end
%%
fileNumber=0;
totalHour=0;
bufferNREM=[];
bufferREM=[];
bufferWake=[];
bufferPower=[];
bufferState=[];
%st=204;            %start time in minute
for i=1:length(list)
    fname=list(i).name;
    if contains(fname,'.mat')
        subfname=fullfile(folder,fname);
        %NOTE: sleepData saved in mat-file is cumlative, not per hour
        load(subfname,'state','specDat','info');
        sLen1=length(state);
        sLen2=size(specDat.p,1);
        sLen=min(sLen2,sLen1);
        state=state(1:sLen);
        specDat.p=specDat.p(1:sLen,:);
        bufferState=[bufferState;state];
        bufferPower=[bufferPower;specDat.p(:,1:201)];
        sleepData=profileSleep(state,info);
        epoch0=sleepData.wakeEpoch;
        epoch0(:,5)=fileNumber+1;
        bufferWake=[bufferWake;epoch0];
        epoch1=sleepData.nremEpoch;
        epoch1(:,5)=fileNumber+1;
        bufferNREM=[bufferNREM;epoch1];
        epoch2=sleepData.remEpoch;
        if ~isempty(sleepData.remEpoch)
            idx2=sleepData.remEpoch(:,4)>=10;
            epoch2=sleepData.remEpoch(idx2,:);
            epoch2(:,5)=fileNumber+1;
        else
            epoch2=[];
        end
        bufferREM=[bufferREM;epoch2];
        fileNumber=fileNumber+1;
        totalHour=totalHour+round(range(info.procWindow)/60);

        dur_perh(fileNumber,:)=sleepData.dur;
    end
end
%totalHour=fileNumber;
disp(['Total files = ',num2str(fileNumber),' Total hours = ', num2str(totalHour)]);
%%
%convert to zeitgeber time
if ~isfield(info,'amplifier')
    info.amplifier='EDF';
end
ztFlag=0;
if contains(info.amplifier,'Neuralynx')
    stDate=getNLXStartTime(info.FileInfo);
    if ~isempty(stDate)
        ztFlag=1;
    end
elseif contains(info.amplifier,'TDT')
    if isfield(info.FileInfo,'Start')
        stDate=info.FileInfo.Start;
        ztFlag=1;
    end
elseif contains(info.amplifier,'Intan')
    if isfield(info.FileInfo,'Start')
        stDate=info.FileInfo.Start;
        ztFlag=1;
    else
        if isfield(info,'fileList')
            stDate=getIntanStartTime(info.fileList{1});
            ztFlag=1;
        end
    end
elseif contains(info.amplifier,'EDF')
    stDate=getEDFStartTime(info.FileInfo);
    ztFlag=1;
end
if ztFlag
    hh=str2num(datestr(stDate,'HH'));
    mm=str2num(datestr(stDate,'MM'));
    stHH=round(hh+(mm+startMin)/60);
    t=(1:totalHour)+stHH;
    lightmap=zeros(1,totalHour);
    lightmap(mod(t,24)>lightseting(1) & mod(t,24)<=lightseting(2))=1;
    daynum=ceil(totalHour/24);
    %calculate the total durations of wake/NREMS/REMS
    dur_24h(1,:)=sum(dur_perh)/daynum;
    dur_24h(2,:)=sum(dur_perh(lightmap==1,:))/daynum;
    dur_24h(3,:)=sum(dur_perh(lightmap==0,:))/daynum;
    for i=1:24
        idx=find(mod(t,24)==(mod(lightseting(1)+i,24)));
        ztSleep(i,:)=mean(dur_perh(idx,:),1);
    end
else
    disp('cannot convert to zeitgeber time');
end

for i=1:totalHour
    k=bufferWake(:,5)==i;
    bufferWake(k,6)=lightmap(i);
    k=bufferNREM(:,5)==i;
    bufferNREM(k,6)=lightmap(i);
    k=bufferREM(:,5)==i;
    bufferREM(k,6)=lightmap(i);
end

%calculate bouts and bout durations
bouts=zeros(3,3);   %row: 24h,light,dark, col wake/nrem/rem
bout_dur=zeros(3,3);   %row: 24h,light,dark, col wake/nrem/rem

bouts(1,1)=size(bufferWake,1)/daynum;
bouts(1,2)=size(bufferNREM,1)/daynum;
bouts(1,3)=size(bufferREM,1)/daynum;
if ztFlag
    k=find(bufferWake(:,6)==1);
    bouts(2,1)=length(k)/daynum;
    k=find(bufferWake(:,6)==0);
    bouts(3,1)=length(k)/daynum;
    k=find(bufferNREM(:,6)==1);
    bouts(2,2)=length(k)/daynum;
    k=find(bufferNREM(:,6)==0);
    bouts(3,2)=length(k)/daynum;
    k=find(bufferREM(:,6)==1);
    bouts(2,3)=length(k)/daynum;
    k=find(bufferREM(:,6)==0);
    bouts(3,3)=length(k)/daynum;
end

if ~isempty(bufferWake)
	bout_dur(1,1)=mean(bufferWake(:,4));
    if ztFlag
        k=(bufferWake(:,6)==1);
        bout_dur(2,1)=mean(bufferWake(k,4));
        k=(bufferWake(:,6)==0);
        bout_dur(3,1)=mean(bufferWake(k,4));
    end
else
	bout_dur(1,1)=nan;
end

if ~isempty(bufferNREM)
	bout_dur(1,2)=mean(bufferNREM(:,4));
    if ztFlag
        k=(bufferNREM(:,6)==1);
        bout_dur(2,2)=mean(bufferNREM(k,4));
        k=(bufferNREM(:,6)==0);
        bout_dur(3,2)=mean(bufferNREM(k,4));
    end
else
	bout_dur(1,2)=nan;
end

if ~isempty(bufferREM)
    bout_dur(1,3)=mean(bufferREM(:,4));
    if ztFlag
        k=(bufferREM(:,6)==1);
        bout_dur(2,3)=mean(bufferREM(k,4));
        k=(bufferREM(:,6)==0);
        bout_dur(3,3)=mean(bufferREM(k,4));
    end
else
    bout_dur(1,3)=nan;
end

%calculate the transitions among states
ds=bufferState(2:end)-bufferState(1:end-1);
ds=[0;ds];

%wake-to-NREMS
idx=find(ds==1 & bufferState==1);
transit(1)=length(idx);
%NREMS-REMS
idx=find(ds==1 & bufferState==2);
transit(2)=length(idx);
%NREMS-wake
idx=find(ds==-1 & bufferState==0);
transit(3)=length(idx);
%REMS-NREMS
idx=find(ds==-1 & bufferState==1);
transit(4)=length(idx);
%REMS-wake
idx=find(ds==-2 & bufferState==0);
transit(5)=length(idx);

%calculate power
pLen=size(specDat.p,2);
pLen=201;
power_sleep = zeros(pLen,6);  %power in NREMS (0-20Hz), [original, relative] for Wake/NREM/REM
pm0=mean(bufferPower);
%normalize to total power (0-50Hz)
powerMap=100*bufferPower./sum(pm0);
idx = (bufferState==0);
power_sleep(:,1)=mean(bufferPower(idx,:));
power_sleep(:,2)=mean(powerMap(idx,:));
%for NREM sleep
idx = (bufferState==1);
power_sleep(:,3)=mean(bufferPower(idx,:));
power_sleep(:,4)=mean(powerMap(idx,:));
%for REM sleep
idx = (bufferState==2);
power_sleep(:,5)=mean(bufferPower(idx,:));
power_sleep(:,6)=mean(powerMap(idx,:));
%%
%plot data--------duration per hour
figure;
tm=(1:totalHour)';
axes('position',[0.1,0.9,0.85,0.05]);
imagesc(lightmap);
colormap('gray');
set(gca,'xtick',[],'ytick',[]);
axes('position',[0.1,0.1,0.85,0.78]);
h=plot(tm,dur_perh,'.-');
set(h,'Markersize',12);
set(gca,'ylim',[-5,60+5],'xlim',[1-0.5,totalHour+0.5]);
legend({'wake','NREM','REM'});
xlabel('hour#');
ylabel('time(min)');
f1=fullfile(folder,'durations_hourly.png');
F=getframe(gcf);
imwrite(F.cdata,f1);
%ZT order
if ztFlag
    figure;
    zt=(1:24)';
    axes('position',[0.1,0.9,0.85,0.05]);
    ztlightmap=[ones(1,12),zeros(1,12)];
    imagesc(ztlightmap);
    colormap('gray');
    set(gca,'xtick',[],'ytick',[]);
    axes('position',[0.1,0.1,0.85,0.78]);
    h=plot(zt,ztSleep,'.-');
    set(h,'Markersize',12);
    set(gca,'ylim',[-5,60+5],'xlim',[1-0.5,24+0.5]);
    legend({'wake','NREM','REM'});
    xlabel('hour#');
    ylabel('time(min)');
end
%save plot
f1=fullfile(folder,'durations_ZT.png');
F=getframe(gcf);
imwrite(F.cdata,f1);
%plot data--------spectral information
fHz=linspace(specDat.fsRange(1),specDat.fsRange(2),size(power_sleep,1));
figure;
subplot(1,3,1);
plot(fHz,power_sleep(:,2));
title('EEG power in Wake'); 
ylabel('power');
xlabel('frequency (Hz)');
set(gca,'xlim',[0,15]);
subplot(1,3,2);
plot(fHz,power_sleep(:,4));
title('EEG power in NREM sleep'); 
ylabel('power');
xlabel('frequency (Hz)');
set(gca,'xlim',[0,15]);
subplot(1,3,3);
plot(fHz,power_sleep(:,6));
title('EEG power in REM sleep'); 
ylabel('power');
xlabel('frequency (Hz)');
set(gca,'xlim',[0,15]);
f1=fullfile(folder,'spectral.png');
F=getframe(gcf);
imwrite(F.cdata,f1);
%%
%export data to an excel file
fout='sleepMetrics';
% nowstr=datestr(now,31);
% nowstr(strfind(nowstr,':'))='-';
nowstr=datestr(now,30);
FileName=['sleepMetrics',nowstr,'.xls'];
fname=fullfile(folder,FileName);
label1={'ZT-time','Wake','NREMS','REMS'};
%sheet 1------------basic summary
writecell(label1,fname,'Sheet',1,'Range','A1:D1'); 
writematrix((1:24)',fname,'Sheet',1,'Range','A2:A25'); 
writematrix(ztSleep,fname,'Sheet',1,'Range','B2:D25'); 
label1={'total(min)','light(min)','dark(min)'};
writecell(label1',fname,'Sheet',1,'Range','A27:A29'); 
writematrix(dur_24h,fname,'Sheet',1,'Range','B27:D29');
label1={'bouts-24h','bouts-light','bouts-dark'};
writecell(label1',fname,'Sheet',1,'Range','A31:A33'); 
writematrix(bouts,fname,'Sheet',1,'Range','B31:D33'); 
label1={'bout-duratoin(s)-24h','dur-light','dur-dark'};
writecell(label1',fname,'Sheet',1,'Range','A35:A37'); 
writematrix(bout_dur,fname,'Sheet',1,'Range','B35:D37'); 
label1={'Transitions'};
writecell(label1,fname,'Sheet',1,'Range','G1'); 
label1={'W-N','N-R','N-W','R-N','R-W'};
writecell(label1',fname,'Sheet',1,'Range','G2:G6'); 
writematrix(transit',fname,'Sheet',1,'Range','H2:H6'); 
%sheet 2------------spectral
% modify on 1/16/2025, remove log2-p, add wake
label1={'F(hz)','wake-p0','wake-p1','NREM-p0','NREM-p1','REM-p0','REM-p1'};
writecell(label1,fname,'Sheet',2,'Range','A1:G1'); 
lidx=['A2:G',num2str(1+length(fHz))];
writematrix([fHz',power_sleep],fname,'Sheet',2,'Range',lidx);
%sheet 3------------original hourly
label1={'Hour#','Wake','NREMS','REMS'};
writecell(label1,fname,'Sheet',3,'Range','A1:D1'); 
lidx=['A2:D',num2str(1+totalHour)];
writematrix([tm,dur_perh],fname,'Sheet',3,'Range',lidx);
disp('done, data saved in excel file');
%%
disp(bouts);
disp(transit);
