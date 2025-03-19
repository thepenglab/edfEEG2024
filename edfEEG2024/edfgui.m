function varargout = edfgui(varargin)
% EDFGUI MATLAB code for edfgui.fig
%      EDFGUI, by itself, creates a new EDFGUI or raises the existing
%      singleton*.
%
%      H = EDFGUI returns the handle to a new EDFGUI or the handle to
%      the existing singleton*.
%
%      EDFGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDFGUI.M with the given input arguments.
%
%      EDFGUI('Property','Value',...) creates a new EDFGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before edfgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to edfgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help edfgui

% Last Modified by GUIDE v2.5 24-Apr-2021 15:41:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @edfgui_OpeningFcn, ...
                   'gui_OutputFcn',  @edfgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before edfgui is made visible.
function edfgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to edfgui (see VARARGIN)

% Choose default command line output for edfgui
handles.output = hObject;

% add my init
%init once
handles=initOnce(handles);
%init data
initData();

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes edfgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


%init only once
function handles=initOnce(handles)
versionName='EDF/EDF+ gui v3.0 @2024YP';        %Updated 2024-04-17
setappdata(0,'versionName',versionName);
set(handles.text_versionName,'String',versionName);
setappdata(0,'PathName',[]);
set(handles.text_file_folderName,'String',[]);
%parameters
info=struct();
info.chs=[];
info.eegCh=[1,0];
info.emgCh=[0,0];
info.procWindow=[0,60];         %unit=min
info.binTime=5;                 %unit=sec
info.stepTime=2;                %unit=sec
info.th=[1,1,1];                %threshold for state-detection   
info.autoSaveTag=0;
info.seg=60;
info.clim=[0,2];                    %colormap
info.ylim=[-1000,1000];                 %unit=uv
info.filterEEG=[0.5,50];              %bandpass filter for EEG
info.filterEMG=[1,200];            %bandpass filter for EMG
info.filterNotch=1;                 %notch filter, 1=on, 0=off
info.filterOnOff=1;                 %filter on/off for VIEW-DATA!
info.matFileVersion=0;              %0=original, 1 for modified 
info.xytrackingFile=[];             %csv file with XY tracking from deeplabcut
setappdata(0,'info',info);
%update panel
set(handles.edit_par_binTime,'String',info.binTime);
set(handles.edit_par_stepTime,'String',info.stepTime);
set(handles.checkbox_function_sleep,'Value',1);
set(handles.checkbox_function_SWD,'Value',0);
set(handles.edit_filter_eeg_bandpass1,'String',info.filterEEG(1));
set(handles.edit_filter_eeg_bandpass2,'String',info.filterEEG(2));
set(handles.edit_filter_emg_bandpass1,'String',info.filterEMG(1));
set(handles.edit_filter_emg_bandpass2,'String',info.filterEMG(2));
%figure handles
setappdata(0,'figRawData',[]);
setappdata(0,'figResult',[]);
setappdata(0,'figTraces',[]);
setappdata(0,'figSpectrum',[]);
setappdata(0,'figTh',[]);
setappdata(0,'mscoreSelect',0);     %selected brain states for manual-scoring, 0/1/2=w/nrem/rem
setappdata(0,'anaMode',[1,0,0]);      %sleep / SWD / GTCS for analysis
setappdata(0,'figseizreviewer',[]);
setappdata(0,'cnn_p',0.75);         %probablity of threshold for CNN prediction
setappdata(0,'std_th',1);           %std threshold
setappdata(0,'seizureMethod',1);    %1=std, 2=Kmean,3=CNN


%init the data
function initData()
setappdata(0,'allData',[]);         %original referential signals
setappdata(0,'egDat',[]);           %signals for processing (referential or differential)
setappdata(0,'mgDat',[]);           %signals for processing (referential or differential)
setappdata(0,'specDat',[]);
setappdata(0,'emgAmpDat',[]);
setappdata(0,'state',[]);
setappdata(0,'szEvents',[]);
setappdata(0,'sleepData',[]);       %summary of sleep analysis
setappdata(0,'stiTm',[]);
info=getappdata(0,'info');
info.chs=[];
info.eegCh=[1,0];
info.emgCh=[0,0];
setappdata(0,'info',info);


% --- Executes on button press in pushbutton_file_open.
function pushbutton_file_open_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PathName = getappdata(0,'PathName');
[FileName,PathName,FilterIndex] = uigetfile({'*.edf';'*.mat'},'Select a file',PathName);
fname=fullfile(PathName,FileName);
if FileName==0
    disp('No file seleted!');
    return;
