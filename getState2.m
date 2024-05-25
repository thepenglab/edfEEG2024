%--------------------------------------------------------------getState
%use Kmean clustering 
function state=getState2(specDat,emgAmp,mode)
delta=clipNoise(specDat.delta,20);
delta=smooth(delta,round(5*specDat.fs+1));
theta=clipNoise(specDat.theta,20);
theta=smooth(theta,round(5*specDat.fs+1));
if mode>0
    X=[delta,theta,5*specDat.fseiz];
    knum=3;             %wake/NREM/seizure
else
    if ~isempty(emgAmp)
        X=[specDat.p,emgAmp];
        knum=3;         %wake/NREMS/REMS
    else
        X=[delta,theta,specDat.ratio];
        knum=2;         %awke/NREMS
    end
    
end
s0=kmeans(X,knum,'distance','cosine');          %correlation/cosine

%draw the clusters
%tg={'r+','g*','bx'};
% tg={'r.','g.','b.'};
% figure;
% for i=1:knum
%     k1=find(s0==i);
%     hold on;
%     plot3(X(k1,1),X(k1,2),X(k1,3),tg{i});
% end
% xlabel('delta');ylabel('theta');zlabel('fseiz');

m0=zeros(knum,1);m1=m0;m2=m0;
for i=1:knum
    idx=(s0==i);
    m0(i)=mean(specDat.fseiz(idx));
    m1(i)=mean(delta(idx));
    if ~isempty(emgAmp)
        m2(i)=mean(emgAmp(idx));
    end
end

state=0*s0;
%assign NREM (by default, wake=0)
[B,k1]=max(m1);
state(s0==k1) = 1;
%connect if gap is shorter than 10sec
state=fillGap(state,10/specDat.step,0);
%remove sleep period if shorter than 60sec
state=fillGap(state,60/specDat.step,1);
%assign REM if EMG exist
if ~isempty(emgAmp) && mode==0
	[B,k2]=min(m2.*(1+m1));
	state(s0==k2) = 2;
end
    
%assign seizure (SWD or GTCS)
if mode==1
    [B,k3]=max(m0);
    state1=(s0==k3);
    state1=adjustSWD(state1,specDat);
    state(state1) = 3;
end



