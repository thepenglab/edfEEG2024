%show spectral information of seizures
function ShowSpectrum(state,specDat)
%create figure
hfig=0;
figSpectrum=getappdata(0,'figSpectrum');
if ~isempty(figSpectrum)
    if ishandle(figSpectrum)
        hfig=1;
    end
end
if hfig
    set(0,'currentfigure',figSpectrum);
    clf;
else
    hfg=figure('position',[50,50,1000,400],...
        'NumberTitle','off','Name','Spectral power');
    setappdata(0,'figSpectrum',hfg);    
end
[tLen,pLen]=size(specDat.p);
f=linspace(specDat.fsRange(1),specDat.fsRange(2),pLen);
%spectrum of all-data (remove noise)
deltaTh=mean(specDat.delta)+6*std(specDat.delta);
thetaTh=mean(specDat.theta)+6*std(specDat.theta);
idx=specDat.delta>deltaTh & specDat.theta>thetaTh;
idx2=~idx;
p0=mean(specDat.p(idx2,:));
%p0=mean(specDat.p);                %real all-data
%spectrum of seizures
idx=state==3;
p1=mean(specDat.p(idx,:));
%identify the peak-frequency
offset=12;
[m,idx]=max(p1(offset:end));
f0_peak=f(idx+offset-1);
fprintf('Peak frequency =%6.2f\n',f0_peak);
subplot(1,2,1);
plot(f,p0,'linewidth',1);
xlabel('frequency(Hz)');
ylabel('power');
title('Spectral power of all-data');
subplot(1,2,2);
plot(f,p1,'linewidth',1);
text(f(end)*0.55,m*0.8,['Peak frequency=',num2str(f0_peak),'Hz']);
xlabel('frequency(Hz)');
ylabel('power');
title('Spectral power of seizures');