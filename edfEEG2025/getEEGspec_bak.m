%-------------------------------------------------------------getEEGspectro
% modifed from neuralnx-version
function pDat=getEEGspec(dat,info)
eeg=double(dat.Data);
fs=dat.SamplingRate;
%fiter data, default for sleep: 0.5-60Hz with bandpass filter
d=fdesign.bandpass('N,F3dB1,F3dB2',10,info.filterEEG(1),info.filterEEG(2),fs);
hd=design(d,'butter');
eeg=filter(hd,eeg);
% if info.filterNotch
%     %notch filter to remove 60Hz noise
%     d=fdesign.notch(6,60,10,fs);
%     hd=design(d);
%     eeg=filter(hd,eeg);
% end
pDat=getmySpectrogram(dat.Tim,eeg,fs,info.binTime,info.stepTime);
pDat.fEEG=[dat.Tim;eeg];
pDat.step=info.stepTime;
pDat.bin=info.binTime;
pDat.fs=fs;
pDat.Labels=dat.Labels;


function pDat=getmySpectrogram(tm,eeg,fs,bin,step)
%----------------
%default for sleep, due to different time scale of sleep/SWD
bin2=5;
%----------------
pDat=struct();
fsRange=[0 30];      %frequence range for analysis
ftheta=[6,9];       %theta frequency
fdelta=[1,4];        %delta frequency
fseiz=[20,24];      %for seizure detection,default=[12,25],or [19,23]
fs0=[17,19];         %control for seizure detection, [17,19];
t=tm(1:step*fs:end);
L=fs*3;
nfft=2^nextpow2(L);
f=fs/2*linspace(0,1,nfft/2+1);
idx0=find(f>=fsRange(1) & f<=fsRange(2));
idx1=(f>=ftheta(1) & f<=ftheta(2));
idx2=(f>=fdelta(1) & f<=fdelta(2));
idx3=(f>=fseiz(1) & f<=fseiz(2));
idx6=(f>=fs0(1) & f<=fs0(2));
tLen=length(t);
p=zeros(tLen,length(idx0));
ptheta=zeros(tLen,1);
pdelta=zeros(tLen,1);
pseiz=zeros(tLen,1);
pfs0=zeros(tLen,1);
%egm0=median(abs(eeg))/1000;
h=waitbar(0,'fft EEG,please wait...');   
for i=1:tLen
    %fft for seizure
    idx=(tm>=t(i)-bin/2 & tm<t(i)+bin/2);
    Y=fft(eeg(idx),nfft)/L;
    pxx=abs(Y(1:nfft/2+1)).^2/fs;
    p(i,:)=pxx(idx0);
    pseiz(i)=mean(pxx(idx3));
    %another fft for sleep
    idxx=(tm>=t(i)-bin2/2 & tm<t(i)+bin2/2);
    Y2=fft(eeg(idxx),nfft)/L;
    pxx2=abs(Y2(1:nfft/2+1)).^2/fs;
    ptheta(i)=mean(pxx2(idx1));
    pdelta(i)=mean(pxx2(idx2));
    pfs0(i)=mean(pxx2(idx6));
    waitbar(i/tLen) 
end
close(h);  
%note: extra smooth here, due to small bin/step for seizures
%normalize the power
%for normal EEG (sleep/wake, SWD seizure)
%factor=max(quantile(ptheta,0.9),quantile(pdelta,0.9))/10;
%for huge TS/GTCS seizures
%factor=max(quantile(ptheta,0.5),quantile(pdelta,0.5))/10;
factor=1;
bin2=floor(10/step)+1;
ptheta=smooth(ptheta,bin2)/factor;
pdelta=smooth(pdelta,bin2)/factor;
pfs0=smooth(pfs0,bin2)/factor;
pseiz=pseiz/factor;
pfs0m=median(pfs0);

%f-band with highest power: 0=one, 1=delta, 2=theta, -1=noiseonly
phighfband=zeros(tLen,1);
%generate a matrix to compare band-power
pfband=[pdelta ptheta*1.2 pfs0*2];
[mx,phIdx]=max(pfband,[],2);
phighfband(phIdx==1 & pdelta/pfs0m>4)=1;
phighfband(phIdx==2 & ptheta/pfs0m>5)=2;
phighfband(phIdx==3)=-1;

pDat.t=t;
pDat.fsRange=fsRange;
%smooth image
h=fspecial('average',3);
pDat.p=imfilter(p,h)/factor;
%pDat.p=p/factor;
pDat.theta=ptheta;
pDat.delta=pdelta;
pDat.fseiz=pseiz;
pDat.fcontrol=pfs0;
pDat.ratio=ptheta./pdelta;      % for sleep use theta/delta
pDat.phighfband=phighfband;