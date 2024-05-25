function ShowRawData(dat)
figRawData=getappdata(0,'figRawData');
hfig=0;
chnum=length(dat.Data);
if ~isempty(figRawData)
    if ishandle(figRawData)
        hfig=1;
    end
end
if hfig
    set(0,'currentfigure',figRawData);
    clf;
else
    hfg=figure('position',[50,0,1500,800],'Name','Original EEG data');
    setappdata(0,'figRawData',hfg);    
end
fhi=0.95/(chnum+0);

for i=1:chnum
	%subplot(chnum,1,i);
    axes('position',[0.05,1-i*fhi,0.75,fhi*0.8]);
    data=dat.Data{i};
    %if filters on 
    if isfield(dat,'filter')
        if dat.filter.OnOff
            d=fdesign.bandpass('N,F3dB1,F3dB2',10,dat.filter.EEG(1),dat.filter.EEG(2),dat.fs);
            hd=design(d,'butter');
            data=filter(hd,dat.Data{i});
            if dat.filter.Notch
                %notch filter to remove 60Hz noise
                d=fdesign.notch(6,60,10,dat.fs);
                hd=design(d);
                data=filter(hd,data);
            end
        end
    end
    plot(dat.Tim/60,data,'k');   
    ymax=max(1000,10*prctile(data,95));
    set(gca,'xlim',dat.Tim([1,end])/60,'ylim',[-ymax,ymax]);
    ylabel('uV');
    title(dat.Labels{i});
    %grid on;
    if i==chnum
        xlabel('time(min)');
    else
        set(gca,'xtick',[]);
    end
    %show spectral information for each channel
    specDat=getRawSpectral(dat.Data{i},dat.fs);
    pLen=length(specDat.p);
    xf=linspace(specDat.fsRange(1),specDat.fsRange(2),pLen);
    axes('position',[0.85,1-i*fhi,0.1,fhi*0.8]);
    plot(xf,specDat.p);
    ylabel('Power');
    if i==chnum
        xlabel('frequency(Hz)');
    else
        set(gca,'xtick',[]);
    end
end
% yaxis=[-1000,1000];