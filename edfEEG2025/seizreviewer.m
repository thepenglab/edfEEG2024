function varargout = seizreviewer(varargin)
% SEIZREVIEWER MATLAB code for seizreviewer.fig
%      SEIZREVIEWER, by itself, creates a new SEIZREVIEWER or raises the existing
%      singleton*.
%
%      H = SEIZREVIEWER returns the handle to a new SEIZREVIEWER or the handle to
%      the existing singleton*.
%
%      SEIZREVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEIZREVIEWER.M with the given input arguments.
%
%      SEIZREVIEWER('Property','Value',...) creates a new SEIZREVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before seizreviewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to seizreviewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help seizreviewer

% Last Modified by GUIDE v2.5 20-Feb-2020 13:02:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @seizreviewer_OpeningFcn, ...
                   'gui_OutputFcn',  @seizreviewer_OutputFcn, ...
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


% --- Executes just before seizreviewer is made visible.
function seizreviewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to seizreviewer (see VARARGIN)

% Choose default command line output for seizreviewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes seizreviewer wait for user response (see UIRESUME)
% uiwait(handles.figure_SWDreview);
init(handles);


%get data from main-function
function init(handles)
global hCurrentEvent;
%anaMode=getappdata(0,'anaMode');
szEvents=getappdata(0,'szEvents');
allN=size(szEvents,1);
%szType={'SWD','GTCS/TS'};
set(handles.text_info,'String',['Reviewing ',num2str(allN),' ','SWD',' Events...']);
if ~isempty(szEvents)
    plotEEGtrace(handles);
    %highlight current event in figResult
    figResult=getappdata(0,'figResult');
    if ishandle(figResult)
    	set(0,'currentfigure',figResult);
    	hold on;
        %hCurrentEvent=plot(szEvents(1,2)/60,0,'*r','Markersize',8);
        hCurrentEvent=rectangle('position',[szEvents(1,2)/60,0,szEvents(1,4)/60,10],'EdgeColor','r');
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = seizreviewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_previous.
function pushbutton_previous_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hCurrentEvent;
nEvent=str2double(get(handles.edit_NEvent,'String'));
if nEvent-1>0
    set(handles.edit_NEvent,'String',num2str(nEvent-1));
    plotEEGtrace(handles);
    %highlight current event in figResult
    figResult=getappdata(0,'figResult');
    if ishandle(figResult)
    	if ishandle(hCurrentEvent)
            szEvents=getappdata(0,'szEvents');
            set(0,'currentfigure',figResult);
            hold on;
            delete(hCurrentEvent);
            %hCurrentEvent=plot(szEvents(nEvent-1,2)/60,0,'*r','Markersize',8);
            hCurrentEvent=rectangle('position',[szEvents(nEvent-1,2)/60,0,szEvents(nEvent-1,4)/60,10],'EdgeColor','r');
        end
    end
end

% --- Executes on button press in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hCurrentEvent;
szEvents=getappdata(0,'szEvents');
nEvent=str2double(get(handles.edit_NEvent,'String'));
if nEvent+1<=size(szEvents,1)
    set(handles.edit_NEvent,'String',num2str(nEvent+1));
    plotEEGtrace(handles);
    %highlight current event in figResult
    figResult=getappdata(0,'figResult');
    if ishandle(figResult)
    	if ishandle(hCurrentEvent)
            szEvents=getappdata(0,'szEvents');
            set(0,'currentfigure',figResult);
            hold on;
            delete(hCurrentEvent);
            %hCurrentEvent=plot(szEvents(nEvent+1,2)/60,0,'*r','Markersize',8);
            hCurrentEvent=rectangle('position',[szEvents(nEvent+1,2)/60,0,szEvents(nEvent+1,4)/60,10],'EdgeColor','r');
        end
    end
end


% --- Executes on button press in pushbutton_edit.
function pushbutton_edit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
szEvents=getappdata(0,'szEvents');
nEvent=str2double(get(handles.edit_NEvent,'String'));
if isempty(szEvents)
    return;
