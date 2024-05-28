%--------------------------------------------------------------adjustSWD
function state=adjustSWD(state,pDat)
dat1=pDat.fseiz;
dat0=pDat.fcontrol;
r=(dat1./dat0);

% use confidence interval 
dat2=dat1(state);
SEM2 = std(dat2)/sqrt(length(dat2));               % Standard Error
t2 = tinv(0.001,length(dat2)-1);                 % T-Score
C2 = mean(dat2) + t2*SEM2;                      % Confidence Intervals
dat3=dat1(~state);
SEM3 = std(dat3)/1;               % Standard Error
t3 = tinv(0.99,length(dat3)-1);                 % T-Score
C3 = mean(dat3) + t3*SEM3;                      % Confidence Intervals
%r2=median(dat1(state)./dat0(state));
r2=quantile(dat1(state)./dat0(state),0.05);
r3=quantile(dat1(~state)./dat0(~state),0.95);
%remove big noisy events
delta=pDat.delta;
sm=std(delta)/sqrt(length(delta));
t1=tinv(0.999,length(delta)-1);
std4x=mean(delta)+4*std(delta);
C1=max(mean(delta)+t1*sm,std4x);

%add missing events
state2=(dat1>C3 & r>r3);
state2=fillGap(state2,1/pDat.step,0);
missing=(state2 & ~state);
blk=getBlocks(missing,1);
if ~isempty(blk)
    state=(state | missing);
end
fprintf('Add %d missing events\n',size(blk,1));

%remove false positive 
%state=(state & dat1>C3);
blk=getBlocks(state,1);
if ~isempty(blk)
    n=0;
    for i=1:size(blk,1)
        s0=mean(dat1(blk(i,2):blk(i,3)));
        c0=mean(dat0(blk(i,2):blk(i,3)));
        d0=mean(delta(blk(i,2):blk(i,3)));
        if (s0<C2 && s0/c0<r2) || d0>C1
            state(blk(i,2):blk(i,3))=0;
            n=n+1;
        end
    end
    fprintf('Remove %d false positive events\n',n);
end
state=fillGap(state,0.5/pDat.step,1);
blk=getBlocks(state,1);
fprintf('Detect %d SWD events\n',size(blk,1));
