% analyze sleep patterns (use pre-analyzed mat-files) and export to excel
% updated 3/20/2025 - modified to process all files in batches of n

%%
% ------------folder name first-------------
base_folder = '/Users/davidrivas/Documents/research/eeg/eeg-data/Artemis/K168-5';
startMin = 0; % Start minute of processed data
lightseting = [6,18]; % Light on and off time
lowpass_cutoff = 40; % Lowpass filter cutoff frequency in Hz
batch_size = 6; % Number of .mat files (hours) to process at once (must divide evenly into 24)

% Function to find all .mat files in base_folder and its subfolders
function allMatFiles = findAllMatFiles(baseFolder)
    % Get all subfolders
    allFolders = genpath(baseFolder);
    folderList = strsplit(allFolders, pathsep);
    
    % Find all .mat files
    allMatFiles = {};
    for i = 1:length(folderList)
        if ~isempty(folderList{i})
            files = dir(fullfile(folderList{i}, '*.mat'));
            for j = 1:length(files)
                allMatFiles{end+1} = fullfile(folderList{i}, files(j).name);
            end
        end
    end
end

% Function to sort .mat files based on subfolder name first, then _mXX-XXX pattern
function sortedFiles = sortMatFiles(fileList)
    % Extract subfolder names and minute values for sorting
    subfolders = cell(length(fileList), 1);
    timeIndices = zeros(length(fileList), 1);
    
    for i = 1:length(fileList)
        % Extract the subfolder path
        [filePath, ~, ~] = fileparts(fileList{i});
        
        % Extract the last subfolder name from the path
        pathParts = strsplit(filePath, filesep);
        subfolders{i} = pathParts{end}; % Get the last subfolder name
        
        % Extract the minute value from the filename
        [~, name, ~] = fileparts(fileList{i});
        match = regexp(name, '_m(\d+)-', 'tokens', 'once');
        if ~isempty(match)
            timeIndices(i) = str2double(match{1});
        else
            timeIndices(i) = inf; % Assign inf for files without a match
        end
    end
    
    % Create a table for sorting
    T = table(subfolders, timeIndices, (1:length(fileList))', 'VariableNames', {'Subfolder', 'Minute', 'OriginalIndex'});
    
    % Sort first by subfolder name, then by minute value
    T = sortrows(T, {'Subfolder', 'Minute'});
    
    % Extract the sorted file list
    sortedFiles = fileList(T.OriginalIndex);
    
    % Display the sorted order for debugging
    disp('Sorted files by subfolder and then by minute value:');
    for i = 1:length(sortedFiles)
        disp(sortedFiles{i});
    end
end

% Function to process a batch of .mat files
function processFileBatch(fileList, batchNumber, startMin, lightseting, outputFolder, lowpass_cutoff)
    disp(['Processing batch: ' num2str(batchNumber)]);
    
    % Data to calculate
    ztSleep = zeros(24,3);
    dur_perh = zeros(1,3);
    dur_24h = zeros(3,3);
    bouts = zeros(3,3);
    transit = zeros(1,5);
    
    numFiles = length(fileList);
    disp(['Number of .mat files in batch: ', num2str(numFiles)]);
    
    % If no files found, return
    if numFiles == 0
        disp('No .mat files found in this batch.');
        return;
    end
    
    disp(['Start Min(min): ', num2str(startMin)]);
    
    % Display sorted list
    disp('List of files in batch:');
    for i = 1:numFiles
        disp(fileList{i});
    end
    
    % Initialize before loop
    bufferState = [];  
    bufferPower = [];  
    bufferWake = [];  
    bufferNREM = [];  
    bufferREM = [];  
    fileNumber = 0;
    totalHour = 0;
    
    % Process each .mat file
    for i = 1:length(fileList)
        fname = fileList{i};  % Extract the string from the cell
        if ~ischar(fname) && ~isstring(fname)
            error('Filename must be a character vector or string scalar.');
        end
        if contains(fname, '.mat')
            % NOTE: sleepData saved in mat-file is cumulative, not per hour
            load(fname, 'state', 'specDat', 'info');
            sLen1 = length(state);
            sLen2 = size(specDat.p, 1);
            sLen = min(sLen2, sLen1);
            state = state(1:sLen);
            specDat.p = specDat.p(1:sLen, :);
            bufferState = [bufferState; state];
            bufferPower = [bufferPower; specDat.p(:, 1:201)];
            sleepData = profileSleep(state, info);
            epoch0 = sleepData.wakeEpoch;
            epoch0(:, 5) = fileNumber + 1;
            bufferWake = [bufferWake; epoch0];
            epoch1 = sleepData.nremEpoch;
            epoch1(:, 5) = fileNumber + 1;
            bufferNREM = [bufferNREM; epoch1];
            epoch2 = sleepData.remEpoch;
            epoch2(:, 5) = fileNumber + 1;
            bufferREM = [bufferREM; epoch2];
            fileNumber = fileNumber + 1;
            
            % Explicitly calculate the range
            if isnumeric(info.procWindow)
                procWindowRange = max(info.procWindow) - min(info.procWindow);
                totalHour = totalHour + round(procWindowRange / 60);
            else
                error('info.procWindow is not numeric.');
            end
            
            dur_perh(fileNumber, :) = sleepData.dur;
        end
    end

    if totalHour == 0
        disp('No valid data found in this batch.');
        return;
    end
    
    %%
    %convert to zeitgeber time
    if ~isfield(info,'amplifier')
        info.amplifier='EDF';
    end
    ztFlag=0;
    if contains(info.amplifier,'Neuralynx')
        stDate=getNLXStartTime(info.FileInfo);
        if ~isempty(stDate)
            ztFlag=1;
        end
    elseif contains(info.amplifier,'TDT')
        if isfield(info.FileInfo,'Start')
            stDate=info.FileInfo.Start;
            ztFlag=1;
        end
    elseif contains(info.amplifier,'Intan')
        if isfield(info.FileInfo,'Start')
            stDate=info.FileInfo.Start;
            ztFlag=1;
        else
            if isfield(info,'fileList')
                stDate=getIntanStartTime(info.fileList{1});
                ztFlag=1;
            end
        end
    elseif contains(info.amplifier,'EDF')
        stDate=datetime(info.FileInfo.StartTime, 'InputFormat', 'HH.mm.ss');
        ztFlag=1;
    end
    if ztFlag
        hh = hour(stDate);
        mm = minute(stDate);
        stHH = floor(hh + mm / 60); % Use floor to avoid misalignment
    
        % Calculate Zeitgeber Time properly
        t = (0:totalHour-1) + stHH; % Absolute hours (clock time), starting from 0
        ZT = mod(t - lightseting(1), 24); % ZT where 0 is lights on (6am)

        % Define light and dark phases
        lightmap = zeros(1, totalHour);
        lightmap(ZT >= 0 & ZT <= 11) = 1; % Light phase: ZT 0-11
    
        % *** FIXED: Compute actual total durations without scaling ***
        % These values should add up correctly: total = light + dark
        light_hours = sum(lightmap);
        dark_hours = totalHour - light_hours;
        
        % Total durations across all hours
        dur_24h(1, :) = sum(dur_perh);
        
        % Light phase durations
        if light_hours > 0
            dur_24h(2, :) = sum(dur_perh(lightmap == 1, :));
        else
            dur_24h(2, :) = zeros(1, 3);
        end
        
        % Dark phase durations
        if dark_hours > 0
            dur_24h(3, :) = sum(dur_perh(lightmap == 0, :));
        else
            dur_24h(3, :) = zeros(1, 3);
        end
        
        % Verification - total should equal light + dark
        for i = 1:3
            total = dur_24h(1, i);
            sumPhases = dur_24h(2, i) + dur_24h(3, i);
            if abs(total - sumPhases) > 0.01
                disp(['Warning: Duration sum mismatch for state ' num2str(i-1) ...
                     ': Total=' num2str(total) ', Light+Dark=' num2str(sumPhases)]);
            end
        end
    
        % Compute Zeitgeber-time-aligned sleep durations
        ztSleep = zeros(24,3); % Initialize with 24 rows for ZT 0-23
        for i = 0:23
            idx = find(ZT == i);
            ztSleep(i+1, :) = mean(dur_perh(idx, :), 1); % i+1 for array indexing
        end
    else
        disp('Cannot convert to Zeitgeber time');
    end
    
    % Mark each epoch with its phase (1=light, 0=dark)
    for i=1:totalHour
        k=bufferWake(:,5)==i;
        bufferWake(k,6)=lightmap(i);
        k=bufferNREM(:,5)==i;
        bufferNREM(k,6)=lightmap(i);
        k=bufferREM(:,5)==i;
        bufferREM(k,6)=lightmap(i);
    end

    % Mark each epoch with its ZT-hour
    % We already have the absolute hours in the 't' variable and ZT in the 'ZT' variable
    if ztFlag
        % Create a mapping from file hours to ZT hours
        hourToZT = zeros(totalHour, 1);
        for i = 1:totalHour
            hourToZT(i) = ZT(i);
        end
        
        % Initialize a new column in each buffer for ZT-hour
        if ~isempty(bufferWake)
            bufferWake(:,7) = zeros(size(bufferWake,1), 1);
        end
        if ~isempty(bufferNREM)
            bufferNREM(:,7) = zeros(size(bufferNREM,1), 1);
        end
        if ~isempty(bufferREM)
            bufferREM(:,7) = zeros(size(bufferREM,1), 1);
        end
        
        % Assign ZT-hour to each epoch based on which file hour it belongs to
        for i = 1:totalHour
            if ~isempty(bufferWake)
                k = bufferWake(:,5) == i;
                bufferWake(k,7) = hourToZT(i);
            end
            if ~isempty(bufferNREM)
                k = bufferNREM(:,5) == i;
                bufferNREM(k,7) = hourToZT(i);
            end
            if ~isempty(bufferREM)
                k = bufferREM(:,5) == i;
                bufferREM(k,7) = hourToZT(i);
            end
        end
    else
        % If ZT time can't be calculated, fill with NaN
        if ~isempty(bufferWake)
            bufferWake(:,7) = NaN(size(bufferWake,1), 1);
        end
        if ~isempty(bufferNREM)
            bufferNREM(:,7) = NaN(size(bufferNREM,1), 1);
        end
        if ~isempty(bufferREM)
            bufferREM(:,7) = NaN(size(bufferREM,1), 1);
        end
    end

    % Check what phases are present in the data
    have_light_phase = any(lightmap == 1);
    have_dark_phase = any(lightmap == 0);
    
    % *** FIXED: Calculate bout counts correctly without scaling ***
    % Total bout counts
    bouts(1,1) = size(bufferWake,1);
    bouts(1,2) = size(bufferNREM,1);
    bouts(1,3) = size(bufferREM,1);
    
    if ztFlag
        % Light phase bout counts
        if have_light_phase
            bouts(2,1) = sum(bufferWake(:,6) == 1);
            bouts(2,2) = sum(bufferNREM(:,6) == 1);
            bouts(2,3) = sum(bufferREM(:,6) == 1);
        else
            bouts(2,:) = zeros(1,3);
        end
        
        % Dark phase bout counts
        if have_dark_phase
            bouts(3,1) = sum(bufferWake(:,6) == 0);
            bouts(3,2) = sum(bufferNREM(:,6) == 0);
            bouts(3,3) = sum(bufferREM(:,6) == 0);
        else
            bouts(3,:) = zeros(1,3);
        end
        
        % Verification - total should equal light + dark
        for i = 1:3
            total = bouts(1, i);
            sumPhases = bouts(2, i) + bouts(3, i);
            if abs(total - sumPhases) > 0.01
                disp(['Warning: Bout count mismatch for state ' num2str(i-1) ...
                     ': Total=' num2str(total) ', Light+Dark=' num2str(sumPhases)]);
            end
        end
    end
    
    % *** FIXED: Calculate bout durations correctly as simple averages ***
    bout_dur = zeros(3,3);
    
    % Wake bout durations
    if ~isempty(bufferWake)
        bout_dur(1,1) = mean(bufferWake(:,4));
        if ztFlag
            if have_light_phase && any(bufferWake(:,6) == 1)
                bout_dur(2,1) = mean(bufferWake(bufferWake(:,6) == 1, 4));
            else
                bout_dur(2,1) = NaN;
            end
            if have_dark_phase && any(bufferWake(:,6) == 0)
                bout_dur(3,1) = mean(bufferWake(bufferWake(:,6) == 0, 4));
            else
                bout_dur(3,1) = NaN;
            end
        end
    else
        bout_dur(1,1) = NaN;
        bout_dur(2,1) = NaN;
        bout_dur(3,1) = NaN;
    end
    
    % NREM bout durations
    if ~isempty(bufferNREM)
        bout_dur(1,2) = mean(bufferNREM(:,4));
        if ztFlag
            if have_light_phase && any(bufferNREM(:,6) == 1)
                bout_dur(2,2) = mean(bufferNREM(bufferNREM(:,6) == 1, 4));
            else
                bout_dur(2,2) = NaN;
            end
            if have_dark_phase && any(bufferNREM(:,6) == 0)
                bout_dur(3,2) = mean(bufferNREM(bufferNREM(:,6) == 0, 4));
            else
                bout_dur(3,2) = NaN;
            end
        end
    else
        bout_dur(1,2) = NaN;
        bout_dur(2,2) = NaN;
        bout_dur(3,2) = NaN;
    end
    
    % REM bout durations
    if ~isempty(bufferREM)
        bout_dur(1,3) = mean(bufferREM(:,4));
        if ztFlag
            if have_light_phase && any(bufferREM(:,6) == 1)
                bout_dur(2,3) = mean(bufferREM(bufferREM(:,6) == 1, 4));
            else
                bout_dur(2,3) = NaN;
            end
            if have_dark_phase && any(bufferREM(:,6) == 0)
                bout_dur(3,3) = mean(bufferREM(bufferREM(:,6) == 0, 4));
            else
                bout_dur(3,3) = NaN;
            end
        end
    else
        bout_dur(1,3) = NaN;
        bout_dur(2,3) = NaN;
        bout_dur(3,3) = NaN;
    end
    
    % Calculate transitions among states (unchanged)
    ds = bufferState(2:end) - bufferState(1:end-1);
    ds = [0; ds];
    
    % wake-to-NREMS
    idx = find(ds == 1 & bufferState == 1);
    transit(1) = length(idx);
    % NREMS-REMS
    idx = find(ds == 1 & bufferState == 2);
    transit(2) = length(idx);
    % NREMS-wake
    idx = find(ds == -1 & bufferState == 0);
    transit(3) = length(idx);
    % REMS-NREMS
    idx = find(ds == -1 & bufferState == 1);
    transit(4) = length(idx);
    % REMS-wake
    idx = find(ds == -2 & bufferState == 0);
    transit(5) = length(idx);
    
    % Calculate power (modified to use lowpass_cutoff and normalize after averaging)
    pLen = size(specDat.p, 2);
    pLen = 201;
    power_sleep = zeros(pLen, 6);  % power in NREMS (0-20Hz), [original, relative] for Wake/NREM/REM
    
    % Get frequency range
    fHz = linspace(specDat.fsRange(1), specDat.fsRange(2), size(bufferPower, 2));
    
    % Find index corresponding to lowpass cutoff
    cutoff_idx = find(fHz <= lowpass_cutoff, 1, 'last');
    if isempty(cutoff_idx)
        error('Lowpass cutoff frequency is too low for the available frequency range.');
    end
    disp(['Using frequency range up to index ' num2str(cutoff_idx) ' (approx. ' num2str(fHz(cutoff_idx)) ' Hz)']);
    
    % For wake: first calculate absolute power (average across epochs)
    idx = (bufferState == 0);
    power_sleep(:, 1) = 0;
    if any(idx)
        power_sleep(1:cutoff_idx, 1) = mean(bufferPower(idx, 1:cutoff_idx));
        
        % Then normalize to get relative power
        wake_total_power = sum(power_sleep(1:cutoff_idx, 1));
        power_sleep(:, 2) = 0;
        if wake_total_power > 0
            power_sleep(1:cutoff_idx, 2) = 100 * power_sleep(1:cutoff_idx, 1) / wake_total_power;
        end
        disp(['Wake total power: ' num2str(wake_total_power)]);
    else
        disp('No Wake epochs found');
    end
    
    % For NREM sleep
    idx = (bufferState == 1);
    power_sleep(:, 3) = 0;
    if any(idx)
        power_sleep(1:cutoff_idx, 3) = mean(bufferPower(idx, 1:cutoff_idx));
        
        % Normalize
        nrem_total_power = sum(power_sleep(1:cutoff_idx, 3));
        power_sleep(:, 4) = 0;
        if nrem_total_power > 0
            power_sleep(1:cutoff_idx, 4) = 100 * power_sleep(1:cutoff_idx, 3) / nrem_total_power;
        end
        disp(['NREM total power: ' num2str(nrem_total_power)]);
    else
        disp('No NREM epochs found');
    end
    
    % For REM sleep
    idx = (bufferState == 2);
    power_sleep(:, 5) = 0;
    if any(idx)
        power_sleep(1:cutoff_idx, 5) = mean(bufferPower(idx, 1:cutoff_idx));
        
        % Normalize
        rem_total_power = sum(power_sleep(1:cutoff_idx, 5));
        power_sleep(:, 6) = 0;
        if rem_total_power > 0
            power_sleep(1:cutoff_idx, 6) = 100 * power_sleep(1:cutoff_idx, 5) / rem_total_power;
        end
        disp(['REM total power: ' num2str(rem_total_power)]);
    else
        disp('No REM epochs found');
    end
    
    % Zero out power values beyond cutoff frequency
    power_sleep((cutoff_idx+1):end, :) = 0;
    
    % Debug: Check if relative power sums to approximately 100%
    disp('=== POWER SUM VERIFICATION ===');
    wake_power_sum = sum(power_sleep(1:cutoff_idx, 2));
    nrem_power_sum = sum(power_sleep(1:cutoff_idx, 4));
    rem_power_sum = sum(power_sleep(1:cutoff_idx, 6));
    
    disp(['Sum of Wake relative power (0-' num2str(lowpass_cutoff) 'Hz): ' num2str(wake_power_sum) '%']);
    disp(['Sum of NREM relative power (0-' num2str(lowpass_cutoff) 'Hz): ' num2str(nrem_power_sum) '%']);
    disp(['Sum of REM relative power (0-' num2str(lowpass_cutoff) 'Hz): ' num2str(rem_power_sum) '%']);

    % Plot data - duration per hour (unchanged)
    figure;
    tm = (1:totalHour)';
    axes('position', [0.1, 0.9, 0.85, 0.05]);
    imagesc(lightmap);
    colormap('gray');
    set(gca, 'xtick', [], 'ytick', []);
    axes('position', [0.1, 0.1, 0.85, 0.78]);
    h = plot(tm, dur_perh, '.-');
    set(h, 'Markersize', 12);
    set(gca, 'ylim', [-5, 60+5], 'xlim', [1-0.5, totalHour+0.5]);
    legend({'Wake', 'NREM', 'REM'});
    xlabel('hour#');
    ylabel('time(min)');
    f1 = fullfile(outputFolder, ['durations_hourly_batch' num2str(batchNumber) '.png']);
    F = getframe(gcf);
    imwrite(F.cdata, f1);
    close;
    
    % ZT order plot (unchanged)
    if ztFlag
        figure;
        zt = (0:23)';
        axes('position', [0.1, 0.9, 0.85, 0.05]);
        ztlightmap = zeros(1, 24);
        ztlightmap(1:12) = 1; % Light phase: ZT 0-11 (array indices 1-12)
        imagesc(ztlightmap);
        colormap('gray');
        set(gca, 'xtick', [], 'ytick', []);
        axes('position', [0.1, 0.1, 0.85, 0.78]);
        h = plot(zt, ztSleep, '.-');
        set(h, 'Markersize', 12);
        set(gca, 'ylim', [-5, 60+5], 'xlim', [0-0.5, 23+0.5]);
        set(gca, 'xtick', 0:23);
        legend({'Wake', 'NREM', 'REM'});
        xlabel('ZT');
        ylabel('time(min)');
        
        % Save plot
        f1 = fullfile(outputFolder, ['durations_ZT_batch' num2str(batchNumber) '.png']);
        F = getframe(gcf);
        imwrite(F.cdata, f1);
        close;
    end
    
    % Plot spectral information (modified to show cutoff)
    figure;
    fHz = linspace(specDat.fsRange(1), specDat.fsRange(2), size(power_sleep, 1));
    subplot(1, 3, 1);
    plot(fHz, power_sleep(:, 2));
    title('EEG power in Wake'); 
    ylabel('Relative power (%)');
    xlabel('Frequency (Hz)');
    set(gca, 'xlim', [0, lowpass_cutoff]); % Set x limit to cutoff
    hold on;
    
    subplot(1, 3, 2);
    plot(fHz, power_sleep(:, 4));
    title('EEG power in NREM sleep'); 
    ylabel('Relative power (%)');
    xlabel('Frequency (Hz)');
    set(gca, 'xlim', [0, lowpass_cutoff]);
    hold on;
    
    subplot(1, 3, 3);
    plot(fHz, power_sleep(:, 6));
    title('EEG power in REM sleep'); 
    ylabel('Relative power (%)');
    xlabel('Frequency (Hz)');
    set(gca, 'xlim', [0, lowpass_cutoff]);
    hold on;
    f1 = fullfile(outputFolder, ['spectral_batch' num2str(batchNumber) '.png']);
    F = getframe(gcf);
    imwrite(F.cdata, f1);
    close;
    
    %%
    % Export data to an Excel file (unchanged)
    nowstr = datestr(now, 30);
    FileName = ['sleepMetrics_batch' num2str(batchNumber) '_' nowstr '.xls'];
    fname = fullfile(outputFolder, FileName);
    label1 = {'Standard Hour Time', 'ZT-time', 'Wake(min)', 'NREM(min)', 'REM(min)'};
    
    % Sheet 1 - basic summary
    writecell(label1, fname, 'Sheet', 1, 'Range', 'A1:E1');
    % Calculate the hour values that correspond to ZT times
    hourValues = mod(zt + lightseting(1), 24); % Convert ZT back to hour of day
    writematrix(hourValues, fname, 'Sheet', 1, 'Range', 'A2:A25'); 
    writematrix(zt, fname, 'Sheet', 1, 'Range', 'B2:B25'); 
    writematrix(ztSleep, fname, 'Sheet', 1, 'Range', 'C2:E25'); 
    label1 = {'total(min)', 'light(min)', 'dark(min)'};
    writecell(label1', fname, 'Sheet', 1, 'Range', 'B27:B29'); 
    writematrix(dur_24h, fname, 'Sheet', 1, 'Range', 'C27:E29');
    label1 = {'total # bouts', '# bouts light', '# bouts dark'};
    writecell(label1', fname, 'Sheet', 1, 'Range', 'B31:B33'); 
    writematrix(bouts, fname, 'Sheet', 1, 'Range', 'C31:E33'); 
    label1 = {'total avg bout-duration(s)', 'avg bout dur-light(s)', 'avg bout dur-dark(s)'};
    writecell(label1', fname, 'Sheet', 1, 'Range', 'B35:B37'); 
    writematrix(bout_dur, fname, 'Sheet', 1, 'Range', 'C35:E37');  
    label1 = {'# Transitions'};
    writecell(label1, fname, 'Sheet', 1, 'Range', 'H1'); 
    label1 = {'Wake-NREM', 'NREM-REM', 'NREM-Wake', 'RREM-NREM', 'REM-Wake'};
    writecell(label1', fname, 'Sheet', 1, 'Range', 'H2:H6'); 
    writematrix(transit', fname, 'Sheet', 1, 'Range', 'I2:I6'); 
    
    % Sheet 2 - spectral (only up to lowpass cutoff)
    label1 = {'F(hz)', 'wake-p0', 'wake-p1', 'NREM-p0', 'NREM-p1', 'REM-p0', 'REM-p1'};
    writecell(label1, fname, 'Sheet', 2, 'Range', 'A1:G1'); 
    
    % Only write data up to the cutoff frequency
    lidx = ['A2:G', num2str(1+cutoff_idx)];
    writematrix([fHz(1:cutoff_idx)', power_sleep(1:cutoff_idx,:)], fname, 'Sheet', 2, 'Range', lidx);
    
    % Add sum verification to Excel
    sum_labels = {'Relative Power Sums (%)'};
    writecell(sum_labels, fname, 'Sheet', 2, 'Range', ['A' num2str(cutoff_idx+3)]);
    sum_labels = {'Wake', 'NREM', 'REM'};
    writecell(sum_labels, fname, 'Sheet', 2, 'Range', ['A' num2str(cutoff_idx+4) ':C' num2str(cutoff_idx+4)]);
    sums = [wake_power_sum, nrem_power_sum, rem_power_sum];
    writematrix(sums, fname, 'Sheet', 2, 'Range', ['A' num2str(cutoff_idx+5) ':C' num2str(cutoff_idx+5)]);
    
    % Sheet 3 - NREM Sleep Epochs
    disp('Creating NREM epoch listing in Sheet 3');
    
    % Write sleep summary header for NREM sheet
    writecell({'----sleep summary---------'}, fname, 'Sheet', 3, 'Range', 'A1');
    
    % Write time summary with proper column placement
    writecell({'total Wake/NREM/REM time(min):'}, fname, 'Sheet', 3, 'Range', 'A2');
    writematrix([dur_24h(1,1), dur_24h(1,2), dur_24h(1,3)], fname, 'Sheet', 3, 'Range', 'D2:F2');
    
    % Add all epoch counts and details for consistency
    if ~isempty(bufferNREM)
        writecell({'total NREM sleep epoches:'}, fname, 'Sheet', 3, 'Range', 'A3');
        writematrix(size(bufferNREM, 1), fname, 'Sheet', 3, 'Range', 'D3');
        
        writecell({'average NREM sleep duration per epoch:'}, fname, 'Sheet', 3, 'Range', 'A4');
        writematrix(mean(bufferNREM(:,4)), fname, 'Sheet', 3, 'Range', 'D4');
        writecell({'(sec)'}, fname, 'Sheet', 3, 'Range', 'E4');
    end
    
    if ~isempty(bufferREM)
        writecell({'total REM sleep epoches:'}, fname, 'Sheet', 3, 'Range', 'A5');
        writematrix(size(bufferREM, 1), fname, 'Sheet', 3, 'Range', 'D5');
        
        writecell({'average REM sleep duration per epoch:'}, fname, 'Sheet', 3, 'Range', 'A6');
        writematrix(mean(bufferREM(:,4)), fname, 'Sheet', 3, 'Range', 'D6');
        writecell({'(sec)'}, fname, 'Sheet', 3, 'Range', 'E6');
    end
    
    if ~isempty(bufferWake)
        writecell({'total Wake epoches:'}, fname, 'Sheet', 3, 'Range', 'A7');
        writematrix(size(bufferWake, 1), fname, 'Sheet', 3, 'Range', 'D7');
        
        writecell({'average Wake duration per epoch:'}, fname, 'Sheet', 3, 'Range', 'A8');
        writematrix(mean(bufferWake(:,4)), fname, 'Sheet', 3, 'Range', 'D8');
        writecell({'(sec)'}, fname, 'Sheet', 3, 'Range', 'E8');
    end
    
    % Add spacing
    writecell({''}, fname, 'Sheet', 3, 'Range', 'A9');
    
    % Write NREM epoch details header
    writecell({'----NREM sleep epoches(#/startTime/endTime/duration(sec)/fileNum/lightDark/ZT-hour)---------'}, fname, 'Sheet', 3, 'Range', 'A10');
    
    % Add column headers for NREM epochs (now with ZT-hour)
    writecell({'#', 'startTime', 'endTime', 'duration(sec)', 'fileNum', 'lightDark', 'ZT-hour'}, fname, 'Sheet', 3, 'Range', 'A11:G11');
    
    % Write NREM epochs data
    if ~isempty(bufferNREM)
        % Sort the epochs by start time
        [~, idx] = sort(bufferNREM(:, 1));
        sortedNREM = bufferNREM(idx, :);
        
        % Include all columns including ZT-hour
        nremEpochsTable = sortedNREM(:, 1:7);
        
        % Convert numeric light/dark indicators to text labels
        lightDarkLabels = cell(size(nremEpochsTable, 1), 1);
        for i = 1:size(nremEpochsTable, 1)
            if nremEpochsTable(i, 6) == 1
                lightDarkLabels{i} = 'Light';
            else
                lightDarkLabels{i} = 'Dark';
            end
        end
        
        % Write the NREM epochs numeric data
        start_row = 12;
        end_row = start_row + size(nremEpochsTable, 1) - 1;
        
        % Write columns 1-5 (unchanged)
        range = ['A' num2str(start_row) ':E' num2str(end_row)];
        writematrix(nremEpochsTable(:, 1:5), fname, 'Sheet', 3, 'Range', range);
        
        % Write the light/dark text labels (column 6)
        range = ['F' num2str(start_row) ':F' num2str(end_row)];
        writecell(lightDarkLabels, fname, 'Sheet', 3, 'Range', range);
        
        % Write the ZT-hour values (column 7)
        range = ['G' num2str(start_row) ':G' num2str(end_row)];
        writematrix(nremEpochsTable(:, 7), fname, 'Sheet', 3, 'Range', range);
    end
    
    % Add a mapping of file numbers to actual filenames for NREM sheet
    if ~isempty(fileList)
        if ~isempty(bufferNREM)
            file_map_row = end_row + 4;
        else
            file_map_row = 15; % Default if no NREM data
        end
        
        % Header for file mapping
        writecell({'----File Number Mapping---------'}, fname, 'Sheet', 3, 'Range', ['A' num2str(file_map_row)]);
        writecell({'FileNum', 'Filename'}, fname, 'Sheet', 3, 'Range', ['A' num2str(file_map_row+1) ':B' num2str(file_map_row+1)]);
        
        % Create file mapping data
        fileNumData = (1:length(fileList))';
        fileNameData = cell(length(fileList), 1);
        
        for i = 1:length(fileList)
            [~, filename, ext] = fileparts(fileList{i});
            fileNameData{i} = [filename ext];
        end
        
        % Write file number mapping
        range = ['A' num2str(file_map_row+2) ':A' num2str(file_map_row+1+length(fileList))];
        writematrix(fileNumData, fname, 'Sheet', 3, 'Range', range);
        
        range = ['B' num2str(file_map_row+2) ':B' num2str(file_map_row+1+length(fileList))];
        writecell(fileNameData, fname, 'Sheet', 3, 'Range', range);
    end
    
    % Sheet 4 - REM Sleep Epochs
    disp('Creating REM epoch listing in Sheet 4');
    
    % Write sleep summary header for REM sheet
    writecell({'----sleep summary---------'}, fname, 'Sheet', 4, 'Range', 'A1');
    
    % Write time summary with proper column placement
    writecell({'total Wake/NREM/REM time(min):'}, fname, 'Sheet', 4, 'Range', 'A2');
    writematrix([dur_24h(1,1), dur_24h(1,2), dur_24h(1,3)], fname, 'Sheet', 4, 'Range', 'D2:F2');
    
    % Add all epoch counts and details for consistency
    if ~isempty(bufferNREM)
        writecell({'total NREM sleep epoches:'}, fname, 'Sheet', 4, 'Range', 'A3');
        writematrix(size(bufferNREM, 1), fname, 'Sheet', 4, 'Range', 'D3');
        
        writecell({'average NREM sleep duration per epoch:'}, fname, 'Sheet', 4, 'Range', 'A4');
        writematrix(mean(bufferNREM(:,4)), fname, 'Sheet', 4, 'Range', 'D4');
        writecell({'(sec)'}, fname, 'Sheet', 4, 'Range', 'E4');
    end
    
    if ~isempty(bufferREM)
        writecell({'total REM sleep epoches:'}, fname, 'Sheet', 4, 'Range', 'A5');
        writematrix(size(bufferREM, 1), fname, 'Sheet', 4, 'Range', 'D5');
        
        writecell({'average REM sleep duration per epoch:'}, fname, 'Sheet', 4, 'Range', 'A6');
        writematrix(mean(bufferREM(:,4)), fname, 'Sheet', 4, 'Range', 'D6');
        writecell({'(sec)'}, fname, 'Sheet', 4, 'Range', 'E6');
    end
    
    if ~isempty(bufferWake)
        writecell({'total Wake epoches:'}, fname, 'Sheet', 4, 'Range', 'A7');
        writematrix(size(bufferWake, 1), fname, 'Sheet', 4, 'Range', 'D7');
        
        writecell({'average Wake duration per epoch:'}, fname, 'Sheet', 4, 'Range', 'A8');
        writematrix(mean(bufferWake(:,4)), fname, 'Sheet', 4, 'Range', 'D8');
        writecell({'(sec)'}, fname, 'Sheet', 4, 'Range', 'E8');
    end
    
    % Add spacing
    writecell({''}, fname, 'Sheet', 4, 'Range', 'A9');
    
    % Write REM epoch details header
    writecell({'----REM sleep epoches(#/startTime/endTime/duration(sec)/fileNum/lightDark/ZT-hour)---------'}, fname, 'Sheet', 4, 'Range', 'A10');
    
    % Add column headers for REM epochs (now with ZT-hour)
    writecell({'#', 'startTime', 'endTime', 'duration(sec)', 'fileNum', 'lightDark', 'ZT-hour'}, fname, 'Sheet', 4, 'Range', 'A11:G11');
    
    % Write REM epochs data
    if ~isempty(bufferREM)
        % Sort the epochs by start time
        [~, idx] = sort(bufferREM(:, 1));
        sortedREM = bufferREM(idx, :);
        
        % Include all columns including ZT-hour
        remEpochsTable = sortedREM(:, 1:7);
        
        % Convert numeric light/dark indicators to text labels
        lightDarkLabels = cell(size(remEpochsTable, 1), 1);
        for i = 1:size(remEpochsTable, 1)
            if remEpochsTable(i, 6) == 1
                lightDarkLabels{i} = 'Light';
            else
                lightDarkLabels{i} = 'Dark';
            end
        end
        
        % Write the REM epochs numeric data
        start_row = 12;
        end_row = start_row + size(remEpochsTable, 1) - 1;
        
        % Write columns 1-5 (unchanged)
        range = ['A' num2str(start_row) ':E' num2str(end_row)];
        writematrix(remEpochsTable(:, 1:5), fname, 'Sheet', 4, 'Range', range);
        
        % Write the light/dark text labels (column 6)
        range = ['F' num2str(start_row) ':F' num2str(end_row)];
        writecell(lightDarkLabels, fname, 'Sheet', 4, 'Range', range);
        
        % Write the ZT-hour values (column 7)
        range = ['G' num2str(start_row) ':G' num2str(end_row)];
        writematrix(remEpochsTable(:, 7), fname, 'Sheet', 4, 'Range', range);
    end
    
    % Add a mapping of file numbers to actual filenames for REM sheet
    if ~isempty(fileList)
        if ~isempty(bufferREM)
            file_map_row = end_row + 4;
        else
            file_map_row = 15; % Default if no REM data
        end
        
        % Header for file mapping
        writecell({'----File Number Mapping---------'}, fname, 'Sheet', 4, 'Range', ['A' num2str(file_map_row)]);
        writecell({'FileNum', 'Filename'}, fname, 'Sheet', 4, 'Range', ['A' num2str(file_map_row+1) ':B' num2str(file_map_row+1)]);
        
        % Create file mapping data
        fileNumData = (1:length(fileList))';
        fileNameData = cell(length(fileList), 1);
        
        for i = 1:length(fileList)
            [~, filename, ext] = fileparts(fileList{i});
            fileNameData{i} = [filename ext];
        end
        
        % Write file number mapping
        range = ['A' num2str(file_map_row+2) ':A' num2str(file_map_row+1+length(fileList))];
        writematrix(fileNumData, fname, 'Sheet', 4, 'Range', range);
        
        range = ['B' num2str(file_map_row+2) ':B' num2str(file_map_row+1+length(fileList))];
        writecell(fileNameData, fname, 'Sheet', 4, 'Range', range);
    end
    
    % Sheet 5 - Wake Epochs
    disp('Creating Wake epoch listing in Sheet 5');
    
    % Write sleep summary header for Wake sheet
    writecell({'----sleep summary---------'}, fname, 'Sheet', 5, 'Range', 'A1');
    
    % Write time summary with proper column placement
    writecell({'total Wake/NREM/REM time(min):'}, fname, 'Sheet', 5, 'Range', 'A2');
    writematrix([dur_24h(1,1), dur_24h(1,2), dur_24h(1,3)], fname, 'Sheet', 5, 'Range', 'D2:F2');
    
    % Add all epoch counts and details for consistency
    if ~isempty(bufferNREM)
        writecell({'total NREM sleep epoches:'}, fname, 'Sheet', 5, 'Range', 'A3');
        writematrix(size(bufferNREM, 1), fname, 'Sheet', 5, 'Range', 'D3');
        
        writecell({'average NREM sleep duration per epoch:'}, fname, 'Sheet', 5, 'Range', 'A4');
        writematrix(mean(bufferNREM(:,4)), fname, 'Sheet', 5, 'Range', 'D4');
        writecell({'(sec)'}, fname, 'Sheet', 5, 'Range', 'E4');
    end
    
    if ~isempty(bufferREM)
        writecell({'total REM sleep epoches:'}, fname, 'Sheet', 5, 'Range', 'A5');
        writematrix(size(bufferREM, 1), fname, 'Sheet', 5, 'Range', 'D5');
        
        writecell({'average REM sleep duration per epoch:'}, fname, 'Sheet', 5, 'Range', 'A6');
        writematrix(mean(bufferREM(:,4)), fname, 'Sheet', 5, 'Range', 'D6');
        writecell({'(sec)'}, fname, 'Sheet', 5, 'Range', 'E6');
    end
    
    if ~isempty(bufferWake)
        writecell({'total Wake epoches:'}, fname, 'Sheet', 5, 'Range', 'A7');
        writematrix(size(bufferWake, 1), fname, 'Sheet', 5, 'Range', 'D7');
        
        writecell({'average Wake duration per epoch:'}, fname, 'Sheet', 5, 'Range', 'A8');
        writematrix(mean(bufferWake(:,4)), fname, 'Sheet', 5, 'Range', 'D8');
        writecell({'(sec)'}, fname, 'Sheet', 5, 'Range', 'E8');
    end
    
    % Add spacing
    writecell({''}, fname, 'Sheet', 5, 'Range', 'A9');
    
    % Write Wake epoch details header
    writecell({'----Wake epoches(#/startTime/endTime/duration(sec)/fileNum/lightDark/ZT-hour)---------'}, fname, 'Sheet', 5, 'Range', 'A10');
    
    % Add column headers for Wake epochs (now with ZT-hour)
    writecell({'#', 'startTime', 'endTime', 'duration(sec)', 'fileNum', 'lightDark', 'ZT-hour'}, fname, 'Sheet', 5, 'Range', 'A11:G11');
    
    % Write Wake epochs data
    if ~isempty(bufferWake)
        % Sort the epochs by start time
        [~, idx] = sort(bufferWake(:, 1));
        sortedWake = bufferWake(idx, :);
        
        % Include all columns including ZT-hour
        wakeEpochsTable = sortedWake(:, 1:7);
        
        % Convert numeric light/dark indicators to text labels
        lightDarkLabels = cell(size(wakeEpochsTable, 1), 1);
        for i = 1:size(wakeEpochsTable, 1)
            if wakeEpochsTable(i, 6) == 1
                lightDarkLabels{i} = 'Light';
            else
                lightDarkLabels{i} = 'Dark';
            end
        end
        
        % Write the Wake epochs numeric data
        start_row = 12;
        end_row = start_row + size(wakeEpochsTable, 1) - 1;
        
        % Write columns 1-5 (unchanged)
        range = ['A' num2str(start_row) ':E' num2str(end_row)];
        writematrix(wakeEpochsTable(:, 1:5), fname, 'Sheet', 5, 'Range', range);
        
        % Write the light/dark text labels (column 6)
        range = ['F' num2str(start_row) ':F' num2str(end_row)];
        writecell(lightDarkLabels, fname, 'Sheet', 5, 'Range', range);
        
        % Write the ZT-hour values (column 7)
        range = ['G' num2str(start_row) ':G' num2str(end_row)];
        writematrix(wakeEpochsTable(:, 7), fname, 'Sheet', 5, 'Range', range);
    end
    
    % Add a mapping of file numbers to actual filenames for Wake sheet
    if ~isempty(fileList)
        if ~isempty(bufferWake)
            file_map_row = end_row + 4;
        else
            file_map_row = 15; % Default if no Wake data
        end
        
        % Header for file mapping
        writecell({'----File Number Mapping---------'}, fname, 'Sheet', 5, 'Range', ['A' num2str(file_map_row)]);
        writecell({'FileNum', 'Filename'}, fname, 'Sheet', 5, 'Range', ['A' num2str(file_map_row+1) ':B' num2str(file_map_row+1)]);
        
        % Create file mapping data
        fileNumData = (1:length(fileList))';
        fileNameData = cell(length(fileList), 1);
        
        for i = 1:length(fileList)
            [~, filename, ext] = fileparts(fileList{i});
            fileNameData{i} = [filename ext];
        end
        
        % Write file number mapping
        range = ['A' num2str(file_map_row+2) ':A' num2str(file_map_row+1+length(fileList))];
        writematrix(fileNumData, fname, 'Sheet', 5, 'Range', range);
        
        range = ['B' num2str(file_map_row+2) ':B' num2str(file_map_row+1+length(fileList))];
        writecell(fileNameData, fname, 'Sheet', 5, 'Range', range);
    end
    
    disp(['Data saved in Excel file: ' fname]);
end

% Main script execution flow
% Find all .mat files in all subfolders
allMatFiles = findAllMatFiles(base_folder);
disp(['Total .mat files found: ' num2str(length(allMatFiles))]);

% Sort the combined list
sortedMatFiles = sortMatFiles(allMatFiles);

% Check if batch_size is valid - must divide evenly into 24
if mod(24, batch_size) ~= 0
    % Get all valid batch sizes that divide evenly into 24
    validBatchSizes = [];
    for i = 1:24
        if mod(24, i) == 0
            validBatchSizes(end+1) = i;
        end
    end
    
    validBatchSizesStr = num2str(validBatchSizes);
    error(['Invalid batch size. Batch size must divide evenly into 24. ' ...
           'Valid batch sizes are: ' validBatchSizesStr]);
end

% Now check if we have enough files to process
totalFiles = length(sortedMatFiles);
if totalFiles < batch_size
    error(['Not enough files to form a complete batch. Found ' num2str(totalFiles) ...
           ' files, but batch size is ' num2str(batch_size) '.']);
end

% Create output directory in base folder if it doesn't exist
outputDir = fullfile(base_folder, 'batch_analysis_results');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Calculate how many complete batches we can process
numBatches = floor(totalFiles / batch_size);
disp(['Processing ' num2str(numBatches * batch_size) ' files in ' num2str(numBatches) ' batches of ' num2str(batch_size) ' files each.']);

if totalFiles > numBatches * batch_size
    remainingFiles = totalFiles - (numBatches * batch_size);
    disp(['Note: ' num2str(remainingFiles) ' files will not be processed because they don''t form a complete batch.']);
end

% Store batch file lists for summary report
batchFileLists = cell(numBatches, 1);

for batchIdx = 1:numBatches
    startIdx = (batchIdx - 1) * batch_size + 1;
    endIdx = batchIdx * batch_size;
    
    disp(['Batch ' num2str(batchIdx) ' of ' num2str(numBatches) ': Files ' num2str(startIdx) ' to ' num2str(endIdx)]);
    
    % Select the files for this batch
    batchFiles = sortedMatFiles(startIdx:endIdx);
    
    % Store this batch's file list for the summary report
    batchFileLists{batchIdx} = batchFiles;
    
    % Process this batch
    processFileBatch(batchFiles, batchIdx, startMin, lightseting, outputDir, lowpass_cutoff);
    disp('--------------------------------------------------');
end

disp('Processing complete for all batches!');

% Create a comprehensive summary file with all batches
summaryFilePath = fullfile(outputDir, 'processed_files_summary.txt');
fileID = fopen(summaryFilePath, 'w');

% Add header and timestamp
fprintf(fileID, 'SLEEP METRICS PROCESSING SUMMARY\n');
fprintf(fileID, 'Generated on: %s\n', datestr(now));
fprintf(fileID, 'Base folder: %s\n\n', base_folder);
fprintf(fileID, 'Total files found: %d\n', totalFiles);
fprintf(fileID, 'Batch size: %d\n', batch_size);
fprintf(fileID, 'Number of batches processed: %d\n\n', numBatches);

% List files by batch
for batchIdx = 1:numBatches
    batchFiles = batchFileLists{batchIdx};
    fprintf(fileID, '==== BATCH %d ====\n', batchIdx);
    for i = 1:length(batchFiles)
        fprintf(fileID, '%d. %s\n', i, batchFiles{i});
    end
    fprintf(fileID, '\n');
end

% Note any unprocessed files
if totalFiles > numBatches * batch_size
    remainingFiles = totalFiles - (numBatches * batch_size);
    fprintf(fileID, '==== FILES NOT PROCESSED ====\n');
    fprintf(fileID, '%d files were not processed because they don''t form a complete batch.\n\n', remainingFiles);
    
    % List the unprocessed files
    for i = (numBatches * batch_size + 1):totalFiles
        fprintf(fileID, '%d. %s\n', i - (numBatches * batch_size), sortedMatFiles{i});
    end
end

fclose(fileID);
disp(['Summary of processed files saved to: ' summaryFilePath]);
