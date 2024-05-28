% load data from EDF file
% modify from EDF-viewer
function data=loadEDF(filename)
%read headInfo
data=struct();
data.FileName=filename;
fprintf('reading %s\n',filename);
%tic
try
    belClass = BlockEdfLoadClass(filename);
    belClass = belClass.blockEdfLoad; 
    belClass = belClass.CheckEdf;
    %fprintf('Checking: %s\n', filename);
    % Access checking information: lines 321-327 on BlockEdfLoadClass
    if ~isempty(belClass.errMsg) && belClass.mostSeriousErrValue <= 4
        belClass.DispCheck 
        ErrMsg = []; %belClass.errSummary;
        ErrMsg = [ErrMsg, showErrorMessages(belClass.errList)];
        
        warndlg(ErrMsg, belClass.errSummary, 'modal');
    end
    if belClass.mostSeriousErrValue > 4
        ErrMsg = 'Fatal Error: Cannot load';  
        errordlg(ErrMsg, 'Fatal Errors', 'modal');
        % EDF check failed
        data.EDF_CHECK = 0;
        return
    else
        data.EDF_CHECK = 1;
    end
    %fprintf('Checking passed.\n')
catch exception
    errMsg = sprintf('Could not load: %s\nFile cannot be read', filename);
    errordlg(errMsg, 'Fatal Error', 'modal');     
    return;
end

%channel info
tempEdfHandles = EdfInfo(filename);
data.FileInfo  = tempEdfHandles.FileInfo;
data.ChInfo    = tempEdfHandles.ChInfo;
data.FlagChInfo = 1;

% handles.ChInfo.nr is a vector contains numbers of samples in each
% data record
numOfChannels = length(data.ChInfo.nr);

% Initialize to be selected channels
% Temp = ns x 2 structure, <index of channel, 1/0 (not) selected>
Temp = [(1:numOfChannels)' zeros(numOfChannels,1)];
   
data.SelectedCh = Temp;
data.FlagSelectedCh = 1;
    
FilterPara = cell(1, numOfChannels); % preallocate cell array, by Wei, 2014-11-05
for i=1:numOfChannels
	FilterPara{i}.A              = 1;
	FilterPara{i}.B              = 1;
	FilterPara{i}.HighValue      = 1;
	FilterPara{i}.LowValue       = 1;
	FilterPara{i}.NotchValue     = 1;
	FilterPara{i}.ScalingFactor  = 1;
    FilterPara{i}.Color      = 'k';
end
data.FilterPara = FilterPara;    

% Get file description, which contains name/date/bytes/isdir/datenum
EdfFileAttributes = dir(filename);
%TODO: determine the total time later from EDF file
data.TotalTime = (EdfFileAttributes.bytes - data.FileInfo.HeaderNumBytes) ...
        / 2  / sum(data.ChInfo.nr) * data.FileInfo.DataRecordDuration;

fprintf('total recording time: %d sec\n',data.TotalTime)

%load actual data
data=DataLoad(data);
%fprintf('Time opening EDF: %d sec\n', round(toc));


%----------------------------------------------------------------- DataLoad
function handles = DataLoad(handles)
% DataLoad rewritten to access data loaded with block load.

% Access epoch (e.g. 30sec)
WindowTime = 120;   %unit=sec
Time = 30;          %unit=sec

FileName = handles.FileName;

fid=fopen(FileName,'r');

SkipByte=handles.FileInfo.HeaderNumBytes+fix(Time/handles.FileInfo.DataRecordDuration) ...
    *sum(handles.ChInfo.nr)*2;
fseek(fid,SkipByte,-1);

% Data=[]; 2014-11-03, preallocate cell array, by Wei
Data = cell(handles.FileInfo.SignalNumbers);
for i=1:handles.FileInfo.SignalNumbers
    Data{i}=[];
end

% Sec/handles.DatarecordDuration is the number of
%%% TODO: HeartBEAT, when WindowTime = 5,
%%% handles.FileInfo.DataRecordDuration = 10, will crash
for i=1 : max(WindowTime/handles.FileInfo.DataRecordDuration, 1) %% added max(), fix crash
    for j=1:handles.FileInfo.SignalNumbers
        Data{j}= [Data{j} fread(fid,[1 handles.ChInfo.nr(j)],'int16') ];
    end
end
fclose('all');

handles.Data = Data;
handles=DataNormalize(handles);
Data = handles.Data;

handles.Data=[];
SelectedCh = handles.SelectedCh;
FilterPara = handles.FilterPara;

% construct the selected referential and differential channels
for i=1:size(SelectedCh,1)
    if SelectedCh(i,2)==0
        % referential
        handles.Data{i}=Data{SelectedCh(i,1)};
    else
        % differential
        handles.Data{i}=Data{SelectedCh(i,1)}-Data{SelectedCh(i,2)};
    end
    
    % Filtering
    handles.Data{i} = filter(FilterPara{i}.B,FilterPara{i}.A,handles.Data{i});
    
end



%----------------------------------------------------------------- DataNormalize
function handles = DataNormalize(handles)

for i=1:length(handles.Data)
    % remove the mean
    handles.Data{i}=handles.Data{i}-(handles.ChInfo.DiMax(i)+handles.ChInfo.DiMin(i))/2;
    handles.Data{i}=handles.Data{i}./(handles.ChInfo.DiMax(i)-handles.ChInfo.DiMin(i));
    if handles.ChInfo.PhyMin(i)>0
        handles.Data{i}=-handles.Data{i};
    end
end
