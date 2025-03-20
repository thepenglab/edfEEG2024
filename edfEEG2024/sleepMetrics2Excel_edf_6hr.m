% analyze sleep patterns (use pre-analyzed mat-files) and export to excel
% updated 3/19/2025 - modified to process subfolders individually
%%
% ------------folder name first-------------
base_folder = '/Users/davidrivas/Documents/research/eeg/eeg-data/Artemis/K168-2/day3';
startMin = 0; % Start minute of processed data
lightseting = [6,18]; % Light on and off time

% Function to process a folder containing .mat files
function processFolder(folder, startMin, lightseting)
    disp(['Processing folder: ' folder]);
    
    % Data to calculate
    ztSleep = zeros(24,3);
    dur_perh = zeros(1,3);
    dur_24h = zeros(3,3);
    bouts = zeros(3,3);
    transit = zeros(1,5);
    
    % Get all .mat files in the current folder (non-recursive)
    files = dir(fullfile(folder, '*.mat'));
    matFilePaths = fullfile(folder, {files.name});
    
    % Sort .mat files within the current directory based on _mXX-XXX pattern
    timeIndices = zeros(length(matFilePaths), 1);
    for i = 1:length(matFilePaths)
        [~, name, ~] = fileparts(matFilePaths{i});
        match = regexp(name, '_m(\d+)-', 'tokens', 'once');
        if ~isempty(match)
            timeIndices(i) = str2double(match{1});
        else
            timeIndices(i) = inf; % Assign inf for files without a match (places them last)
        end
    end
    [~, sortIdx] = sort(timeIndices);
    fileList = matFilePaths(sortIdx);
    
    numFiles = length(fileList);
    disp(['Number of .mat files: ', num2str(numFiles)]);
    
    % If no files found, return
    if numFiles == 0
        disp('No .mat files found in this folder.');
        return;
    end
    
    disp(['Start Min(min): ', num2str(startMin)]);
    
    % Display sorted list
    disp('Sorted list of files:');
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
        disp('No valid data found in this folder.');
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
    
    % Calculate power (unchanged)
    pLen = size(specDat.p, 2);
    pLen = 201;
    power_sleep = zeros(pLen, 6);  % power in NREMS (0-20Hz), [original, relative] for Wake/NREM/REM
    pm0 = mean(bufferPower);
    % normalize to total power (0-50Hz)
    powerMap = 100 * bufferPower ./ sum(pm0);
    idx = (bufferState == 0);
    power_sleep(:, 1) = mean(bufferPower(idx, :));
    power_sleep(:, 2) = mean(powerMap(idx, :));
    % for NREM sleep
    idx = (bufferState == 1);
    power_sleep(:, 3) = mean(bufferPower(idx, :));
    power_sleep(:, 4) = mean(powerMap(idx, :));
    % for REM sleep
    idx = (bufferState == 2);
    power_sleep(:, 5) = mean(bufferPower(idx, :));
    power_sleep(:, 6) = mean(powerMap(idx, :));
    
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
    f1 = fullfile(folder, 'durations_hourly.png');
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
        f1 = fullfile(folder, 'durations_ZT.png');
        F = getframe(gcf);
        imwrite(F.cdata, f1);
        close;
    end
    
    % Plot spectral information (unchanged)
    figure;
    fHz = linspace(specDat.fsRange(1), specDat.fsRange(2), size(power_sleep, 1));
    subplot(1, 3, 1);
    plot(fHz, power_sleep(:, 2));
    title('EEG power in Wake'); 
    ylabel('power');
    xlabel('frequency (Hz)');
    set(gca, 'xlim', [0, 50]);
    subplot(1, 3, 2);
    plot(fHz, power_sleep(:, 4));
    title('EEG power in NREM sleep'); 
    ylabel('power');
    xlabel('frequency (Hz)');
    set(gca, 'xlim', [0, 50]);
    subplot(1, 3, 3);
    plot(fHz, power_sleep(:, 6));
    title('EEG power in REM sleep'); 
    ylabel('power');
    xlabel('frequency (Hz)');
    set(gca, 'xlim', [0, 50]);
    f1 = fullfile(folder, 'spectral.png');
    F = getframe(gcf);
    imwrite(F.cdata, f1);
    close;
    
    %%
    % Export data to an Excel file (unchanged)
    nowstr = datestr(now, 30);
    [~, folderName] = fileparts(folder);
    FileName = ['sleepMetrics_' folderName '_' nowstr '.xls'];
    fname = fullfile(folder, FileName);
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
    
    % Sheet 2 - spectral
    label1 = {'F(hz)', 'wake-p0', 'wake-p1', 'NREM-p0', 'NREM-p1', 'REM-p0', 'REM-p1'};
    writecell(label1, fname, 'Sheet', 2, 'Range', 'A1:G1'); 
    lidx = ['A2:G', num2str(1+length(fHz))];
    writematrix([fHz', power_sleep], fname, 'Sheet', 2, 'Range', lidx);
    
    % Sheet 3 - original hourly
    label1 = {'Hour#', 'Wake', 'NREMS', 'REMS'};
    writecell(label1, fname, 'Sheet', 3, 'Range', 'A1:D1'); 
    lidx = ['A2:D', num2str(1+totalHour)];
    writematrix([tm, dur_perh], fname, 'Sheet', 3, 'Range', lidx);
    disp(['Data saved in Excel file: ' fname]);
    
    % Display summary
    disp('Bout summary:');
    disp(bouts);
    disp('Transition summary:');
    disp(transit);
end

% Function to find all subfolders with .mat files
function subfolders = findSubfoldersWithMatFiles(baseFolder)
    % Get all subfolders
    allFolders = genpath(baseFolder);
    folderList = strsplit(allFolders, pathsep);
    
    % Find subfolders containing .mat files
    subfolders = {};
    for i = 1:length(folderList)
        if ~isempty(folderList{i})
            files = dir(fullfile(folderList{i}, '*.mat'));
            if ~isempty(files)
                subfolders{end+1} = folderList{i};
            end
        end
    end
end

% Find all subfolders with .mat files
subfoldersWithMat = findSubfoldersWithMatFiles(base_folder);
disp(['Found ' num2str(length(subfoldersWithMat)) ' subfolders with .mat files']);

% Process each subfolder individually
for i = 1:length(subfoldersWithMat)
    disp(['Processing subfolder ' num2str(i) ' of ' num2str(length(subfoldersWithMat))]);
    disp(['Folder: ' subfoldersWithMat{i}]);
    processFolder(subfoldersWithMat{i}, startMin, lightseting);
    disp('--------------------------------------------------');
end

disp('Processing complete for all subfolders!');
