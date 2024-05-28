function mDat=getEMGAmplitude(dat,info)
mDat=struct('Tm',[],'Amp',[],'Std',[]);
emg=double(dat.Data);
fs=dat.SamplingRate;
%filter data: 10-300Hz
d=fdesign.bandpass('N,F3dB1,F3dB2',10,info.filterEMG(1),info.filterEMG(2),fs);
hd=design(d,'butter');
emg2=filter(hd,emg);
if info.filterNotch
    %notch filter to remove 60Hz noise
    d=fdesign.notch(6,60,10,fs);
    hd=design(d);
    emg2=filter(hd,emg2);
end
%show the data: pre and filtered
%figure;subplot(2,1,1);plot(emg);subplot(2,1,2);plot(emg2);
offset=0;
D1=abs(emg2)-offset;
D2=smooth(D1,floor(fs*info.binTime/2)+1,'moving')-offset;
%down-sampling
%mDat.Amp=resample(D2,1,step*dat.fs);
step2=floor(info.stepTime*fs);
mDat.Amp=D2(1:step2:end);
%mDat.Amp=clipNoise(mDat.Amp,150);
tLen=length(mDat.Amp);
mDat.Tm=linspace(dat.Tim(1),dat.Tim(end),tLen);
mDat.Std=zeros(tLen,1); 
h=waitbar(0,'processing EMG,please wait...');  
for i=1:tLen
    idx=(mDat.Tm>=(mDat.Tm(i)-1*info.binTime) & mDat.Tm<(mDat.Tm(i)+1*info.binTime));
    mDat.Std(i)=std(mDat.Amp(idx));
    waitbar(i/tLen);  
end
close(h);
mDat.step=info.stepTime;
mDat.bin=info.binTime;
%save filtered EMG for ploting
t=linspace(dat.Tim(1),dat.Tim(end),length(emg2));
mDat.fEMG=[t;emg2];