end
%clear all previous data
initData();                 
set(handles.text_file_folderName,'String',fname);
setappdata(0,'PathName',PathName);
setappdata(0,'FileName',FileName);
if contains(FileName,'.mat')
    %load pre-saved mat-file, already fft
    load(fname,'specDat','emgAmpDat','state','info','egDat','mgDat','szEvents');
    setappdata(0,'specDat',specDat);
    setappdata(0,'emgAmpDat',emgAmpDat);
    setappdata(0,'state',state);
    setappdata(0,'szEvents',szEvents);
    setappdata(0,'egDat',egDat);
    setappdata(0,'mgDat',mgDat);
    %update info
    %info2=info;
    %info=getappdata(0,'info');
    %info.binTime=info2.binTime;
    %info.stepTime=info2.stepTime;
    info.PathName=PathName;
    info.FileName=FileName;
    info.matFileVersion=1;
    set(handles.edit_par_binTime,'String',info.binTime);
    set(handles.edit_par_stepTime,'String',info.stepTime);
    %plot data
    plotData(specDat,emgAmpDat,state,[]);
elseif contains(FileName,'.edf') || contains(FileName,'.EDF')
    %load original EDF/EDF+ file
    info=getappdata(0,'info');
    info.PathName=PathName;
    info.FileName=FileName;
    info.matFileVersion=0;
    %read file-header to get some basic information
    tempEdfHandles = EdfInfo(fname);
    info.FileInfo  = tempEdfHandles.FileInfo;
    info.ChInfo    = tempEdfHandles.ChInfo;
    fprintf('File information:\n');
    disp(info.FileInfo);
%     fprintf('%d Labels found in the file:\n',size(info.ChInfo.Labels,1));
%     disp(info.ChInfo.Labels);
    
    info.ChInfo.chNumber=length(info.ChInfo.nr);
    info.fs = info.ChInfo.nr(1)/info.FileInfo.DataRecordDuration;
    info.TotalTime = info.FileInfo.NumberDataRecord*info.FileInfo.DataRecordDuration;
    info.totalHour=info.TotalTime/3600;
    info.stimuli='N/A';
    info.chs=1:info.ChInfo.chNumber;
    labelNum=size(info.ChInfo.Labels,1);
    info.Labels=cell(1,labelNum);
    for i=1:labelNum
        info.Labels{i}=info.ChInfo.Labels(i,:);
    end
    if info.TotalTime/60<info.procWindow(2) || info.procWindow(2)==0
        info.procWindow(2)=(info.TotalTime/60);
        info.seg=info.procWindow(2)-info.procWindow(1);
        set(handles.edit_par_endTime,'String',info.procWindow(2));
    end
    
    %show info
    tmstr=['Date:',info.FileInfo.StartDate,' Time:', info.FileInfo.StartTime];
    set(handles.text_info_startTime,'String',tmstr);
    set(handles.text_info_totalHour,'String',num2str(info.totalHour));
    set(handles.text_info_samplingRate,'String',num2str(info.fs)); 
    set(handles.listbox_info_labels,'String',info.ChInfo.Labels);
    set(handles.listbox_info_labels_selected,'String',info.Labels);
    %update EEG channel listboxes
    updateFileLabelList(handles,info.Labels);
end
%check if there are cvs files in the folder
flist=dir(fullfile(PathName,'*.csv'));
if ~isempty(flist)
    %sort filenames by name
    [~,idx] = natsortfiles({flist.name});
    flist = flist(idx);
    info.xytrackingFile=flist;
end
setappdata(0,'info',info);


function updateFileLabelList(handles,Labels)
if isempty(Labels)
    labels2='N/A';
    refList=labels2;
else
    labels2=Labels;
    refList=cell(1,length(Labels)+1);
    refList{1}='N/A';
    refList(2:end)=Labels;
end
set(handles.listbox_eeg_selected,'String',labels2,'Value',1);
set(handles.listbox_eeg_ref,'String',refList,'Value',1);
set(handles.listbox_emg_selected,'String',refList,'Value',1);
set(handles.listbox_emg_ref,'String',refList,'Value',1);

% --- Executes on button press in pushbutton_file_save.
function pushbutton_file_save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PathName=getappdata(0,'PathName');
specDat=getappdata(0,'specDat');
if isempty(PathName) || isempty(specDat)
    return;
end
emgAmpDat=getappdata(0,'emgAmpDat');
state=getappdata(0,'state');
info=getappdata(0,'info');
egDat=getappdata(0,'egDat');           
mgDat=getappdata(0,'mgDat');          
szEvents=getappdata(0,'szEvents');
%sleepData=getappdata(0,'sleepData');
sleepData=profileSleep(state,info);
% save scoring data into mat-file 
if info.matFileVersion>0
    filename=fullfile(info.PathName,info.FileName);
else
    egName=erase(info.Labels{info.eegCh(1)}," ");
    f0=[egName,'_m',num2str(info.procWindow(1)),'-',num2str(info.procWindow(2)),'.mat'];
    filename=fullfile(PathName,f0);
end
save(filename,'PathName','specDat','emgAmpDat','state','info','egDat','mgDat','szEvents','sleepData');
fprintf('data saved in %s\n',filename);
%also save events into a txt-file
f1=[filename(1:end-4),'.txt'];
save2Txt(szEvents,sleepData,info,f1);


% --- Executes on button press in pushbutton_file_viewData.
function pushbutton_file_viewData_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_viewData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PathName=getappdata(0,'PathName');
if isempty(PathName)
    return;
