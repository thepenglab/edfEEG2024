%--------------------------------------------------------------------SortCh
function chDat=sortCh(Labels)
%default labels for channels and mice
chLabels={'FL','FR','BL','BR'}; 
commonMiceLabel='M';
% chLabels={'33','35','34','36'};
% commonMiceLabel='3';
chDat=struct();
chnum=size(Labels,1);
FLidx=[];FRidx=[];BLidx=[];BRidx=[];
for i=1:chnum
    if strfind(Labels(i,:),chLabels{1})
        FLidx=[FLidx i];
    end
    if strfind(Labels(i,:),chLabels{2})
        FRidx=[FRidx i];
    end
    if strfind(Labels(i,:),chLabels{3})
        BLidx=[BLidx i];
    end
    if strfind(Labels(i,:),chLabels{4})
        BRidx=[BRidx i];
    end
end
[micenum,idx]=min([length(FLidx),length(FRidx),length(BLidx),length(BRidx)]);
if idx==1
    lb0=FLidx;
elseif idx==2
    lb0=FRidx;
elseif idx==3
    lb0=BLidx;
else
    lb0=BRidx;
end
%get the name for each mouse, only work if Labels as 'Mx', x=1-9
miceName=cell(1,micenum);
for i=1:micenum
    idx=strfind(Labels(lb0(i),:),commonMiceLabel);
    if ~isempty(idx)
        miceName{i}=Labels(lb0(i),idx(1):idx(1)+1);
    end
end
midx=cell(1,micenum);
for i=1:chnum
    for m=1:micenum
        if strfind(Labels(i,:),miceName{m})
            midx{m}=[midx{m},i];
        end
    end
end
eegChs=zeros(micenum,4);
for i=1:micenum
    eegChs(i,1)=intersect(midx{i},FLidx);
    eegChs(i,2)=intersect(midx{i},FRidx);
    eegChs(i,3)=intersect(midx{i},BLidx);
    eegChs(i,4)=intersect(midx{i},BRidx);
end
%see if there is EMG channels (labels '33'-'40')
emgChs=[];
% for i=1:chnum
%     for j=33:40
%         if strfind(Labels(i,:),num2str(j))
%             emgChs(end+1)=i;
%         end
%     end
% end
chDat.eegChs=eegChs;
chDat.miceName=miceName;
chDat.emgChs=emgChs;