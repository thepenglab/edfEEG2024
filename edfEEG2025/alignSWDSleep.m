% align SWD and sleep
% load SWD events as dat1=[start,end], 2D arrays
% load NREM sleep as dat2=[state,end], 2D arrays 
swdnum=size(dat1,1);
nremnum=size(dat2,1);
cls=[0.5,0.5,1;1,0,0];    %first color for NREM sleep, second for SWD
nremHei=1;      %height of NREM episodes
swdHei=2;       %height of SWD lines
figure;
%draw NREM sleep episodes
for i=1:nremnum
    rectangle('Position',[dat2(i,1),0-nremHei/2,dat2(i,2)-dat2(i,1),nremHei],'FaceColor',cls(1,:),'EdgeColor',cls(1,:))
end
%draw SWD events
for i=1:swdnum
    rectangle('Position',[dat1(i,1),0-swdHei/2,dat1(i,2)-dat1(i,1),swdHei],'FaceColor',cls(2,:),'EdgeColor',cls(2,:))
end
title('SWD vs Sleep');
xlabel('Time(s)');
ylabel('Events');
