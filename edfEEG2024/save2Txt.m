function save2Txt(szEvents,sleepData,info,fname)
if ~isempty(fname)
    fid=fopen(fname,'wt');
    fn=fullfile(info.PathName,info.FileName);
    fprintf(fid,'Data source: %s\r\n',fn);
    fprintf(fid,'Label/channel processed: %s\r\n',info.Labels{info.eegCh(1)});
    if info.eegCh(2)==0
        ref='N/A';
    else
        ref=info.Labels{info.eegCh(2)};
    end
    fprintf(fid,'Reference Label/channel: %s\r\n',ref);
    fprintf(fid,'Time window processed: %d - %d (minutes)\r\n',info.procWindow);
    fprintf(fid,'Bin and Step time: %6.2f(sec) %6.2f(sec)\r\n',info.binTime,info.stepTime);
    
    snum=size(szEvents,1);
    fprintf(fid,'Total number of seizure events:%d\r\n',snum);
    fprintf(fid,'\r\n----Seizure Events---------\r\n');
    fprintf(fid,'Event#\tStart-time(s)\tEnd-time(s)\tDuration(s)\r\n');
    for i=1:snum
        fprintf(fid,'%d\t%10.2f\t%10.2f\t%8.2f\r\n',szEvents(i,:));
    end
    
    if ~isempty(sleepData)
        fprintf(fid,'\r\n----sleep summary---------\r\n');
        fprintf(fid,'total Wake/NREM/REM time(min): %8.1f %8.1f %8.1f\r\n',sleepData.dur);
        if ~isempty(sleepData.nremEpoch)
            fprintf(fid,'total NREM sleep epoches: %d\r\n',size(sleepData.nremEpoch,1));
            fprintf(fid,'average NREM sleep duration per epoch: %8.1f(sec)\r\n',mean(sleepData.nremEpoch(:,4)));
        end
        if ~isempty(sleepData.remEpoch)
            fprintf(fid,'total REM sleep epoches: %d\r\n',size(sleepData.remEpoch,1));
            fprintf(fid,'average REM sleep duration per epoch: %8.1f(sec)\r\n',mean(sleepData.remEpoch(:,4)));
        end
        fprintf(fid,'\r\n----NREM sleep epoches(#/startTime/endTime/duration(sec)---------\r\n');
        for i=1:size(sleepData.nremEpoch,1)
            fprintf(fid,'%g\t%g\t%g\t%g\r\n',sleepData.nremEpoch(i,:));
        end
        fprintf(fid,'\r\n----REM sleep epoches(#/startTime/endTime/duration(sec)---------\r\n');
        for i=1:size(sleepData.remEpoch,1)
            fprintf(fid,'%g\t%g\t%g\t%g\r\n',sleepData.remEpoch(i,:));
        end
    end
    
    fclose(fid);
end