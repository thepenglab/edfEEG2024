%----------------------------------------------------------------- DataLoad
function dat = DataLoad(info,procWindow)
fname = strcat(info.PathName,info.FileName);
fid=fopen(fname,'r');

SkipByte=info.FileInfo.HeaderNumBytes+fix(procWindow(1)/info.FileInfo.DataRecordDuration) ...
    *sum(info.ChInfo.nr)*2;
fseek(fid,SkipByte,-1);

%Method#1-----------------------------------------------------------------
%original method of loading data, very slow due to for-loop
% for i=1 : max(procWindow(2)/info.FileInfo.DataRecordDuration, 1) %% added max(), fix crash
%     for j=1:info.FileInfo.SignalNumbers
%         Data{j}= [Data{j} fread(fid,[1 info.ChInfo.nr(j)],'int16') ];
%     end
% end
%Method#2-----------------------------------------------------------------
%fast way to load data
rep=floor(procWindow(2)/info.FileInfo.DataRecordDuration);
AllChSize=sum(info.ChInfo.nr);
allDat=fread(fid,[1 AllChSize*rep],'int16');

%separate channels
Data = cell(length(info.chs),1);
k1=0;
%for i=1:info.FileInfo.SignalNumbers
for i=1:length(info.chs)
    k=info.chs(i);
    A=repmat((1:info.ChInfo.nr(k))',1,rep);
    if k>1
        k1=sum(info.ChInfo.nr(1:k-1));
    end
    b1=(k1:AllChSize:AllChSize*rep-1);
    B=repmat(b1,info.ChInfo.nr(k),1);
    C=reshape(A+B,1,info.ChInfo.nr(k)*rep);
    Data{i}=allDat(C);
end

labels = cell(length(info.chs),1);
for j=1:length(info.chs)
    k=info.chs(j);
    labels{j}=deblank(info.ChInfo.Labels(k,:));
end
%deal with EDF+ file, get annotations
annoIdx=0;
for i=1:info.FileInfo.SignalNumbers
    if contains(info.ChInfo.Labels(i,:),'Annotation')
        annoIdx=i;
        break;
    end
end
if annoIdx>0
    Annotations=getAnnotations(Data{annoIdx});
    Data = Data(1:annoIdx-1);
    fprintf('\r\nAnnotations:\n');
    for i=1:length(Annotations.tm)
        fprintf('Time:%fsec\t%s\n',Annotations.tm(i),Annotations.txt{i})
    end
    fprintf('------End of Annotations------\r\n');
else
    Annotations=[];
end

fclose(fid);
%dat.Data=Data;
dat.Tim = linspace(0,procWindow(2),length(Data{1}))+procWindow(1);
dat.Annotations = Annotations;
dat.Labels=labels;
if ~isempty(strfind(info.FileInfo.LocalRecordID,'Profusion'))
    %for old Profusion recording system
    dat.Data=DataNormalize0(info,Data);
else
    %for natus system
    dat.Data=DataNormalize(info,Data);
end

%-----------------
function Annotations=getAnnotations(dat)
Annotations=struct('tm',[],'txt',[]);
%idx0=find(dat==20);
%TALnum=length(idx0);
highbyte=uint8(dat/256);
lowbyte=uint8(mod(dat,256));
strAll=blanks(2*length(lowbyte));
strAll(1:2:end)=char(lowbyte);
strAll(2:2:end)=char(highbyte);
%number of Time-stamped Annotations, each start with '+'=43 or '-'=45
idx1=find(strAll==43);
TALnum=length(idx1);
k=0;
for i=1:TALnum
    d1=idx1(i)+1;
    if i<TALnum
        d2=idx1(i+1);
    else
        d2=length(strAll);
    end
    idx20=find(strAll(d1:d2)==20);
    if length(idx20)>1
        t1=str2double(strAll(d1:d1+idx20(1)-2));
        s1=[];
        for j=1:length(idx20)-1
            if idx20(j+1)-idx20(j)>1
                s1=[s1,strAll(idx20(j)+d1:idx20(j+1)+d1-2),' '];
            end
        end
        if ~isempty(s1)
            k=k+1;
            Annotations.tm(k)=t1;
            Annotations.txt{k}=s1;
        end
    end
end
%display(k);


%----------------------------------------------------------------- DataNormalize
function dat2 = DataNormalize(info,Data)
dat2=cell(length(Data),1);
% original from EDF-Viewer
% for i=1:length(Data)
%     % remove the mean
%     dat2{i}=Data{i}-(info.ChInfo.DiMax(i)+info.ChInfo.DiMin(i))/2;
%     dat2{i}=dat2{i}./(info.ChInfo.DiMax(i)-info.ChInfo.DiMin(i));
%     if info.ChInfo.PhyMin(i)>0
%         dat2{i}=-dat2{i};
%     end
% end
% from Kaoskey, to solve clipping issue?
for i=1:length(Data)
    MaxVal=info.ChInfo.DiMax(i);
    MinVal=info.ChInfo.DiMin(i);
    %clip extreme-datappints
%     c1=mean(Data{i})-3*std(Data{i});
%     c2=mean(Data{i})+3*std(Data{i});
    %recalculate mean after removing extreme
%     idx=Data{i}>c1 & Data{i}<c2 ;
    cc1=mean(Data{i})-10*std(Data{i});
    cc2=mean(Data{i})+10*std(Data{i});
    Data{i}(Data{i}<cc1)=cc1;
    Data{i}(Data{i}>cc2)=cc2;
    if ~isempty(find(Data{i}<cc1 | Data{i}>cc2))
        disp('unusual datapoints clipped!');
    end
%     PhysMax=max(Data{i});
%     PhysMin=min(Data{i});
    PhysMax=info.ChInfo.PhyMax(i);
    PhysMin=info.ChInfo.PhyMin(i);
    ScaleFactors=(PhysMax-PhysMin)/(MaxVal-MinVal);
    dat2{i}=round((Data{i}-MinVal)*ScaleFactors)+PhysMin;
end


%-------------------------------------------------DataNormalize from Kaoskey
function dat2 = DataNormalize0(info,Data)
dat2=cell(length(Data),1);
for i=1:length(Data)
    k=info.chs(i);
    MaxVal=info.ChInfo.DiMax(k);
    MinVal=info.ChInfo.DiMin(k);
    %clip extreme-datappints
%     c1=mean(Data{i})-3*std(Data{i});
%     c2=mean(Data{i})+3*std(Data{i});
%     %recalculate mean after removing extreme
%     idx=Data{i}>c1 & Data{i}<c2 ;
%     cc1=mean(Data{i}(idx))-10*std(Data{i}(idx));
%     cc2=mean(Data{i}(idx))+10*std(Data{i}(idx));
%     if ~isempty(find(Data{i}<cc1 | Data{i}>cc2))
%         %disp('unusual datapoints found!');
%         Data{i}(Data{i}<cc1)=cc1;
%         Data{i}(Data{i}>cc2)=cc2;
%     end
    PhysMax=max(Data{i});
    PhysMin=min(Data{i});
    ScaleFactors=(MaxVal-MinVal)/(PhysMax-PhysMin);
    dat2{i}=round((Data{i}-PhysMin)*ScaleFactors)+MinVal;
end

