%load EEG data from edf-file and plot traces for a defined windows
% startTime='8/6/2018 11:05:23';
% tim1='8/7/2018 00:00:00';
% tim2='8/7/2018 00:45:00';
startTime='11/13/2017 11:49:33';
tim1='11/13/2017 12:49:33';
tim2='11/13/2017 13:49:33';
timHH=24*[datenum(tim1)-datenum(startTime),datenum(tim2)-datenum(startTime)];

%step2=read edf-file
m=1;
selectedCh=2;   % for fft (should be either FL-BL(2) or FR-BL(3))
datWindow=timHH*60;     %time window for analysis(min): start/end, 0-all data
edffile=strcat(PathName,edfname);
info=struct();
info.PathName=PathName;
info.FileName=edfname;
%channel info
tempEdfHandles = EdfInfo(edffile);
info.FileInfo  = tempEdfHandles.FileInfo;
info.ChInfo    = tempEdfHandles.ChInfo;
%sort channels for each mouse with the order: FL,FR,BL,BR,EMG based on Labels
chDat = sortCh(info.ChInfo.Labels);
info.ChInfo.eegChs=chDat.eegChs;
info.ChInfo.emgChs=chDat.emgChs;
info.ChInfo.miceName=chDat.miceName;
info.ChInfo.micenum = length(info.ChInfo.miceName);
% Get file description, which contains name/date/bytes/isdir/datenum
EdfFileAttributes = dir(edffile);
%TODO: determine the total time later from EDF file
info.TotalTime = (EdfFileAttributes.bytes - info.FileInfo.HeaderNumBytes) ...
        / 2  / sum(info.ChInfo.nr) * info.FileInfo.DataRecordDuration;
fprintf('the number of mice detected: %d\n',info.ChInfo.micenum);
fprintf('total record time: %d sec, or %5.1f hours\n',info.TotalTime, info.TotalTime/3600);
micelist=1:info.ChInfo.micenum;       %list of mice for processing, based on index generated from <sortCh>
procWindow=floor(datWindow*60);       %processing window,start/duration, unit=sec
data=DataLoad(info,procWindow);
%construct differential signals for each mouse
eegDat=diffCh(info,data);
eeg=double(eegDat(m).Data{selectedCh});
fs=eegDat(1).SamplingRate;
%fiter data, default for sleep: 0.5-60Hz with bandpass filter
d=fdesign.bandpass('N,F3dB1,F3dB2',10,0.5,60,fs);
hd=design(d,'butter');
eeg=filter(hd,eeg);

%step3=plot traces
scaleTm=60;     %unit=sec
eventnum=floor((procWindow(2)-procWindow(1))/scaleTm);
egmax=quantile(abs(eeg),0.9)*10;
figure('position',[0,0,1500,eventnum*40]);
for i=1:eventnum
    idx=find(eegDat(m).Tim>=(i-1)*scaleTm+procWindow(1) & eegDat(m).Tim<=i*scaleTm+procWindow(1));
    t=eegDat(m).Tim(idx)-eegDat(m).Tim(idx(1));
    eg=eeg(idx)/egmax+i-0.5;
    plot(t,eg,'k','linewidth',1);
    hold on;
end
set(gca,'ylim',[0,eventnum]);
xlabel('time(sec)')
%ylabel('#minute');
ylabel(['#minute ','(',tim1,'-',tim2,')']);