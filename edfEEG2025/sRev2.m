function varargout = sRev2(varargin)
% SREV2 MATLAB code for sRev2.fig
%      SREV2, by itself, creates a new SREV2 or raises the existing
%      singleton*.
%
%      H = SREV2 returns the handle to a new SREV2 or the handle to
%      the existing singleton*.
%
%      SREV2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SREV2.M with the given input arguments.
%
%      SREV2('Property','Value',...) creates a new SREV2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sRev2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sRev2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sRev2

% Last Modified by GUIDE v2.5 13-Nov-2024 10:03:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sRev2_OpeningFcn, ...
                   'gui_OutputFcn',  @sRev2_OutputFcn, ...
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


% --- Executes just before sRev2 is made visible.
function sRev2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sRev2 (see VARARGIN)

% Choose default command line output for sRev2
handles.output = hObject;
%init data
init();

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes sRev2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = sRev2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function init()
setappdata(0,'PathName',[]);
setappdata(0,'FileName',[]);
setappdata(0,'FileList',[]);
setappdata(0,'FileListIndex',0);
setappdata(0,'mscoreSelect',1);
setappdata(0,'dataFormat',2);
setappdata(0,'procWindow',[0,60]);   
setappdata(0,'figWindow',[0,60]);   %unit=min, for figure-result
setappdata(0,'figResult',[]);
setappdata(0,'climmax',2);


% --- Executes on button press in pushbutton_file_open.
function pushbutton_file_open_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PathName=getappdata(0,'PathName');
if ~isempty(PathName)
    f0=fullfile(PathName,'*.mat');
else
    f0='*.mat';
end
[FileName,PathName] = uigetfile(f0,'Select a matlab file',PathName);
fname=fullfile(PathName,FileName);
fileKeys='eeg'; %default
%fileKeys='dat_';    %older files
if FileName==0
    disp('No file seleted!');
    return;
else
    %get file list
    list=dir(PathName);
    %sort fileanme by date-modifed
    %[~,idx] = sort([list.datenum]);
    %sort filenames by name 
    [~,idx] = natsortfiles({list.name});
    list = list(idx);
    FileList={};
    fIdx=1;
    k=0;
    for i=1:length(list)
        if contains(list(i).name,'.mat') && contains(lower(list(i).name),fileKeys)
            k=k+1;
            FileList{k}=list(i).name;
            if strcmpi(FileName,FileList{k})
                fIdx=k;
            end
        end
    end

    setappdata(0,'FileList',FileList);
    setappdata(0,'FileListIndex',fIdx);
    setappdata(0,'FileName',FileName);
    setappdata(0,'PathName',PathName);
    set(handles.text_file_name,'String',fname);
    %show figure
    loadData(fname);
    %update procWindow
    procWindow=getappdata(0,'procWindow');
    set(handles.edit_par_timescale1,'String',procWindow(1));
    set(handles.edit_par_timescale2,'String',procWindow(2));
end

function loadData(fname)
dataFormat=getappdata(0,'dataFormat');
if dataFormat==1
    %dataset from tdtEventEEG/nlxEventEEG
    load(fname,'pDat','mDat','state','info');
elseif dataFormat==2
    %dataset from tdtEEGgui/nlxEEGgui
    %data about seizures
    state_Seizure=[];
    state_Sleep=[];
    szEvents=[];
    load(fname,'specDat','emgAmpDat','state','info',...
        'state_Seizure','state_Sleep','szEvents');
    pDat=specDat;
    mDat=emgAmpDat;
    if isempty(state_Sleep)
        state_Sleep=state;
    end
    if isempty(state_Seizure)
        state_Seizure=state*0;
    end
end
if ~isfield(info,'stepTime')
    info.stepTime=2;
end
if ~isfield(info,'stiTm')
    info.stiTm=[];
else
    if length(info.stiTm)==1
        info.stiTm(2)=info.stiTm(1);
    end
end
if ~isfield(info,'procWindow')
    info.procWindow=[mDat.Tm(1),mDat.Tm(end)]/60;
end
%re-do EMG filtering if needed
% redoEMG=0;
% if redoEMG
%     info.filterEMG=[30,300];
%     mgDat.fs=info.samplingRate;
%     mgDat.data=emgAmpDat.fEMG(2,:);
%     mgDat.tm=emgAmpDat.fEMG(1,:);
%     mDat=getEMGAmplitude(mgDat,info);
% end
sleepData=profileSleep(state,info);
setappdata(0,'pDat',pDat);
setappdata(0,'mDat',mDat);
setappdata(0,'state',state);
setappdata(0,'state_Seizure',state_Seizure);
setappdata(0,'state_Sleep',state_Sleep);
setappdata(0,'szEvents',szEvents);
setappdata(0,'info',info);
setappdata(0,'sleepData',sleepData);
setappdata(0,'procWindow',info.procWindow);
%setappdata(0,'procWindow',info.procWindow-info.procWindow(1));
setappdata(0,'figWindow',info.procWindow);
%show result
if isfield(info,'stiTm')
	st1=info.stiTm;
    %st1=(info.procWindow(1)+[5,7])*60;
    %st1=mDat.Tm(1)+info.stiTm;
