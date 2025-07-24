%plot spectral power
%load data to workspace first
sname={'Wake','NREM','REM'};
gammaRange=[30,50];
[tLen,pLen]=size(specDat.p);
f=linspace(specDat.fsRange(1),specDat.fsRange(2),pLen);
gfIdx=(f>=gammaRange(1) & f<=gammaRange(2));

%remove noisy periods
dth=mean(specDat.delta)+3*std(specDat.delta);
idx0=(specDat.delta<dth);
dth=mean(specDat.fcontrol)+3*std(specDat.fcontrol);
idx0b=(specDat.fcontrol<dth);
idx0=idx0 & idx0b;
% dth=mean(specDat.fseiz)+0.5*std(specDat.fseiz);
% idx0=(specDat.fseiz<dth);
%figure;imagesc(specDat.p(idx0,:)');
disp(['Data rate: ',num2str(length(find(idx0))/length(idx0))]);
%%
p0=mean(specDat.p(idx0,:));
totalP0=sum(p0);
%figure;plot(f,p0);

%breakdown to state
figure;
pstate=zeros(3,pLen);
gammaPower=zeros(3,2);
for i=0:2
    idx=(state==i) & idx0;
    pstate(i+1,:)=mean(specDat.p(idx,:))*100/totalP0;
    gammaPower(i+1,1)=sum(pstate(i+1,gfIdx));
    gammaPower(i+1,2)=sum(pstate(i+1,gfIdx))*100/sum(pstate(i+1,:));
    hold on;
    plot(f,pstate(i+1,:));
end
xlabel('Frequency(Hz)');
ylabel('Relative power(%)');
legend(sname);
disp(gammaPower');
%%
%calculate power in each wake episode
figure;
wake=getBlocks(state,0);
wgamma=[];
if ~isempty(wake)>0
    wnum=size(wake,1);
    %wgamma=zeros(wnum,1);
    for i=1:wnum
        wp=mean(specDat.p(wake(i,2):wake(i,3),:));
        if wake(i,4)*info.stepTime>60
            wgamma(end+1)=sum(wp)*100/totalP0;
            plot(f,wp);
            set(gca,'xlim',[20,50]);
            hold on;
            %pause;
        end
    end
end