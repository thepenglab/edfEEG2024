function szEvents=getszEvents(pDat,state,tag)
blks=getBlocks(state,tag);
if isempty(blks)
    szEvents=[];
    return;
end
szEvents=blks;
szEvents(:,2:3)=pDat.t(blks(:,2:3))-0*pDat.step; 
szEvents(:,4)=szEvents(:,3)-szEvents(:,2);