end
info=getappdata(0,'info');
if isempty(info.chs)
    return;
end
procSec=[info.procWindow(1),info.seg]*60;
%read allData
disp('Loading data, please wait...');
allData=DataLoad(info,procSec);
%split data per animal
%allData=splitData(info,data);

setappdata(0,'allData',allData);
%plot data
allData.fs=info.fs;
allData.filter.OnOff=info.filterOnOff;
allData.filter.EEG=info.filterEEG;
allData.filter.Notch=info.filterNotch;
ShowRawData(allData);
set(handles.edit_par_timescale1,'String',info.procWindow(1));
set(handles.edit_par_timescale2,'String',info.procWindow(2));
setappdata(0,'figWindow',info.procWindow);
disp('Data loaded,please run spectrogram!');

% --- Executes on button press in pushbutton_function_spectrogram.
function pushbutton_function_spectrogram_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_function_spectrogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
if contains(info.FileName,'.mat')
    %do nothing, already done previously
else
    allData=getappdata(0,'allData');
    if isempty(allData)
        msgbox('NO DATA! Please open folder and load data!','warn');
        return;
    end
    %select signals 
    egDat=struct;
    egDat.Tim=allData.Tim;
    egDat.SamplingRate=info.fs;
    eegCh=info.eegCh;
    if length(eegCh)>1 && eegCh(2)>0
        %construct differential signals
        egDat.Data=allData.Data{eegCh(2)}-allData.Data{eegCh(1)};
        egDat.Labels=['Diff_',allData.Labels{eegCh(1)},'-',allData.Labels{eegCh(2)}];
    else
        egDat.Data=allData.Data{eegCh(1)};
        egDat.Labels=allData.Labels{eegCh(1)};
    end
    setappdata(0,'egDat',egDat);
    
    %starting parallel pool
    poolobj=gcp('nocreate');
    if isempty(poolobj) && info.stepTime<=1
        parpool('local');
    end
    %for EEG, get the Spectrum
    %original version
    %pDat=getEEGspec(egDat,info);
    %using parallel (no waitbar)
    pDat=getEEGspec2(egDat,info);
    %std threshold
    std_th = getappdata(0,'std_th');
    dat1=pDat.fseiz;
    dat2=dat1(dat1<mean(dat1)+2*std(dat1));
    pDat.seizTh=mean(dat2)+std_th*std(dat1);
    setappdata(0,'specDat',pDat);
    fprintf('EEG processing done\n');
    %for EMG, get the amplitude
    emgCh=info.emgCh;
    if length(emgCh)>=1
        mgDat=struct;
        mgDat.Tim=allData.Tim;
        mgDat.SamplingRate=info.fs;
        if emgCh(2)>0
            mgDat.Data=allData.Data{emgCh(2)}-allData.Data{emgCh(1)};
            mgDat.Labels=['Diff_',allData.Labels{emgCh(1)},'-',allData.Labels{emgCh(2)}];
        else
            mgDat.Data=allData.Data{emgCh(1)};
            mgDat.Labels=allData.Labels{emgCh(1)};
        end
        mDat=getEMGAmplitude(mgDat,info);
        %add velData to mDat if xy tracking data available, 1/27/2025
        if ~isempty(info.xytrackingFile)
            disp('loading and processing xy tracking.');
            %assume csv files are organized by hourly, and in order
            fnum=round(info.procWindow(1)/60)+1;
            xyfilename=fullfile(info.PathName,info.xytrackingFile(fnum).name);
            [xyDat,velDat]=readXYVelData(xyfilename);
            mDat.velDat=velDat;
            %time to match EEG/EMG
            mDat.velDat(:,1)=info.procWindow(1)*60+velDat(:,1);
            %smooth velDat
            b=info.stepTime*20+1;       %assume frameRate=20;
            mDat.velDat(:,2)=smooth(velDat(:,2),b);
            mDat.xyDat=xyDat;
            disp('velDat done!');
        end
        setappdata(0,'emgAmpDat',mDat);
        setappdata(0,'mgDat',mgDat);
        fprintf('EMG processing done\n');
    else
        mDat=[];
    end
end
%plot data
anaMode=getappdata(0,'anaMode');
if anaMode(1)
    %figure for sleep
    plotData(pDat,mDat,[],[]);
else
    %figure for seizure
    plotData2(pDat,mDat,[],[]);
end

% --- Executes on button press in pushbutton_function_detect.
function pushbutton_function_detect_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_function_detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% main part of the analysis
info=getappdata(0,'info');
pDat=getappdata(0,'specDat');
mDat=getappdata(0,'emgAmpDat');
if isempty(pDat)
    disp('Run Spectrogram first!');
    return;
end
%update std-th
std_th = getappdata(0,'std_th');
dat1=pDat.fseiz;
dat2=dat1(dat1<mean(dat1)+3*std(dat1));
pDat.seizTh=mean(dat2)+std_th*std(dat2);

