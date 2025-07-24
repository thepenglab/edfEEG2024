%to start time of recording from FileInfo
%format-31 datestr: yyyy-mm-dd HH:MM:SS
function startTimestr=getEDFStartTime(fileInfo)
%startTimestr=[];

OpenTime=[fileInfo.StartTime(1:2),':',...
    fileInfo.StartTime(4:5),':',fileInfo.StartTime(7:8)];
OpenDate=[fileInfo.StartDate(1:2),'/',...
    fileInfo.StartDate(4:5),'/20',fileInfo.StartDate(7:8)];

startTimestr=datestr([OpenDate,' ',OpenTime]);
