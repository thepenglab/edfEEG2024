%-------------------------------------------------------------getEEGspectro
% modifed from neuralnx-version
function pDat=getEEGspec2(dat,info)
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
disp('FFT EEG, please wait...');
tic;
pDat=getSpectrogram(dat.Tim,eeg,fs,info.binTime,info.stepTime);
toc;
pDat.fEEG=[dat.Tim;eeg];
pDat.step=info.stepTime;
pDat.bin=info.binTime;
pDat.fs=fs;
pDat.Labels=dat.Labels;