end
h=getappdata(0,'figseizreviewer');
set(0,'currentFigure',h);
[x,y]=ginput(2);
x1=min(x);
w=abs(x(2)-x(1));
szEvents(nEvent,2)=x1;
szEvents(nEvent,3)=x1+w;
szEvents(nEvent,4)=w;
setappdata(0,'szEvents',szEvents);
state=getappdata(0,'state');
info=getappdata(0,'info');
blks=getBlocks(state,3);
state(blks(nEvent,2):blks(nEvent,3))=0;
k1=round((szEvents(nEvent,2:3)-info.procWindow(1)*60)/info.stepTime);
state(k1)=3;
setappdata(0,'state',state);
plotEEGtrace(handles);

% --- Executes on button press in pushbutton_add.
function pushbutton_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hCurrentEvent;
szEvents=getappdata(0,'szEvents');
nEvent=str2double(get(handles.edit_NEvent,'String'));
h=getappdata(0,'figseizreviewer');
set(0,'currentFigure',h);
[x,y]=ginput(2);
x1=min(x);
w=abs(x(2)-x(1));
newEvent=zeros(1,4);
newEvent(2)=x1;
newEvent(3)=x1+w;
newEvent(4)=w;
allN=size(szEvents,1);
if x1<szEvents(nEvent,2)
    newEvent(1)=nEvent;
    if nEvent==1
        szEvents_2(1,:)=newEvent;
    else
        szEvents_2(1:nEvent-1,:)=szEvents(1:nEvent-1,:);
        szEvents_2(nEvent,:)=newEvent;
    end
    szEvents_2(nEvent+1:allN+1,:)=szEvents(nEvent:end,:);
else
    newEvent(1)=nEvent+1;
    szEvents_2=szEvents(1:nEvent,:);
    szEvents_2(nEvent+1,:)=newEvent;
    szEvents_2(nEvent+2:allN+1,:)=szEvents(nEvent+1:end,:);
end
szEvents=szEvents_2;
szEvents(:,1)=1:size(szEvents,1);
setappdata(0,'szEvents',szEvents);
state=getappdata(0,'state');
info=getappdata(0,'info');
k1=round((newEvent(1,2:3)-info.procWindow(1)*60)/info.stepTime);
state(k1)=3;
setappdata(0,'state',state);
plotEEGtrace(handles);
set(handles.text_info,'String',['Reviewing ',num2str(length(szEvents)),' ','SWD',' Events...']);
%highlight current event in figResult
figResult=getappdata(0,'figResult');
if ishandle(figResult)
	set(0,'currentfigure',figResult);
    if ishandle(hCurrentEvent)
        delete(hCurrentEvent);
    end
    hCurrentEvent=rectangle('position',[newEvent(1,2)/60,0,newEvent(1,4)/60,10],'EdgeColor','r');
end



% --- Executes on button press in pushbutton_reject.
function pushbutton_reject_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_reject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hCurrentEvent;
nEvent=str2double(get(handles.edit_NEvent,'String'));
szEvents=getappdata(0,'szEvents');
state=getappdata(0,'state');
blks=getBlocks(state,3);
state(blks(nEvent,2):blks(nEvent,3))=0;
allN=size(szEvents,1);
if nEvent==1
    szEvents=szEvents(2:end,:);
    nEvent=1;
elseif nEvent==allN
    szEvents=szEvents(1:allN-1,:);
    nEvent=allN-1;
else
    szEvents_2=szEvents(1:nEvent-1,:);
    szEvents_2(nEvent:allN-1,:)=szEvents(nEvent+1:allN,:);
    szEvents=szEvents_2;
end
szEvents(:,1)=1:size(szEvents,1);
setappdata(0,'szEvents',szEvents);
setappdata(0,'state',state);
%update plotData
if ishandle(hCurrentEvent)
    delete(hCurrentEvent);
