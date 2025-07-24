%--------------------------------------------------------------getState1
%use STD thresholds
function state=getState1(specDat,emgAmp,mode)
%detect wake/sleep
state1=getSleepState(specDat,emgAmp);
%detect seizures
state2=getSeizure(specDat,mode);
%merge statess
state=state1;
state(state2)=3;


%%------------------------------------------------------------------------
%detect seizure (SWD, GTCS/TS) based on standard deviation of 19-23Hz power
%stdTh = std threshold
%mode: 1=swd, 2=gtcs/ts
function state = getSeizure(specDat,mode)
if mode==0
    state=[];
    return;
end
dat1=specDat.fseiz;
th=specDat.seizTh;
state=dat1>th;
if mode==1
    state=adjustSWD(state,specDat);
elseif mode==2
    %connect if gap is shorter than 10sec
    state=fillGap(state,10/specDat.step,0);
    %remove events if shorter than 10sec
    state=fillGap(state,2/specDat.step,1);
end


%%------------------------------------------------------------------------
%assign the states using phighfband
function state=getSleepState(pDat,mDat)
%con_highDelta = pDat.phighfband==1;
if ~isempty(mDat)
    th=[0,0,0.5,0];     %defualt threshold: delta/theta/ratio/empAmp
    deltath=mean(pDat.delta)+th(1)*std(pDat.delta);
    thetath=mean(pDat.theta)+th(2)*std(pDat.theta);
    ratioth=mean(pDat.ratio)+th(3)*std(pDat.ratio);
    con_highDelta=pDat.delta>deltath;
    emgth=mean(mDat.Amp)+th(4)*std(mDat.Amp);
    con_lowEMG=mDat.Amp<emgth;
    
    %part1---NREM 
    %NREM based on high delta-power and low EMG amplitude  
    state=int8(con_highDelta & con_lowEMG);
    
    %part2---REM sleep
    con_highTheta=pDat.theta>thetath;
    con_highRatio=pDat.ratio>ratioth;
    con_rem=con_highTheta & con_highRatio & con_lowEMG ;
    idx=find(con_rem);
    if ~isempty(idx)
        state(idx)=2;
    end
else
    delta=clipNoise(pDat.delta,20);
    dat1=delta(pDat.phighfband==0);
    th1=mean(dat1)+2*std(dat1);
    delta=smooth(delta,round(5*pDat.fs+1));
    con1 = delta>th1;
    state=int8(con_highDelta & con1);
end
% %connect if gap is shorter than 10sec
% state=fillGap(state,5/pDat.step,0);
% %remove sleep period if shorter than 60sec
% state=fillGap(state,60/pDat.step,1);
state=adjustState(state,pDat,0);