seizureMethod=getappdata(0,'seizureMethod');
anaMode=getappdata(0,'anaMode');
cnn_p=getappdata(0,'cnn_p');
if anaMode(1)>0
	mode=0;
end
if anaMode(2)>0
	mode=1;
end
if anaMode(3)>0
	mode=2;
end

if seizureMethod==1
	state = getState1(pDat,mDat,mode);
elseif seizureMethod==2
	state = getState2(pDat,mDat,mode);
elseif seizureMethod==3
	trainedNet_File=getappdata(0,'trainedNet_File');
	state=CNNpredictSeizure(pDat,trainedNet_File,cnn_p);
%         state1=state==3;
%         state1=adjustSWD(state1,pDat);
%         state(state1)=3;
end
if anaMode(1)==0
	state(state==1)=0;
else
    sleepData=profileSleep(state,info);
    %dur=getDur(state,info.seg);
    fprintf('Wake/NREM/REM time(min): %8.1f %8.1f %8.1f\n',sleepData.dur);
    setappdata(0,'sleepData',sleepData);
end
setappdata(0,'state',state);

if anaMode(2)>0 || anaMode(3)>0
	szEvents=getszEvents(pDat,state,3);
	setappdata(0,'szEvents',szEvents);
	snum=size(szEvents,1);
	set(handles.edit_fig_events_number,'String',snum);
    fprintf('Detect %d seizure events\n',snum);
	if snum>10
        tnum=10;
    else
        tnum=snum;
    end
    set(handles.edit_fig_traces_number,'String',tnum);
end

%show the result(EEG-spectrogram and EMG)
if info.autoSaveTag
	fn=['eeg',num2str(eegCh),'.png'];
	fname=strcat(folder,fn);
else
    fname=[];
end

%plot data
%reset the stimili-time for current process window
plotData(pDat,mDat,state,fname);


% --- Executes on button press in pushbutton_function_clear.
function pushbutton_function_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_function_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%clear data
initData();
%clear PathName and info
set(handles.text_file_folderName,'String',[]);
%info=getappdata(0,'info');
set(handles.text_info_startTime,'String','');
set(handles.text_info_totalHour,'String','');
set(handles.text_info_samplingRate,'String',''); 
set(handles.listbox_info_labels,'String','N/A','Value',1);
set(handles.listbox_info_labels_selected,'String','N/A','Value',1);
set(handles.listbox_eeg_selected,'String','N/A','Value',1);
set(handles.listbox_eeg_ref,'String','N/A','Value',1);
set(handles.listbox_emg_selected,'String','N/A','Value',1);
set(handles.listbox_emg_ref,'String','N/A','Value',1);
%close all figures
delAllFigs();

function delAllFigs()
figRawData=getappdata(0,'figRawData');
if ~isempty(figRawData)
    delete(figRawData);
    setappdata(0,'figRawData',[]);
end
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    delete(figResult);
    setappdata(0,'figResult',[]);
end
figTh=getappdata(0,'figTh');
if ~isempty(figTh)
    delete(figTh);
    setappdata(0,'figTh',[]);
end
figTraces=getappdata(0,'figTraces');
if ~isempty(figTraces)
    delete(figTraces);
    setappdata(0,'figTraces',[]);
end
figSpectrum=getappdata(0,'figSpectrum');
if ~isempty(figSpectrum)
    delete(figSpectrum);
    setappdata(0,'figSpectrum',[]);
end
h0=getappdata(0,'figseizreviewer');
if ishandle(h0)
	delete(h0);
	setappdata(0,'figseizreviewer',[]);
end


% --- Outputs from this function are returned to the command line.
function varargout = edfgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function edit_par_startTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_startTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_startTime as text
%        str2double(get(hObject,'String')) returns contents of edit_par_startTime as a double
info=getappdata(0,'info');
info.procWindow(1)=str2double(get(hObject,'String'));
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_par_startTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_startTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_par_endTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_endTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_endTime as text
%        str2double(get(hObject,'String')) returns contents of edit_par_endTime as a double
info=getappdata(0,'info');
info.procWindow(2)=str2double(get(hObject,'String'));
info.seg=info.procWindow(2)-info.procWindow(1);
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_par_endTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_endTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_function_seizreviewer.
function checkbox_function_seizreviewer_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_seizreviewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_seizreviewer
global hCurrentEvent;
if get(hObject,'Value')
    h0=getappdata(0,'figseizreviewer');
    if isempty(h0)
        h=seizreviewer();
        setappdata(0,'figseizreviewer',h);
    end
else
    if ishandle(hCurrentEvent)
        delete(hCurrentEvent);
    end
    h0=getappdata(0,'figseizreviewer');
    if ishandle(h0)
        delete(h0);
        setappdata(0,'figseizreviewer',[]);
    end
end


% --- Executes on button press in checkbox_function_autoSave.
function checkbox_function_autoSave_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_autoSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_autoSave
setappdata(0,'autoSaveTag',get(hObject,'Value'));

