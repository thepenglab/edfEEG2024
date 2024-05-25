function pDat=getSpectrogram(tm,eeg,fs,bin,step)
pDat=struct();
fsRange=[0 50];      %frequence range for analysis
ftheta=[6,9];       %theta frequency
fdelta=[1,4];        %delta frequency
fseiz=[20,24];      %for seizure detection,default=[12,25],or [19,23]
fs0=[10,12];         %control for seizure detection, [17,19];
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
totalHours=(tm(end)-tm(1))/3600;
if totalHours>20
    m=round(totalHours);
else
    m=20;                   %progress bar length
end
fprintf(['Work-load:' repmat('|',1,m) '(100%%)\n']);
fprintf('Work-done:\n');

poolobj=gcp('nocreate');
if isempty(poolobj) 
    for i=1:tLen
        idx=(tm>=t(i)-bin/2 & tm<t(i)+bin/2);
        Y=fft(eeg(idx),nfft)/L;
        pxx=abs(Y(1:nfft/2+1)).^2/fs;
        p(i,:)=pxx(idx0);
        pseiz(i)=mean(pxx(idx3));
        ptheta(i)=mean(pxx(idx1));
        pdelta(i)=mean(pxx(idx2));
        pfs0(i)=mean(pxx(idx6));
        if mod(i,round(tLen/m))==1
            fprintf('\b=\n');
        end
    end
else
    %use parfor
    parfor i=1:tLen
        idx=(tm>=t(i)-bin/2 & tm<t(i)+bin/2);
        Y=fft(eeg(idx),nfft)/L;
        pxx=abs(Y(1:nfft/2+1)).^2/fs;
        p(i,:)=pxx(idx0);
        pseiz(i)=mean(pxx(idx3));
        ptheta(i)=mean(pxx(idx1));
        pdelta(i)=mean(pxx(idx2));
        pfs0(i)=mean(pxx(idx6));
        if mod(i,round(tLen/m))==1
            fprintf('\b=\n');
        end
    end
end



%note: extra smooth here, due to small bin/step for seizures
%bin2=floor(10/step)+1;
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
pDat.p=imfilter(p,h);
%pDat.p=p/factor;
pDat.theta=ptheta;
pDat.delta=pdelta;
pDat.fseiz=pseiz;
pDat.fcontrol=pfs0;
pDat.ratio=ptheta./pdelta;      % for sleep use theta/delta
pDat.phighfband=phighfband;