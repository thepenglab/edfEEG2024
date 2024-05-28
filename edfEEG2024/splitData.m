%-----------------------------------------------------------data per animal
function dat=splitData(info,data)
%output/dat info: [FL-FR, FL-BL, FR-BL, EMG] for each mouse
dat=struct();
micenum=info.ChInfo.micenum;
miceIdx=[];
for i=1:micenum
    if ~isempty(strfind(info.ChInfo.miceName{i},info.miceName_input))
        miceIdx=[miceIdx,i];
    end
end
mnum=length(miceIdx);
for i=1:mnum
    dat(i).Tim=data.Tim;
    ch=miceIdx(i);
    chnum=size(info.ChInfo.eegChs,2);
    for j=1:chnum
        chk=info.ChInfo.eegChs(ch,j);
        dat(i).Data{j}=data.Data{chk};
        dat(i).specDat{j}=getSpectral(dat(i).Data{j},info.fs);
        s1=strtrim(info.ChInfo.Labels(chk,:));
        dat(i).Labels{j}=s1;
        dat(i).SignalNumbers=4;
        dat(i).SamplingRate=info.fs;
    end

end
%add EMG if detected, assume a pair of EMG-channels for one mouse
% emgmnum=length(info.ChInfo.emgChs)/2;
% if emgmnum>0
%     for i=1:emgmnum
%         dat(i).Data{4}=data.Data{info.ChInfo.emgChs(2*i-1)}-data.Data{info.ChInfo.emgChs(2*i)};
%         dat(i).SignalNumbers=4;
%     end
% end