function edit_par_binTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_binTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_binTime as text
%        str2double(get(hObject,'String')) returns contents of edit_par_binTime as a double
info=getappdata(0,'info');
info.binTime=str2double(get(hObject,'String'));
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_par_binTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_binTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_par_stepTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_stepTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_stepTime as text
%        str2double(get(hObject,'String')) returns contents of edit_par_stepTime as a double
info=getappdata(0,'info');
info.stepTime=str2double(get(hObject,'String'));
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_par_stepTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_stepTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_mscore_mark.
function pushbutton_mscore_mark_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_mscore_mark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    set(0,'currentfigure',figResult);
    [x,y]=ginput(2);
    x1=max(round(min(x)),1);
    y1=0.5;   %y1=min(y);
    w=round(abs(x(2)-x(1)));
    h=1;    %h=abs(y(2)-y(1));
    ROI=[x1,y1,w,h];
    mymap=[0.5,0.5,0.5;1,0.5,0;0.6,0.2,1;...
        1,1,0;1,0.5,1;1,0,0.5;0,0,0];
    %mark the event in figResult
    mscoreSelect=getappdata(0,'mscoreSelect');
    if mscoreSelect>=0
        cl=mymap(mscoreSelect+1,:);
    else
        cl=mymap(7,:);
    end
    set(0,'currentfigure',figResult);
    rectangle('position',ROI,'FaceColor',cl,'EdgeColor',cl);
    %update state based on scoring
    state=getappdata(0,'state');
    state(x1:x1+w)=mscoreSelect;
    info=getappdata(0,'info');
    dur=getDur(state,info.seg);
    fprintf('Wake/NREM/REM time(min): %5.1f,%5.1f,%5.1f\n',dur);
    setappdata(0,'state',state);
end


function dur=getDur(state,seg)
%calculate time for each state
idx1=find(state==0);
idx2=find(state==1);
idx3=find(state==2);
dur=[length(idx1),length(idx2),length(idx3)]*seg/length(state);


% --- Executes on button press in checkbox_function_mscore.
function checkbox_function_mscore_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_mscore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_mscore
if get(hObject,'Value')
    set(handles.pushbutton_mscore_mark,'enable','on');
else
    set(handles.pushbutton_mscore_mark,'enable','off');
end


% --- Executes when selected object is changed in uibuttongroup_states.
function uibuttongroup_states_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup_states 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Tag')
    case 'radiobutton_wake'
        val=0;
    case 'radiobutton_nrem'
        val=1;
    case 'radiobutton_rem'
        val=2;
    case 'radiobutton_SWD'
        val=3;
    case 'radiobutton_GTCS'
        val=4;
    case 'radiobutton_TS'
        val=5;
    case 'radiobutton_unknown'
        val=-1;
end
setappdata(0,'mscoreSelect',val);



function edit_fig_clim_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fig_clim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fig_clim as text
%        str2double(get(hObject,'String')) returns contents of edit_fig_clim as a double
clm=str2double(get(hObject,'String'));
if clm<=0
    disp('CLim cannot be set below 0');
    return;
end
info=getappdata(0,'info');
info.clim=[0,clm];
setappdata(0,'info',info);
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    if ishandle(figResult)
        set(0,'currentfigure',figResult);
        set(figResult.Children(end-1),'clim',[0,clm]);
    end
end
setappdata(0,'specClim',clm);

% --- Executes during object creation, after setting all properties.
function edit_fig_clim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fig_clim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_fig_ylim_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fig_ylim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fig_ylim as text
%        str2double(get(hObject,'String')) returns contents of edit_fig_ylim as a double
ylm=str2double(get(hObject,'String'));
info=getappdata(0,'info');
info.ylim=[-ylm,ylm];
setappdata(0,'info',info);
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    if ishandle(figResult)
        set(0,'currentfigure',figResult);
        if length(figResult.Children)==3
            set(figResult.Children(1),'ylim',[0,ylm]);
        elseif length(figResult.Children)==4
            set(figResult.Children(2),'ylim',[-ylm,ylm]);
        end
    end
end

% --- Executes during object creation, after setting all properties.
function edit_fig_ylim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fig_ylim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_fig_power1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fig_power1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fig_power1 as text
%        str2double(get(hObject,'String')) returns contents of edit_fig_power1 as a double
ylm=str2double(get(hObject,'String'));
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    if ishandle(figResult)
        set(0,'currentfigure',figResult);
        set(figResult.Children(1),'ylim',[0,ylm]);
    end
end

% --- Executes during object creation, after setting all properties.
function edit_fig_power1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fig_power1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pushbutton_next_seg.
function pushbutton_next_seg_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next_seg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
proc=info.procWindow;
proc=proc+proc(2)-proc(1);
info.procWindow=proc;
setappdata(0,'info',info);
set(handles.edit_par_startTime,'String',num2str(proc(1)));
set(handles.edit_par_endTime,'String',num2str(proc(2)));

