function stateNew=adjustState(state,specDat,szType)
stateNew=0*state;
nrem=state==1;
rem=state==2;
seiz0=state==3;
step=specDat.step;

%deal with NREMS------------------
%remov high-noise
delta=specDat.delta(1:length(nrem));
dth=mean(delta(nrem))+3*std(delta(nrem));
nrem(delta>dth)=0;
%connect if gap is shorter than 10sec
nrem=fillGap(nrem,10/step,0);
%remove NREM sleep period if shorter than 60sec
nrem=fillGap(nrem,30/step,1);
stateNew(nrem)=1;

%deal with REMS------------------
rem=state==2;
rem=fillGap(rem,20/step,0);
% state(state==2)=0;
% state(rem==1)=2;
pre = floor(60/step);
blocks = getBlocks(rem,1);
if isempty(blocks)
	return;
end
for i=1:length(blocks(:,1))
	if blocks(i,2) > step
        if blocks(i,4)<20/step && blocks(i,2)>1
            rem(blocks(i,2):blocks(i,3)) = state(blocks(i,2)-1);
        end
        n1 = max(blocks(i,2)-pre, 1);
        %remove rem-period if no nrem in the pre-min
        if isempty(find(stateNew(n1:(blocks(i,2)-1)),1))
            rem(blocks(i,2):blocks(i,3)) = 0;
        end
    else
        rem(blocks(i,2):blocks(i,3)) = 0;
    end
end

stateNew(rem)=2;

%deal with seizure---------------
if szType>0
    if szType==1
        d2=[1,1];
    elseif szType==2
        d2=[30,10];
    end
    seiz0=adjustSWD(seiz0,specDat);
    seiz0=fillGap(seiz0,d2(1)/step,0);
    seiz0=fillGap(seiz0,d2(2)/step,1);
    stateNew(seiz0)=3;
end