end
pDat=getappdata(0,'specDat');
mDat=getappdata(0,'emgAmpDat');
plotData(pDat,mDat,state,[]);
% anaMode=getappdata(0,'anaMode');
% szType={'SWD','GTCS/TS'};
set(handles.text_info,'String',['Reviewing ',num2str(length(szEvents)),' ','SWD',' Events...']);
%show next event
set(handles.edit_NEvent,'String',num2str(nEvent));
plotEEGtrace(handles);
%highlight current event in figResult
figResult=getappdata(0,'figResult');
if ishandle(figResult)
	set(0,'currentfigure',figResult);
    hCurrentEvent=rectangle('position',[szEvents(nEvent,2)/60,0,szEvents(nEvent,4)/60,10],'EdgeColor','r');
end


function edit_NEvent_Callback(hObject, eventdata, handles)
% hObject    handle to edit_NEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_NEvent as text
%        str2double(get(hObject,'String')) returns contents of edit_NEvent as a double
nEvent=str2double(get(hObject,'String'));
szEvents=getappdata(0,'szEvents');
if nEvent<=size(szEvents,1) && nEvent>0
    plotEEGtrace(handles);
end



% --- Executes during object creation, after setting all properties.
function edit_NEvent_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_NEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%plot one EEG trace-----------------------------------------------------
function plotEEGtrace(handles)
specDat=getappdata(0,'specDat');
szEvents=getappdata(0,'szEvents');
nEvent=str2double(get(handles.edit_NEvent,'String'));
if isempty(szEvents)
    return;
end
event=szEvents(nEvent,:);

axes(handles.axes_eegTrace);
cla;
%pre=5;post=10;      %for sleep, SWD
%pre=10;post=20;      %for GTCS
pre=str2double(get(handles.edit_pre,'String'));
post=str2double(get(handles.edit_post,'String'));
evtIdx=find(szEvents(:,3)-event(2)+pre>0 & szEvents(:,2)-event(2)<post);
highlightFlag=get(handles.checkbox_highlightEvent,'Value');
if highlightFlag
    ylm=5*prctile(abs(specDat.fEEG(2,:)),95);
    % mark nearby events
    cl=[0.8,0.9,1];
    for i=1:length(evtIdx)
        rectangle('position',[szEvents(evtIdx(i),2),-ylm,szEvents(evtIdx(i),4),2*ylm],'FaceColor',cl,'EdgeColor',cl);
    end
    % mark Current event
    cl=[1,1,0.7];
    rectangle('position',[event(2),-ylm,event(4),2*ylm],'FaceColor',cl,'EdgeColor',cl);
    hold on;
end
tm=specDat.fEEG(1,:);
idx=find(tm>=event(2)-pre & tm<=event(2)+post);
plot(tm(idx),specDat.fEEG(2,idx),'k');

xlabel('Time(sec)');
ylabel('Voltage(uv)');
set(gca,'xlim',[-pre,post]+event(2));


% --- Executes on button press in checkbox_highlightEvent.
function checkbox_highlightEvent_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_highlightEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_highlightEvent
plotEEGtrace(handles);



function edit_pre_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_pre as text
%        str2double(get(hObject,'String')) returns contents of edit_pre as a double
plotEEGtrace(handles);

% --- Executes during object creation, after setting all properties.
function edit_pre_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
anaMode=getappdata(0,'anaMode');      %sleep / SWD / GTCS for analysis
val=5;
if anaMode(3)
    val=10;
end
set(hObject,'String',val);


function edit_post_Callback(hObject, eventdata, handles)
% hObject    handle to edit_post (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_post as text
%        str2double(get(hObject,'String')) returns contents of edit_post as a double
plotEEGtrace(handles);

% --- Executes during object creation, after setting all properties.
function edit_post_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_post (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
anaMode=getappdata(0,'anaMode');      %sleep / SWD / GTCS for analysis
val=10;
if anaMode(3)
    val=50;
end
set(hObject,'String',val);

% --- Executes during object deletion, before destroying properties.
function figure_SWDreview_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure_SWDreview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hCurrentEvent;
if ishandle(hCurrentEvent)
	delete(hCurrentEvent);
end
h0=getappdata(0,'figseizreviewer');
if ishandle(h0)
	delete(h0);
	setappdata(0,'figseizreviewer',[]);
end