% --- Executes on button press in pushbutton_previous_seg.
function pushbutton_previous_seg_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_previous_seg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
proc=info.procWindow;
if proc(1)-(proc(2)-proc(1))>=0
    proc=proc-(proc(2)-proc(1));
    info.procWindow=proc;
    setappdata(0,'info',info);
    set(handles.edit_par_startTime,'String',num2str(proc(1)));
    set(handles.edit_par_endTime,'String',num2str(proc(2)));
end


% --- Executes on button press in checkbox_function_sleep.
function checkbox_function_sleep_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_sleep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_sleep
anaMode=getappdata(0,'anaMode');
anaMode(1)=get(hObject,'Value');
setappdata(0,'anaMode',anaMode);
%also adjust binTime and stepTime
if anaMode(1)==1 && anaMode(2)==0
    info=getappdata(0,'info');
    info.binTime=5;
    info.stepTime=2;
    setappdata(0,'info',info);
    set(handles.edit_par_binTime,'String',info.binTime);
    set(handles.edit_par_stepTime,'String',info.stepTime);
end

% --- Executes on button press in checkbox_function_SWD.
function checkbox_function_SWD_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_SWD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_SWD
anaMode=getappdata(0,'anaMode');
anaMode(2)=get(hObject,'Value');
setappdata(0,'anaMode',anaMode);
%also adjust binTime and stepTime
if anaMode(2)
    info=getappdata(0,'info');
    info.binTime=1;
    info.stepTime=0.25;
    setappdata(0,'info',info);
    set(handles.edit_par_binTime,'String',1);
    set(handles.edit_par_stepTime,'String',0.25);
    setappdata(0,'std_th',1);           %std threshold
    set(handles.edit_STD_threshold,'String',1);
    %starting parallel pool
    poolobj=gcp('nocreate');
    if isempty(poolobj)
	    parpool('local','IdleTimeout', 120);
    end
end

% --- Executes on button press in checkbox_function_GTCS.
function checkbox_function_GTCS_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_function_GTCS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_function_GTCS
anaMode=getappdata(0,'anaMode');
anaMode(3)=get(hObject,'Value');
setappdata(0,'anaMode',anaMode);
%also adjust binTime and stepTime
if anaMode(3)
    info=getappdata(0,'info');
    info.binTime=2;
    info.stepTime=1;
    setappdata(0,'info',info);
    set(handles.edit_par_binTime,'String',2);
    set(handles.edit_par_stepTime,'String',1);
    setappdata(0,'std_th',5);           %std threshold
    set(handles.edit_STD_threshold,'String',5);
end


function edit_CNN_pThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_CNN_pThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_CNN_pThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_CNN_pThreshold as a double
cnn_p=str2double(get(hObject,'String'));
setappdata(0,'cnn_p',cnn_p);
pDat=getappdata(0,'specDat');
trainedNet_File=getappdata(0,'trainedNet_File');
state=CNNpredictSeizure(pDat,trainedNet_File,cnn_p);
szEvents=getszEvents(pDat,state,3);
setappdata(0,'szEvents',szEvents);
setappdata(0,'state',state);
plotData(pDat,[],state,[]);

% --- Executes during object creation, after setting all properties.
function edit_CNN_pThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_CNN_pThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_STD_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_STD_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_STD_threshold as text
%        str2double(get(hObject,'String')) returns contents of edit_STD_threshold as a double
std_th=str2double(get(hObject,'String'));
setappdata(0,'std_th',std_th);           


% --- Executes during object creation, after setting all properties.
function edit_STD_threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_STD_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uibuttongroup_seizureMethod.
function uibuttongroup_seizureMethod_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup_seizureMethod 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Tag')
    case 'radiobutton_seizure_method_STD'
        seizureMethod=1;
    case 'radiobutton_seizure_method_kmean'
        seizureMethod=2;
    case 'radiobutton_seizure_method_CNN'
        seizureMethod=3;
        setCNNtype(handles);
end
setappdata(0,'seizureMethod',seizureMethod);


function setCNNtype(handles)
anaMode=getappdata(0,'anaMode');
if anaMode(2)
	defaultNet='swdNet.mat';
elseif anaMode(3)
	defaultNet='gtcsNet.mat';
else
	disp('Please select seizure type!');
	set(handles.text_function_trainedNet,'String','Net = None');
	return;
end
if ~isempty(dir(defaultNet))
	setappdata(0,'trainedNet_File',defaultNet);
	set(handles.text_function_trainedNet,'String',['Net = ',defaultNet]);
end
    


% --- Executes on button press in checkbox_fig_spectrum.
function checkbox_fig_spectrum_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_fig_spectrum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_fig_spectrum
if get(hObject,'Value')
    state=getappdata(0,'state');
    specDat=getappdata(0,'specDat');
    if ~isempty(specDat)
        ShowSpectrum(state,specDat)
    end
else
    figSpectrum=getappdata(0,'figSpectrum');
    if ishandle(figSpectrum)
        delete(figSpectrum);
    end
end


