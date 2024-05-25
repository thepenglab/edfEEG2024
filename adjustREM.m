function state=adjustREM(state,pDat)
pre = floor(180/pDat.step);
blocks = getBlocks(state,2);
if isempty(blocks)
	return;
end
% dwake=mean(pDat.delta(state==0));
% dnrem=mean(pDat.delta(state==1));
nremdm=median(pDat.delta(state==1));

k1=0;k2=0;k3=0;
%remove rem-period if no nrem in the pre-min
for i=1:length(blocks(:,1))
	if blocks(i,2) > pDat.step
        n1 = max(blocks(i,2)-pre, 1);
        if sum(state(n1:(blocks(i,2)-pDat.step))) == 0
            state(blocks(i,2):blocks(i,3)) = 0;
            k1=k1+1;
        end
    end
    d=mean(pDat.delta(blocks(i,2):blocks(i,3)));
    r=mean(pDat.ratio(blocks(i,2):blocks(i,3)));
    if d>nremdm*0.5 && r<1
        state(blocks(i,2):blocks(i,3)) = 1;
        k2=k2+1;
    end
    if d<nremdm*0.3 && r<1
        state(blocks(i,2):blocks(i,3)) = 0;
        k3=k3+1;
    end
end
disp([k1,k2,k3]);

%remove rem-period if shorter than n-sec
state = smallsegRemove(state, 30/pDat.step, 2);
