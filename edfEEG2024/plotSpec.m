%plot spectral power
plotData(specDat,emgAmpDat,state,[]);
%load data to workspace first
sname={'Wake','NREM','REM'};
gammaRange=[30,50];
[tLen,pLen]=size(specDat.p);
fHz=linspace(specDat.fsRange(1),specDat.fsRange(2),pLen);
gfIdx=(fHz>=gammaRange(1) & fHz<=gammaRange(2));
sLen=length(state);
if sLen>tLen
    state=state(1:tLen);
else
    state(sLen+1:tLen)=0;
end

%remove noisy periods
dth=mean(specDat.delta)+3*std(specDat.delta);
idx0=(specDat.delta<dth);
fth=mean(specDat.fcontrol)+3*std(specDat.fcontrol);
idx0b=(specDat.fcontrol<fth);
idx0=idx0 & idx0b;
% dth=mean(specDat.fseiz)+0.5*std(specDat.fseiz);
% idx0=(specDat.fseiz<dth);
%figure;imagesc(specDat.p(idx0,:)');
disp(['Data rate: ',num2str(length(find(idx0))/length(idx0))]);
%%
p0=mean(specDat.p(idx0,:));
totalP0=sum(p0);
totalP1=zeros(3,1);
%figure;plot(f,p0);

%breakdown to state
figure;
pstate=zeros(pLen,3);
gammaPower=zeros(3,4);
for i=0:2
    idx=(state==i) & idx0;
    if ~isempty(idx)
        p1=mean(specDat.p(idx,:));
        gammaPower(i+1,1)=sum(p1(gfIdx))*100/totalP0;
        totalP1(i+1)=sum(mean(specDat.p(idx,:)));
        gammaPower(i+1,2)=sum(p1(gfIdx))*100/totalP1(i+1);
        pstate(:,i+1)=p1*100/totalP0;
        hold on;
        plot(fHz,pstate(:,i+1));
    end
end
xlabel('Frequency(Hz)');
ylabel('Relative power(%)');
legend(sname);
%calculate power in each wake episode
epiNum=zeros(2,3);
cutoff=[30,30,0];      %cut off duration for wake/N/R in sec
gm={};
for i=0:2
    %figure;
    epi=getBlocks(state,i);
    epigamma=[];
    if ~isempty(epi)>0
        num=size(epi,1);
        for j=1:num
            p1=mean(specDat.p(epi(j,2):epi(j,3),:));
            d1=mean(specDat.delta(epi(j,2):epi(j,3)));
            f1=mean(specDat.fcontrol(epi(j,2):epi(j,3)));
            con1=d1<dth && f1<fth;
            if epi(j,4)*info.stepTime>cutoff(i+1) && con1
                epigamma(end+1)=sum(p1(gfIdx));
%                 plot(fHz,p1);
%                 set(gca,'xlim',[20,50]);
%                 hold on;
                %pause;
            end
        end
        gammaPower(i+1,3)=mean(epigamma)*100/totalP0;
        gammaPower(i+1,4)=mean(epigamma)*100/totalP1(i+1);
    end
    epiNum(1,i+1)=size(epi,1);
    epiNum(2,i+1)=length(epigamma);
    gm{i+1}=epigamma;
    xlabel('Frequency(Hz)');
    ylabel('Relative power(%)');
    title(sname{i+1});
end

disp(gammaPower');
disp(epiNum);
%%
return;
%save result in excel
%folder=
fout='spec.xls';
fname=fullfile(folder,fout);
writematrix(gammaPower', fname,'Sheet',1,'Range','A1:C4');
writematrix(epiNum, fname,'Sheet',1,'Range','A6:C7');
label1={'F(hz)','Wake','NREM','REM'};
writecell(label1,fname,'Sheet',2,'Range','A1:D1'); 
lidx=['A2:D',num2str(1+length(fHz))];
writematrix([fHz',pstate],fname,'Sheet',2,'Range',lidx);
lidx=['A1:A',num2str(length(gm{1}))];
writematrix(gm{1}',fname,'Sheet',3,'Range',lidx);
lidx=['B1:B',num2str(length(gm{2}))];
writematrix(gm{2}',fname,'Sheet',3,'Range',lidx);
lidx=['C1:C',num2str(length(gm{3}))];
writematrix(gm{3}',fname,'Sheet',3,'Range',lidx);