else
	st1=(info.procWindow(1)+[5,7])*60;
end
plotData(pDat,mDat,state,[]);
%plotData3(pDat,mDat,state,[]);
%plotData2b(pDat,mDat,[],state,[]);

% --- Executes on button press in pushbutton_file_previous.
function pushbutton_file_previous_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fIdx=getappdata(0,'FileListIndex');
FileList=getappdata(0,'FileList');
if fIdx>1
    fIdx2=fIdx-1;
    filename=FileList{fIdx2};
    setappdata(0,'FileListIndex',fIdx2);
    setappdata(0,'FileName',filename);
    PathName=getappdata(0,'PathName');
    fname=fullfile(PathName,filename);
    set(handles.text_file_name,'String',fname);
    loadData(fname);
    %update procWindow
    procWindow=getappdata(0,'procWindow');
    set(handles.edit_par_timescale1,'String',procWindow(1));
    set(handles.edit_par_timescale2,'String',procWindow(2));
end

% --- Executes on button press in pushbutton_file_next.
function pushbutton_file_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fIdx=getappdata(0,'FileListIndex');
FileList=getappdata(0,'FileList');
if fIdx<length(FileList)
    fIdx2=fIdx+1;
    filename=FileList{fIdx2};
    setappdata(0,'FileListIndex',fIdx2);
    setappdata(0,'FileName',filename);
    PathName=getappdata(0,'PathName');
    fname=fullfile(PathName,filename);
    set(handles.text_file_name,'String',fname);
    loadData(fname);
    %update procWindow
    procWindow=getappdata(0,'procWindow');
    set(handles.edit_par_timescale1,'String',procWindow(1));
    set(handles.edit_par_timescale2,'String',procWindow(2));
end

% --- Executes on button press in pushbutton_file_save.
function pushbutton_file_save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PathName=getappdata(0,'PathName');
FileName=getappdata(0,'FileName');
dataFormat=getappdata(0,'dataFormat');
%f2=[FileName(1:end-4),'_m.mat'];
fname2=fullfile(PathName,FileName);
%data to save
pDat=getappdata(0,'pDat');
mDat=getappdata(0,'mDat');
state=getappdata(0,'state');
info=getappdata(0,'info');
state_Seizure=getappdata(0,'state_Seizure');
state_Sleep=getappdata(0,'state_Sleep');
szEvents=getappdata(0,'szEvents');

if dataFormat==1
    %data-format from tdtEventEEG/nlxEventEEG
    save(fname2,'pDat','mDat','state','info');
elseif dataFormat==2
    %data-format from tdtEEGgui/nlxEEGgui
    specDat=pDat;
    emgAmpDat=mDat;
    %sleepData=getappdata(0,'sleepData');
    sleepData=profileSleep(state_Sleep,info);
    %re-calculate szEvents;
    %state_Seizure=state==3;
    blks=getBlocks(state_Seizure,1);
    if ~isempty(blks)
        szEvents=blks;
        %szEvents(:,2:3)=blks(:,2:3)*info.stepTime;
        szEvents(:,2:3)=pDat.t(blks(:,2:3));
        szEvents(:,4)=szEvents(:,3)-szEvents(:,2);
    end
    save(fname2,'specDat','emgAmpDat','state','info','sleepData',...
        'state_Sleep','state_Seizure','szEvents');
end
fprintf('data saved in %s\n',fname2);
%also save modifed figure
fname3=[fname2(1:end-4),'.tif'];
%st1=mDat.Tm(1)+info.stiTm;
st1=info.stiTm;
plotData(pDat,mDat,state,st1,fname3);
%plotData3(pDat,mDat,state,st1,fname3);
 
