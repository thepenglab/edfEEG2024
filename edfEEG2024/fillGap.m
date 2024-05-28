%-------------------------------------------------------------------fillGap
%remove the small segments if shorter than 2sec (0.2sec per datapoint)
%see step in <getEEGspectro> for datapoint-timescale
function state=fillGap(state,gap,tag)
d=0*state;
d(2:end)=state(2:end)-state(1:end-1);
idx0=find(d~=0);
dd=idx0(2:end)-idx0(1:end-1);
%remove 1-2 datapoint marker
ix=find(dd<=1);
if ~isempty(ix)
	for k=1:length(ix)
    	state(idx0(ix(k)):(idx0(ix(k)+1)-1))=state(idx0(ix(k))-1);
	end
end
%fill the gap
ix=find(dd<gap);
if ~isempty(ix)
	for k=1:length(ix)
        if state(idx0(ix(k))-1)~=tag
            state(idx0(ix(k)):(idx0(ix(k)+1)-1))=state(idx0(ix(k))-1);
        end
	end
end