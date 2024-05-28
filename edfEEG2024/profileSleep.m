%to summarize sleep analysis
function sleepData=profileSleep(state,info)
stepTime=info.stepTime;
sleepData={};
sleepData.state=state;
sleepData.stepTime=stepTime;
sleepData.totalMinute=length(state)*stepTime/60;
%overall durations for wake/nrem/rem
idx1=find(state==0);
idx2=find(state==1);
idx3=find(state==2);
dur=[length(idx1),length(idx2),length(idx3)]*stepTime/60;
sleepData.dur=dur;
%all wake epoches
blk1=getBlocks(state,0);
if ~isempty(blk1)
    epWake=blk1;
    epWake(:,2:4)=blk1(:,2:4)*stepTime;
    epWake(:,2:3)=epWake(:,2:3)+info.procWindow(2)*60-length(state)*stepTime;
else
    epWake=[];
end
sleepData.wakeEpoch=epWake;
%all NREM epoches
blk1=getBlocks(state,1);
if ~isempty(blk1)
    epNREM=blk1;
    epNREM(:,2:4)=blk1(:,2:4)*stepTime;
    epNREM(:,2:3)=epNREM(:,2:3)+info.procWindow(2)*60-length(state)*stepTime;
else
    epNREM=[];
end
sleepData.nremEpoch=epNREM;
%all REM epoches
blk2=getBlocks(state,2);
if ~isempty(blk2)
    epREM=blk2;
    epREM(:,2:4)=blk2(:,2:4)*stepTime;
    epREM(:,2:3)=epREM(:,2:3)+info.procWindow(2)*60-length(state)*stepTime;
else
    epREM=[];
end
sleepData.remEpoch=epREM;