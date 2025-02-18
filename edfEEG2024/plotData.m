function plotData(pDat,mDat,state,fname)
totmin=floor((mDat.Tm(end)-mDat.Tm(1))/60);
figResult=getappdata(0,'figResult');
hfig=0;
if ~isempty(figResult)
    if ishandle(figResult)
        hfig=1;
    end
end
if hfig
    set(0,'currentfigure',figResult);
else
    hfg=figure('position',[10,200,1500,400]);
    setappdata(0,'figResult',hfg);    
end
clf;
%update Figure title
fName=pDat.Labels;
set(gcf,'Name',fName);
%show state-----------------------------------------
axes('position',[0.05,0.87,0.9,0.06]);
imagesc(state');
mymap=[0,0,0;0.5,0.5,0.5;1,0.5,0;0.6,0.2,1;1,1,0];
colormap(gca,mymap);
set(gca,'clim',[-1,3]);
axis off;
%show EEG-spectrogram-------------------------------
axes('position',[0.05,0.50,0.9,0.35]);
imagesc(pDat.p');
colormap(gca,'jet');
[wid,hei]=size(pDat.p);
fLen=pDat.fsRange(2)-pDat.fsRange(1);

if isfield(pDat,'clim')
    cmax=min(2,pDat.clim);
else
    cmax=2;
end
%cmax=2;
set(gca,'clim',[0,cmax],'YDir','normal','XTick',[],'YTick',[]);
%set(gca,'YDir','normal','XTick',[],'YTick',[]);
text(-0.01*wid,hei*1/fLen,'0-','fontsize',16);
text(-0.02*wid,hei*11/fLen,'10-','fontsize',16);
text(-0.02*wid,hei*24/fLen,'Hz','fontsize',16);
ylm=[0,25]*hei/fLen;
set(gca,'ylim',ylm);
%show EMG----------------------------------------------
axes('position',[0.05,0.18,0.9,0.3]);
if isfield(mDat,'fEMG1')
    emgT=mDat.fEMG(1,:);
    emgDat=mDat.fEMG(2,:);
    h0=min(max(emgDat),1000);
    ylm=[-h0,h0];
else
    emgT=mDat.Tm;
    emgDat=mDat.Amp;
    h0=max(max(emgDat),10);
    ylm=[-h0/10,h0];
end
%h0=100;
%label the stimulation period
plot(emgT/60,emgDat,'linewidth',1,'Color',[0.5,0.5,0.5]);
set(gca,'xlim',[emgT(1),emgT(end)]/60,'fontsize',16,'Box','on','linewidth',1);
%also plot velocity if available
if isfield(mDat,'velDat')
    hold on;
    plot(mDat.velDat(:,1)/60,mDat.velDat(:,2),'r');
end
%set(gca,'ylim',ylm);
%set(gca,'XTick',0:5:30);
% y0=100*(floor(h0/100));
% text(-0.03*totmin,y0/2,[num2str(y0/2),'-'],'fontsize',16);
% text(-0.02*totmin,0,'uV','fontsize',16);
xlabel('time(min)','fontsize',16);
ylabel('EMG(uV)');
%auto save figure to tif-file
if ~isempty(fname)
    F=getframe(gcf);
    imwrite(F.cdata,fname);
end
