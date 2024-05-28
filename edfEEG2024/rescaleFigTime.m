function rescaleFigTime(xlm)
figResult=getappdata(0,'figResult');
info=getappdata(0,'info');
procWindow=info.procWindow;
state=getappdata(0,'state');
%xlm2=0.5+(xlm-procWindow(1))*length(state)/(procWindow(2)-procWindow(1));
if ~isempty(figResult)
    if ishandle(figResult)
        set(0,'currentfigure',figResult);
        h_axes=findobj(figResult,'type','axes');
        %h_axes=figResult.Children;
        for i=1:length(h_axes)
            b=h_axes(i).Position(2)+h_axes(i).Position(4);
            if b>0.8
                xlm2=0.5+(xlm-procWindow(1))*length(state)/(procWindow(2)-procWindow(1));
                set(h_axes(i),'xlim',xlm2);
            else
                set(h_axes(i),'xlim',xlm);
            end
%             ylm0=get(h_axes(i),'ylim');
%             ylm0range=range(ylm0);
%             if ylm0range==1 || ylm0range==100.5 || (ylm0range>=120.5 && ylm0range<=120.6)
%                 xlm2=0.5+(xlm-procWindow(1))*length(state)/(procWindow(2)-procWindow(1));
%                 set(h_axes(i),'xlim',xlm2);
%             else
%                 set(h_axes(i),'xlim',xlm);
%             end
        end
    end
end