% --- Executes on button press in checkbox_fig_traces.
function checkbox_fig_traces_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_fig_traces (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_fig_traces
if get(hObject,'Value')
    szEvents=getappdata(0,'szEvents');
    specDat=getappdata(0,'specDat');
    if ~isempty(szEvents)
        tnum=str2double(get(handles.edit_fig_traces_number,'String'));
        snum=size(szEvents,1);
        %update in case changed during reviewing
        set(handles.edit_fig_events_number,'String',snum);
        if snum>=tnum
            szEvents2=szEvents(1:tnum,:);
        else
            szEvents2=szEvents;
            set(handles.edit_fig_traces_number,'String',snum);
        end
        ShowTraces(szEvents2,specDat)
    end
else
    figTraces=getappdata(0,'figTraces');
    if ishandle(figTraces)
        delete(figTraces);
    end
end


function edit_fig_events_number_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fig_events_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fig_events_number as text
%        str2double(get(hObject,'String')) returns contents of edit_fig_events_number as a double


% --- Executes during object creation, after setting all properties.
function edit_fig_events_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fig_events_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_fig_traces_number_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fig_traces_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fig_traces_number as text
%        str2double(get(hObject,'String')) returns contents of edit_fig_traces_number as a double
snum1=str2double(get(hObject,'String'));
szEvents=getappdata(0,'szEvents');
if snum1>size(szEvents,1)
    snum1=size(szEvents,1);
    set(hObject,'String',snum1);
end

% --- Executes during object creation, after setting all properties.
function edit_fig_traces_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fig_traces_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_info_labels_selected.
function listbox_info_labels_selected_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_info_labels_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_info_labels_selected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_info_labels_selected


% --- Executes during object creation, after setting all properties.
function listbox_info_labels_selected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_info_labels_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_labels_removeAll.
function pushbutton_labels_removeAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_labels_removeAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
info.chs=[];
info.Labels=[];
info.eegCh=[1,0];
info.emgCh=[];
setappdata(0,'info',info);
set(handles.listbox_info_labels_selected,'String',[],'Value',1);
%update EEG channel listboxes
updateFileLabelList(handles,info.Labels);


% --- Executes on button press in pushbutton_labels_remove.
function pushbutton_labels_remove_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_labels_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val=get(handles.listbox_info_labels_selected,'value');
info=getappdata(0,'info');
idx=find(info.chs~=info.chs(val));
info.chs=info.chs(idx);
lnums=1:length(info.Labels);
idx2=find(lnums~=val);
info.Labels=info.Labels(idx2);
info.eegCh=[1,0];
info.emgCh=[];
setappdata(0,'info',info);
val2=max(val-1,1);
set(handles.listbox_info_labels_selected,'String',info.Labels,'Value',val2);
%update EEG channel listboxes
updateFileLabelList(handles,info.Labels);

% --- Executes on button press in pushbutton_labels_add.
function pushbutton_labels_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_labels_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val=get(handles.listbox_info_labels,'value');
info=getappdata(0,'info');
idx=find(info.chs==val);
if isempty(idx)
    info.chs(end+1)=val;
    info.Labels{end+1}=info.ChInfo.Labels(val,:);
end
setappdata(0,'info',info);
set(handles.listbox_info_labels_selected,'String',info.Labels);
%update EEG channel listboxes
updateFileLabelList(handles,info.Labels);


% --- Executes on button press in pushbutton_labels_addAll.
function pushbutton_labels_addAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_labels_addAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
labelNum=size(info.ChInfo.Labels,1);
info.Labels=cell(1,labelNum);
for i=1:labelNum
    info.Labels{i}=info.ChInfo.Labels(i,:);
end
info.chs=1:labelNum;
info.eegCh=[1,0];
info.emgCh=[];
setappdata(0,'info',info);
set(handles.listbox_info_labels_selected,'String',info.Labels,'Value',1);
%update EEG channel listboxes
updateFileLabelList(handles,info.Labels);


% --- Executes on selection change in listbox_eeg_selected.
function listbox_eeg_selected_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_eeg_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_eeg_selected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_eeg_selected
val=get(hObject,'Value');
info=getappdata(0,'info');
info.eegCh(1)=val;
setappdata(0,'info',info);


% --- Executes during object creation, after setting all properties.
function listbox_eeg_selected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_eeg_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_eeg_ref.
function listbox_eeg_ref_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_eeg_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_eeg_ref contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_eeg_ref
val=get(hObject,'Value');
info=getappdata(0,'info');
info.eegCh(2)=val-1;
setappdata(0,'info',info);


% --- Executes during object creation, after setting all properties.
function listbox_eeg_ref_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_eeg_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_emg_selected.
function listbox_emg_selected_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_emg_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_emg_selected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_emg_selected
val=get(hObject,'Value');
info=getappdata(0,'info');
info.emgCh(1)=val-1;
setappdata(0,'info',info);


% --- Executes during object creation, after setting all properties.
function listbox_emg_selected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_emg_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_emg_ref.
function listbox_emg_ref_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_emg_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_emg_ref contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_emg_ref
val=get(hObject,'Value');
info=getappdata(0,'info');
info.emgCh(2)=val-1;
setappdata(0,'info',info);


% --- Executes during object creation, after setting all properties.
function listbox_emg_ref_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_emg_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_filter_eeg_bandpass1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filter_eeg_bandpass1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filter_eeg_bandpass1 as text
%        str2double(get(hObject,'String')) returns contents of edit_filter_eeg_bandpass1 as a double
info=getappdata(0,'info');
info.filterEEG(1)=str2double(get(hObject,'String')); 
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_filter_eeg_bandpass1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filter_eeg_bandpass1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_filter_eeg_bandpass2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filter_eeg_bandpass2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filter_eeg_bandpass2 as text
%        str2double(get(hObject,'String')) returns contents of edit_filter_eeg_bandpass2 as a double
info=getappdata(0,'info');
info.filterEEG(2)=str2double(get(hObject,'String')); 
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_filter_eeg_bandpass2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filter_eeg_bandpass2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_filter_emg_bandpass1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filter_emg_bandpass1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filter_emg_bandpass1 as text
%        str2double(get(hObject,'String')) returns contents of edit_filter_emg_bandpass1 as a double
info=getappdata(0,'info');
info.filterEMG(1)=str2double(get(hObject,'String')); 
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_filter_emg_bandpass1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filter_emg_bandpass1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_filter_emg_bandpass2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filter_emg_bandpass2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filter_emg_bandpass2 as text
%        str2double(get(hObject,'String')) returns contents of edit_filter_emg_bandpass2 as a double
info=getappdata(0,'info');
info.filterEMG(2)=str2double(get(hObject,'String')); 
setappdata(0,'info',info);

% --- Executes during object creation, after setting all properties.
function edit_filter_emg_bandpass2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filter_emg_bandpass2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_filter_notch.
function checkbox_filter_notch_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_filter_notch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_filter_notch
info=getappdata(0,'info');
info.filterNotch=get(hObject,'Value'); 
setappdata(0,'info',info);

% --- Executes on button press in checkbox_filter_onoff.
function checkbox_filter_onoff_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_filter_onoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_filter_onoff
info=getappdata(0,'info');
info.filterOnOff=get(hObject,'Value'); 
setappdata(0,'info',info);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% del all-variables from memory (big ones)
rmappdata(0,'allData');         %original referential signals
rmappdata(0,'egDat');           %signals for processing (referential or differential)
rmappdata(0,'mgDat');           %signals for processing (referential or differential)
rmappdata(0,'specDat');
rmappdata(0,'emgAmpDat');
rmappdata(0,'state');
rmappdata(0,'szEvents');
rmappdata(0,'info');
%del all figures
delAllFigs();
%stop parallel
delete(gcp('nocreate'));



function edit_par_timescale1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_timescale1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_timescale1 as text
%        str2double(get(hObject,'String')) returns contents of edit_par_timescale1 as a double
tm0=getappdata(0,'figWindow');
tm0(1)=str2double(get(hObject,'String'));
setappdata(0,'figWindow',tm0);
rescaleFigTime(tm0);

% --- Executes during object creation, after setting all properties.
function edit_par_timescale1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_timescale1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_par_timescale2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_par_timescale2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_par_timescale2 as text
%        str2double(get(hObject,'String')) returns contents of edit_par_timescale2 as a double
tm0=getappdata(0,'figWindow');
tm0(2)=str2double(get(hObject,'String'));
setappdata(0,'figWindow',tm0);
rescaleFigTime(tm0);

% --- Executes during object creation, after setting all properties.
function edit_par_timescale2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_par_timescale2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_fig_reset.
function pushbutton_fig_reset_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_fig_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getappdata(0,'info');
tm0=info.procWindow;
setappdata(0,'figWindow',tm0);
rescaleFigTime(tm0);
set(handles.edit_par_timescale1,'String',tm0(1));
set(handles.edit_par_timescale2,'String',tm0(2));

% --- Executes on button press in pushbutton_fig_nextSegment.
function pushbutton_fig_nextSegment_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_fig_nextSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tm0=getappdata(0,'figWindow');
d=tm0(2)-tm0(1);
info=getappdata(0,'info');
procWindow=info.procWindow;  
if tm0(2)+d<=procWindow(2)
    tm0=tm0+d;
    setappdata(0,'figWindow',tm0);
    rescaleFigTime(tm0);
    set(handles.edit_par_timescale1,'String',tm0(1));
    set(handles.edit_par_timescale2,'String',tm0(2));
end

% --- Executes on button press in pushbutton_fig_preSegment.
function pushbutton_fig_preSegment_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_fig_preSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tm0=getappdata(0,'figWindow');
d=tm0(2)-tm0(1);
info=getappdata(0,'info');
procWindow=info.procWindow;  
if tm0(1)-d>=procWindow(1)
    tm0=tm0-d;
    setappdata(0,'figWindow',tm0);
    rescaleFigTime(tm0);
    set(handles.edit_par_timescale1,'String',tm0(1));
    set(handles.edit_par_timescale2,'String',tm0(2));
end