% --- Executes on button press in pushbutton_modify.
function pushbutton_modify_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_modify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    state=getappdata(0,'state');
    state_Seizure=getappdata(0,'state_Seizure');
    state_Sleep=getappdata(0,'state_Sleep');
    set(0,'currentfigure',figResult);
    h_axes=findobj(figResult,'type','axes');
    axes(h_axes(end));
    [x,y]=ginput(2);
    x1=max(round(min(x)),1);
    x2=min(round(max(x)),length(state));
    y1=0;       %y1=min(y);
    w=round(x2-x1);
    h=2;            %h=abs(y(2)-y(1));
    ROI=[x1,y1,w,h];
    mymap=[0.5,0.5,0.5;1,0.5,0;0.6,0.2,1;0,0,0];
    %mark the event in figResult
    mscoreSelect=getappdata(0,'mscoreSelect');
    if mscoreSelect>=0
        cl=mymap(mscoreSelect+1,:);
    else
        cl=mymap(4,:);
    end
    
    rectangle('position',ROI,'FaceColor',cl,'EdgeColor',cl);
    %update state based on scoring
    state(x1:x1+w)=mscoreSelect;
    if mscoreSelect==3
        state_Seizure(x1:x1+w)=1;
    else
        state_Sleep(x1:x1+w)=mscoreSelect;
    end
    setappdata(0,'state',state);
    setappdata(0,'state_Seizure',state_Seizure);
    setappdata(0,'state_Sleep',state_Sleep);
    %show modified results
    procWindow=getappdata(0,'procWindow');
    dur=getDur(state,procWindow);
    fprintf('Wake/NREM/REM/unknown time(min): %5.2f %5.2f %5.2f %5.2f\n',dur);
end

function dur=getDur(state,procWindow)
%calculate time for each state
idx1=find(state==0);
idx2=find(state==1);
idx3=find(state==2);
idx4=find(state==-1 | state==3);
seg=procWindow(2)-procWindow(1);
dur=[length(idx1),length(idx2),length(idx3),length(idx4)]*seg/length(state);

% --- Executes when selected object is changed in uibuttongroup1.
function uibuttongroup1_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup1 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Tag')
    case 'radiobutton_state_wake'
        val=0;
    case 'radiobutton_state_nrem'
        val=1;
    case 'radiobutton_state_rem'
        val=2;
    case 'radiobutton_stateX'
        val=3;
end
setappdata(0,'mscoreSelect',val);


% --- Executes on button press in pushbutton_file_clear.
function pushbutton_file_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_file_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    delete(figResult);
    setappdata(0,'figResult',[]);
end


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
tm0=getappdata(0,'procWindow');   
setappdata(0,'figWindow',tm0);
rescaleFigTime(tm0);
set(handles.edit_par_timescale1,'String',tm0(1));
set(handles.edit_par_timescale2,'String',tm0(2));


% function rescaleFigTime(xlm)
% figResult=getappdata(0,'figResult');
% procWindow=getappdata(0,'procWindow');  
% state=getappdata(0,'state');
% xlm2=0.5+(xlm-procWindow(1))*length(state)/(procWindow(2)-procWindow(1));
% if ~isempty(figResult)
%     if ishandle(figResult)
%         set(0,'currentfigure',figResult);
%         h_axes=findobj(figResult,'type','axes');
%         %h_axes=get(figResult,'Children');
%         for i=1:length(h_axes)
%             ylm0=get(h_axes(i),'ylim');
%             dylm=ylm0(2)-ylm0(1);
%             if dylm==1 || dylm==101
%                 set(h_axes(i),'xlim',xlm2);
%             else
%                 set(h_axes(i),'xlim',xlm);
%             end
%         end
%     end
% end


% --- Executes when selected object is changed in uibuttongroup2.
function uibuttongroup2_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup2 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Tag')
    case 'radiobutton_dataFormat1'
        val=1;
    case 'radiobutton_dataFormat2'
        val=2;
end
setappdata(0,'dataFormat',val);


% --- Executes on button press in pushbutton_timescale_pre.
function pushbutton_timescale_pre_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_timescale_pre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tm0=getappdata(0,'figWindow');
d=tm0(2)-tm0(1);
procWindow=getappdata(0,'procWindow');  
if tm0(1)-d>=procWindow(1)
    tm0=tm0-d;
    setappdata(0,'figWindow',tm0);
    rescaleFigTime(tm0);
    set(handles.edit_par_timescale1,'String',tm0(1));
    set(handles.edit_par_timescale2,'String',tm0(2));
end

% --- Executes on button press in pushbutton_timescale_next.
function pushbutton_timescale_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_timescale_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tm0=getappdata(0,'figWindow');
d=tm0(2)-tm0(1);
procWindow=getappdata(0,'procWindow');  
if tm0(2)+d<=procWindow(2)
    tm0=tm0+d;
    setappdata(0,'figWindow',tm0);
    rescaleFigTime(tm0);
    set(handles.edit_par_timescale1,'String',tm0(1));
    set(handles.edit_par_timescale2,'String',tm0(2));
end



function edit_climmax_Callback(hObject, eventdata, handles)
% hObject    handle to edit_climmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_climmax as text
%        str2double(get(hObject,'String')) returns contents of edit_climmax as a double
clm=str2double(get(hObject,'String'));
if clm<=0
    disp('CLim cannot be set below 0');
    return;
end
figResult=getappdata(0,'figResult');
if ~isempty(figResult)
    if ishandle(figResult)
        set(0,'currentfigure',figResult);
        set(figResult.Children(end-1),'clim',[0,clm]);
    end
end


% --- Executes during object creation, after setting all properties.
function edit_climmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_climmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','2');
