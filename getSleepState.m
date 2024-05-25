%--------------------------------------------------------------getSleepState
%assign the states using phighfband
function state=getSleepState(pDat,mDat)
con_highDelta = pDat.phighfband==1;
if ~isempty(mDat)
    th=[0,0,0.5,1];     %defualt threshold: delta/theta/ratio/empAmp
    %deltath=mean(pDat.delta)+th(1)*std(pDat.delta);
    thetath=mean(pDat.theta)+th(2)*std(pDat.theta);
    ratioth=mean(pDat.ratio)+th(3)*std(pDat.ratio);
    emgth=mean(mDat.Amp(con_highDelta))+th(4)*std(mDat.Amp(con_highDelta));
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
    dat1=pDat.delta(pDat.delta<mean(pDat.delta)+2*std(pDat.delta));
    if length(dat1)>length(pDat.delta)*0.7
        th1=mean(dat1)-0.5*std(dat1);
    else
        th1=mean(dat1);
    end
    con1 = pDat.delta>th1;
    state=int8(con_highDelta & con1);
end
%connect if gap is shorter than 10sec
state=fillGap(state,10/pDat.step,0);
%remove sleep period if shorter than 60sec
state=fillGap(state,60/pDat.step,1);