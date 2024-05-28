function plotData2(pDat,mDat,state,fname)
%totmin=round((pDat.t(end)-pDat.t(1))/60);
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
    hfg=figure('position',[10,200,1500,600]);
    setappdata(0,'figResult',hfg);    
end
clf;
%update Figure title
fName=pDat.Labels;
set(gcf,'Name',fName);
%show state-------------------------------------------------------------
axes('position',[0.07,0.9,0.9,0.05]);
imagesc(state');
mymap=[0.5,0.5,0.5;1,0.5,0;0.6,0.2,1;1,1,0];
colormap(gca,mymap);
set(gca,'clim',[0,3]);
axis off;
%show EEG-spectrogram--------------------------------------------------
axes('position',[0.07,0.64,0.9,0.25]);
imagesc(pDat.p');
colormap(gca,'jet');
[wid,hei]=size(pDat.p);
scaleDt=max(pDat.p,[],2);       %default=delta
clm=1*prctile(scaleDt,80);
set(gca,'clim',[0,clm]);
set(gca,'YDir','normal','XTick',[],'YTick',[],'fontsize',14);
%text(-0.01*wid,hei*1/pDat.fsRange(2),'0-','fontsize',14);
text(-0.02*wid,hei*11/pDat.fsRange(2),'10-','fontsize',14);
text(-0.02*wid,hei,[num2str(pDat.fsRange(2)),'-'],'fontsize',14);
text(-0.03*wid,hei*3/pDat.fsRange(2),'(Hz)','fontsize',14);
%ylabel('Hz');
%show filtered EEG-------------------------------------------------------
axes('position',[0.07,0.37,0.9,0.25]);
h0=prctile(pDat.fEEG(2,:), 90)*10;
%h0=100;
plot(pDat.fEEG(1,:)/60,pDat.fEEG(2,:),'k','linewidth',0.5);
%also marker events on the plot
szEvents=getszEvents(pDat,state,3);
if ~isempty(szEvents)
%     y0=zeros(size(szEvents,1),1);
%     hold on;
%     plot(szEvents(:,2)/60,y0,'.r');
%     hold on;
%     plot(szEvents(:,3)/60,y0,'.g');
    sznum=size(szEvents,1);
    for i=1:sznum
        hold on;
        plot(szEvents(i,2:3)/60,[0,0],'g','linewidth',2);
    end
end
set(gca,'xlim',[pDat.fEEG(1,1),pDat.fEEG(1,end)]/60,'ylim',[-h0,h0],'Box','on','fontsize',14);
set(gca,'xtick',[]);
%set(gca,'XTick',0:5:30);
%xlabel('time(min)');
ylabel('uV');
%show indicators traces-------------------------------------------------
axes('position',[0.07,0.1,0.9,0.25]);
scl=60;         %use 60 for min-display, use 1 for sec
%yyaxis left;
% ymax=min(10,3*prctile(pDat.delta,90));
% plot(pDat.t/scl, pDat.delta);
% set(gca,'xlim',[pDat.t(1),pDat.t(end)]/scl,'ylim',[0,ymax]);
% ylabel('delta(1-4Hz)');
%yyaxis right;
ymax=min(100,5*prctile(pDat.fseiz,95));
plot(pDat.t/scl, pDat.fseiz);
%draw std-threshold line
hold on;
plot([pDat.t(1),pDat.t(end)]/scl,[1,1]*pDat.seizTh,'--r');
set(gca,'xlim',[pDat.t(1),pDat.t(end)]/scl,'ylim',[0,ymax],'fontsize',14);
%set(gca,'xtick',pDat.t(1)/scl:60:pDat.t(end)/60);
ylabel('Power(20-24Hz)');
xlabel('time(min)');
%auto save figure to tif-file
if ~isempty(fname)
    F=getframe(gcf);
    imwrite(F.cdata,fname);
end