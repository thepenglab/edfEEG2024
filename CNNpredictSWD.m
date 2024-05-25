%use trained CNN to predict SWD
function state=CNNpredictSWD(specDat,trainedNet_File,cnn_p)
unitSize=2;     %to fit unitSize in trainedNet
XData=getNetXData(specDat,unitSize);
load(trainedNet_File,'trainedNet');
if isempty(trainedNet)
    disp('no trainedNet');
    state=[];
    return;
end
[YPredicted,probs] = classify(trainedNet,XData,'ExecutionEnvironment','cpu');
s1=double(YPredicted)-1;
s1(s1==2)=3;
%same p-threshold for all states
%idx2=find(max(probs,[],2)<cnn_p);
%different p-thresholds 
%threshold for "NotSure" - NREM sleep
pTh=0.975;    
idx1=(probs(:,2)<pTh & s1==1);
s1(idx1)=0;
% "not sure" - SWD
idx2=(probs(:,3)<cnn_p & s1==3);
s1(idx2)=0;
%use higher p for NREM sleep

s2=repmat(s1,1,unitSize);
state_Predicted=reshape(s2',[],1);
state=adjustState(state_Predicted,specDat);
%calculate time for each state
% idx1=find(state==0);
% idx2=find(state==1);
% idx3=find(state==2);
% idx4=find(state==3);
% seg=(specDat.t(end)-specDat.t(1))/60;         %convert to minute
%dur=[length(idx1),length(idx2),length(idx3),length(idx4)]*seg/length(state);
%fprintf('Wake/NREM/REM/SWD time(min): %8.1f %8.1f %8.1f\n',dur);
blk=getBlocks(state,3);
disp(size(blk,1)+" total SWD events found!");


function X=getNetXData(specDat,unitSize)
factor=1.0;
pBuffer=(specDat.p*factor)';
%smooth spectrogram at time-dimension
%filter for smooth
h1=zeros(unitSize*2+1);
h1(unitSize+1,:)=normpdf(-unitSize:unitSize,0,unitSize);            
h1=h1/sum(h1(unitSize+1,:));
pBuffer=imfilter(pBuffer,h1);
[pLen,tLen]=size(pBuffer);
snum=floor(tLen/unitSize);
pBuffer=pBuffer(:,1:snum*unitSize);
X=reshape(pBuffer,pLen,unitSize,1,[]);


