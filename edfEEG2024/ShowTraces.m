%show EEG traces of seizurs
function ShowTraces(szEvents,specDat)
pre=5;post=10;      %for sleep, SWD
anaMode=getappdata(0,'anaMode');
if anaMode(3)
    pre=10;
    post=50;
end
%pre=10;post=20;      %for GTCS
%cl=[.85,.85,.85];
scaleFactor=10;
if pre+post>15
    wid=1600;
else
    wid=1200;
end
snum=size(szEvents,1);
if snum>15
    hei=50;
else
    hei=80;
end
tm=specDat.fEEG(1,:);
eg=specDat.fEEG(2,:);
egmax=quantile(abs(eg),0.95)*scaleFactor;

%create figure
hfig=0;
figTraces=getappdata(0,'figTraces');
if ~isempty(figTraces)
    if ishandle(figTraces)
        hfig=1;
    end
end
if hfig
    set(0,'currentfigure',figTraces);
    clf;
else
    hfg=figure('position',[100,0,wid,snum*hei],...
        'NumberTitle','off','Name','Selected EEG traces');
    setappdata(0,'figTraces',hfg);    
end

%plot traces
for i=1:snum
	idx=find(tm>=szEvents(i,2)-pre & tm<=szEvents(i,2)+post);
	hold on;
	plot(tm(idx)-tm(idx(1))-pre,eg(idx)/egmax+i-0.5,'k','linewidth',0.5);
end
xlabel('time(sec)');
ylabel('Seizure EEG');
set(gca,'xlim',[-pre,post],'ylim',[0,snum]);
