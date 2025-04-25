% Script to analyze mouse sleep data by genotype
% This script:
% 1. Finds all XLS files in subfolders (one folder per mouse)
% 2. Groups mice by genotype (wild-type or mutant)
% 3. Retrieves epoch durations for each mouse and sleep state
% 4. Bins the epochs by their duration (0s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 512s)
% 5. Computes averages and standard deviations by genotype
% 6. Plots results as line, bar, and dot graphs with error bars

%% Parameters and Setup
mainFolder = '/Users/davidrivas/Documents/research/eeg/eeg-data/Artemis'; % Use current directory, or specify your path
genotypes = {'wild-type', 'mutant'}; % Define genotypes 
batchAnalysisFolder = 'batch_analysis_results'; % Name of the subfolder containing .xls files
summaryFilename = 'processed_files_summary.txt'; % Name of the summary file

% Define bin edges for epoch durations (in seconds)
binEdges = [0, 4, 8, 16, 32, 64, 128, 256, 512, inf];
binLabels = {'0-4s', '4-8s', '8-16s', '16-32s', '32-64s', '64-128s', '128-256s', '256-512s', '>512s'};
numBins = length(binLabels);

% Create output folder for saving figures
outputFolder = fullfile(mainFolder, 'compiled_plots');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    fprintf('Created output folder: %s\n', outputFolder);
else
    fprintf('Using existing output folder: %s\n', outputFolder);
end

% Create structures to store binned epoch counts by genotype
epochCounts = struct();
epochCounts.wild_type = struct('nrem', zeros(0, numBins), 'rem', zeros(0, numBins), 'wake', zeros(0, numBins));
epochCounts.mutant = struct('nrem', zeros(0, numBins), 'rem', zeros(0, numBins), 'wake', zeros(0, numBins));

% Create structure to store animal IDs by genotype
animalIDs = struct();
animalIDs.wild_type = {};
animalIDs.mutant = {};

%% Find all mouse folders and extract animal IDs
allFolders = dir(mainFolder);
mouseFolders = allFolders([allFolders.isdir] & ~ismember({allFolders.name}, {'.', '..'}));

% Extract animal IDs from folder names
mouseIDs = cell(length(mouseFolders), 1);
for i = 1:length(mouseFolders)
    mouseIDs{i} = mouseFolders(i).name;
end

% Display all discovered animal IDs
fprintf('Discovered animal IDs:\n');
for i = 1:length(mouseIDs)
    fprintf('  %d. %s\n', i, mouseIDs{i});
end
fprintf('\n');

% Prompt user to identify wild-type mice
fprintf('Please enter the IDs of wild-type mice, separated by commas:\n');
wtInput = input('Wild-type mice: ', 's');
% Process the input - split by commas and trim whitespace
wtMice = strtrim(split(wtInput, ','));
for i = 1:length(wtMice)
    wtMice{i} = strtrim(wtMice{i});
end

% Prompt user to identify mutant mice
fprintf('Please enter the IDs of mutant mice, separated by commas:\n');
mutInput = input('Mutant mice: ', 's');
% Process the input - split by commas and trim whitespace
mutMice = strtrim(split(mutInput, ','));
for i = 1:length(mutMice)
    mutMice{i} = strtrim(mutMice{i});
end

% Verify inputs and warn about any unlisted mice
allListedMice = [wtMice; mutMice];
unlistedMice = setdiff(mouseIDs, allListedMice);
if ~isempty(unlistedMice)
    fprintf('\nWarning: The following mice were not assigned to any genotype and will be skipped:\n');
    for i = 1:length(unlistedMice)
        fprintf('  %s\n', unlistedMice{i});
    end
    fprintf('\n');
end

% Make sure there's no overlap between wild-type and mutant mice
commonMice = intersect(wtMice, mutMice);
if ~isempty(commonMice)
    fprintf('\nERROR: The following mice were assigned to both genotypes:\n');
    for i = 1:length(commonMice)
        fprintf('  %s\n', commonMice{i});
    end
    error('Mice cannot be assigned to both genotypes. Please restart the script and provide non-overlapping lists.');
end

fprintf('Processing will begin with:\n');
fprintf('  Wild-type mice: %s\n', strjoin(wtMice, ', '));
fprintf('  Mutant mice: %s\n\n', strjoin(mutMice, ', '));

%% Process each mouse folder
% Create a structure to store total epoch counts per mouse
totalCounts = struct();
totalCounts.wild_type = struct('nrem', [], 'rem', [], 'wake', []);
totalCounts.mutant = struct('nrem', [], 'rem', [], 'wake', []);

for i = 1:length(mouseFolders)
    currentMouseFolder = fullfile(mainFolder, mouseFolders(i).name);
    currentMouseID = mouseFolders(i).name;
    
    % Determine genotype based on user input
    if ismember(currentMouseID, wtMice)
        mouseGenotype = 'wild_type';
    elseif ismember(currentMouseID, mutMice)
        mouseGenotype = 'mutant';
    else
        % Skip mice not assigned to any genotype
        fprintf('Skipping mouse %s (no genotype assigned)...\n', currentMouseID);
        continue;
    end
    
    fprintf('Processing mouse %s (genotype: %s)...\n', currentMouseID, strrep(mouseGenotype, '_', '-'));
    
    % Look for the batch_analysis_results subfolder
    batchFolder = fullfile(currentMouseFolder, batchAnalysisFolder);
    
    if ~exist(batchFolder, 'dir')
        fprintf('  Warning: No %s folder found for mouse %s. Skipping...\n', batchAnalysisFolder, currentMouseID);
        continue;
    end
    
    % Look for processed_files_summary.txt file in the batch_analysis_results folder
    summaryFile = fullfile(batchFolder, summaryFilename);
    
    % Initialize batch size with default value
    batchSize = 0;
    batchesToProcess = [];
    
    % Check if summary file exists
    if exist(summaryFile, 'file')
        fprintf('  Found summary file: %s\n', summaryFile);
        
        % Read the summary file
        fileID = fopen(summaryFile, 'r');
        if fileID ~= -1
            % Read the first 10 lines to find batch size
            for j = 1:10
                line = fgetl(fileID);
                if ~ischar(line)
                    break; % End of file
                end
                
                % Check if this line contains batch size information
                batchSizeMatch = regexp(line, 'Batch size:\s*(\d+)', 'tokens');
                if ~isempty(batchSizeMatch)
                    batchSize = str2double(batchSizeMatch{1}{1});
                    fprintf('  Detected batch size: %d\n', batchSize);
                    break;
                end
            end
            fclose(fileID);
            
            % If batch size is 6, process specific batches
            if batchSize == 6
                batchesToProcess = 2:9; % Process batches 2 through 9
                fprintf('  Will process batches 2 through 9 only\n');
            else
                fprintf('  Batch size is not 6, will process all available .xls files\n');
                batchesToProcess = []; % Process all batches
            end
        else
            fprintf('  Warning: Could not open summary file for mouse %s\n', currentMouseID);
        end
    else
        fprintf('  Warning: No summary file found in %s folder for mouse %s. Will process all .xls files.\n', batchAnalysisFolder, currentMouseID);
    end
    
    % Find all XLS files in the batch_analysis_results folder
    xlsFiles = dir(fullfile(batchFolder, '*.xls'));
    
    if isempty(xlsFiles)
        fprintf('  Warning: No .xls files found in %s folder for mouse %s. Skipping...\n', batchAnalysisFolder, currentMouseID);
        continue;
    end
    
    % Filter XLS files based on batch size if needed
    if ~isempty(batchesToProcess)
        fprintf('  Filtering .xls files to include only batches 2-9...\n');
        
        % Initialize array for filtered files
        filteredFiles = [];
        
        for k = 1:length(xlsFiles)
            fname = xlsFiles(k).name;
            % Extract batch number using regular expressions
            tokens = regexp(fname, 'sleepMetrics_batch(\d+)', 'tokens');
            if ~isempty(tokens)
                batchNum = str2double(tokens{1}{1});
                if ismember(batchNum, batchesToProcess)
                    filteredFiles = [filteredFiles; xlsFiles(k)];
                    fprintf('    Including file: %s\n', fname);
                else
                    fprintf('    Excluding file: %s (not in batches 2-9)\n', fname);
                end
            else
                fprintf('    Excluding file: %s (does not match naming convention)\n', fname);
            end
        end
        
        % Replace the original files list with the filtered one
        xlsFiles = filteredFiles;
        
        if isempty(xlsFiles)
            fprintf('  Warning: No matching .xls files found after filtering for mouse %s. Skipping...\n', currentMouseID);
            continue;
        end
    end
    
    % Extract batch numbers and sort accordingly
    batchNumbers = zeros(length(xlsFiles), 1);
    for k = 1:length(xlsFiles)
        fname = xlsFiles(k).name;
        % Extract number after 'batch' using regular expressions
        tokens = regexp(fname, 'batch(\d+)', 'tokens');
        if ~isempty(tokens)
            batchNumbers(k) = str2double(tokens{1}{1});
        else
            warning('Filename "%s" does not contain a recognizable batch number.', fname);
            batchNumbers(k) = inf;  % Sort unrecognized files to the end
        end
    end
    
    % Sort files by batch number
    [~, sortedIdx] = sort(batchNumbers);
    xlsFiles = xlsFiles(sortedIdx);
    
    % Initialize arrays to store epoch durations for this mouse
    nremEpochs = [];
    remEpochs = [];
    wakeEpochs = [];
    
    % Process each XLS file for this mouse
    for j = 1:length(xlsFiles)
        xlsPath = fullfile(xlsFiles(j).folder, xlsFiles(j).name);
        fprintf('  Processing file: %s\n', xlsFiles(j).name);
            
        try
            % Read NREM epoch durations (sheet 3)
            try
                % Read using readmatrix
                opts = detectImportOptions(xlsPath, 'Sheet', 3);
                if ~isempty(opts.VariableNames)
                    % Try to find the duration column by name
                    durIdx = find(contains(opts.VariableNames, 'duration', 'IgnoreCase', true));
                    if ~isempty(durIdx)
                        % Set all variables to be imported as numeric
                        opts = setvartype(opts, 'numeric');
                        % Read only the duration column
                        opts.SelectedVariableNames = opts.VariableNames(durIdx(1));
                        data = readmatrix(xlsPath, opts);
                        
                        % Add valid durations to collection
                        validDurations = data(~isnan(data));
                        nremEpochs = [nremEpochs; validDurations];
                        fprintf('    Found %d NREM epochs\n', length(validDurations));
                    else
                        % Fall back to reading raw data and extracting column D
                        data = readmatrix(xlsPath, 'Sheet', 3);
                        if size(data, 2) >= 4 % Ensure we have at least 4 columns
                            % Extract column D (4th column)
                            colData = data(:, 4);
                            % Skip first 11 rows (headers) and get valid data
                            validRows = 12:size(colData, 1);
                            if any(validRows)
                                validDurations = colData(validRows);
                                validDurations = validDurations(~isnan(validDurations));
                                nremEpochs = [nremEpochs; validDurations];
                                fprintf('    Found %d NREM epochs\n', length(validDurations));
                            else
                                fprintf('    No valid NREM epochs found\n');
                            end
                        else
                            fprintf('    NREM sheet has fewer than 4 columns\n');
                        end
                    end
                else
                    fprintf('    Unable to detect column headers in NREM sheet\n');
                end
            catch e
                fprintf('    Error reading NREM sheet: %s\n', e.message);
                
                % Try using basic Excel reading
                try
                    [num, ~, ~] = xlsread(xlsPath, 3);
                    if size(num, 2) >= 4
                        % Find all non-NaN values in column 4 (D)
                        colData = num(:, 4);
                        validDurations = colData(~isnan(colData));
                        nremEpochs = [nremEpochs; validDurations];
                        fprintf('    Found %d NREM epochs using fallback method\n', length(validDurations));
                    else
                        fprintf('    NREM sheet has fewer than 4 columns in fallback method\n');
                    end
                catch e2
                    fprintf('    Error in fallback method for NREM sheet: %s\n', e2.message);
                end
            end
            
            % Read REM epoch durations (sheet 4)
            try
                % Read using readmatrix
                opts = detectImportOptions(xlsPath, 'Sheet', 4);
                if ~isempty(opts.VariableNames)
                    durIdx = find(contains(opts.VariableNames, 'duration', 'IgnoreCase', true));
                    if ~isempty(durIdx)
                        opts = setvartype(opts, 'numeric');
                        opts.SelectedVariableNames = opts.VariableNames(durIdx(1));
                        data = readmatrix(xlsPath, opts);
                        
                        validDurations = data(~isnan(data));
                        remEpochs = [remEpochs; validDurations];
                        fprintf('    Found %d REM epochs\n', length(validDurations));
                    else
                        % Fall back to reading raw data and extracting column D
                        data = readmatrix(xlsPath, 'Sheet', 4);
                        if size(data, 2) >= 4
                            colData = data(:, 4);
                            validRows = 12:size(colData, 1);
                            if any(validRows)
                                validDurations = colData(validRows);
                                validDurations = validDurations(~isnan(validDurations));
                                remEpochs = [remEpochs; validDurations];
                                fprintf('    Found %d REM epochs\n', length(validDurations));
                            else
                                fprintf('    No valid REM epochs found\n');
                            end
                        else
                            fprintf('    REM sheet has fewer than 4 columns\n');
                        end
                    end
                else
                    fprintf('    Unable to detect column headers in REM sheet\n');
                end
            catch e
                fprintf('    Error reading REM sheet: %s\n', e.message);
                
                try
                    % Try using basic Excel reading
                    [num, ~, ~] = xlsread(xlsPath, 4);
                    if size(num, 2) >= 4
                        colData = num(:, 4);
                        validDurations = colData(~isnan(colData));
                        remEpochs = [remEpochs; validDurations];
                        fprintf('    Found %d REM epochs using fallback method\n', length(validDurations));
                    else
                        fprintf('    REM sheet has fewer than 4 columns in fallback method\n');
                    end
                catch e2
                    fprintf('    Error in fallback method for REM sheet: %s\n', e2.message);
                end
            end
            
            % Read Wake epoch durations (sheet 5)
            try
                % Read using readmatrix
                opts = detectImportOptions(xlsPath, 'Sheet', 5);
                if ~isempty(opts.VariableNames)
                    durIdx = find(contains(opts.VariableNames, 'duration', 'IgnoreCase', true));
                    if ~isempty(durIdx)
                        opts = setvartype(opts, 'numeric');
                        opts.SelectedVariableNames = opts.VariableNames(durIdx(1));
                        data = readmatrix(xlsPath, opts);
                        
                        validDurations = data(~isnan(data));
                        wakeEpochs = [wakeEpochs; validDurations];
                        fprintf('    Found %d Wake epochs\n', length(validDurations));
                    else
                        % Fall back to reading raw data and extracting column D
                        data = readmatrix(xlsPath, 'Sheet', 5);
                        if size(data, 2) >= 4
                            colData = data(:, 4);
                            validRows = 12:size(colData, 1);
                            if any(validRows)
                                validDurations = colData(validRows);
                                validDurations = validDurations(~isnan(validDurations));
                                wakeEpochs = [wakeEpochs; validDurations];
                                fprintf('    Found %d Wake epochs\n', length(validDurations));
                            else
                                fprintf('    No valid Wake epochs found\n');
                            end
                        else
                            fprintf('    Wake sheet has fewer than 4 columns\n');
                        end
                    end
                else
                    fprintf('    Unable to detect column headers in Wake sheet\n');
                end
            catch e
                fprintf('    Error reading Wake sheet: %s\n', e.message);
                
                try
                    % Try using basic Excel reading
                    [num, ~, ~] = xlsread(xlsPath, 5);
                    if size(num, 2) >= 4
                        colData = num(:, 4);
                        validDurations = colData(~isnan(colData));
                        wakeEpochs = [wakeEpochs; validDurations];
                        fprintf('    Found %d Wake epochs using fallback method\n', length(validDurations));
                    else
                        fprintf('    Wake sheet has fewer than 4 columns in fallback method\n');
                    end
                catch e2
                    fprintf('    Error in fallback method for Wake sheet: %s\n', e2.message);
                end
            end
        catch e
            fprintf('    Error processing file %s: %s\n', xlsFiles(j).name, e.message);
            continue;
        end
    end
    
    % Store total counts for this mouse
    if ~isfield(totalCounts.(mouseGenotype), 'mouseIDs')
        totalCounts.(mouseGenotype).mouseIDs = {};
    end
    totalCounts.(mouseGenotype).mouseIDs{end+1} = currentMouseID;
    totalCounts.(mouseGenotype).nrem(end+1) = length(nremEpochs);
    totalCounts.(mouseGenotype).rem(end+1) = length(remEpochs);
    totalCounts.(mouseGenotype).wake(end+1) = length(wakeEpochs);

    % Bin the epochs by duration for this mouse
    nremBinCounts = histcounts(nremEpochs, binEdges);
    remBinCounts = histcounts(remEpochs, binEdges);
    wakeBinCounts = histcounts(wakeEpochs, binEdges);
    
    % Store the binned data for this mouse
    epochCounts.(mouseGenotype).nrem = [epochCounts.(mouseGenotype).nrem; nremBinCounts];
    epochCounts.(mouseGenotype).rem = [epochCounts.(mouseGenotype).rem; remBinCounts];
    epochCounts.(mouseGenotype).wake = [epochCounts.(mouseGenotype).wake; wakeBinCounts];
    
    % Store animal ID
    animalIDs.(mouseGenotype){end+1} = currentMouseID;
    
    % Display summary for this mouse
    fprintf('  Summary for mouse %s:\n', currentMouseID);
    fprintf('    NREM epochs: %d (binned: %s)\n', length(nremEpochs), mat2str(nremBinCounts));
    fprintf('    REM epochs: %d (binned: %s)\n', length(remEpochs), mat2str(remBinCounts));
    fprintf('    Wake epochs: %d (binned: %s)\n', length(wakeEpochs), mat2str(wakeBinCounts));
end

%% Calculate statistics by genotype
% Initialize structures for mean and std values
meanCounts = struct();
stdCounts = struct();
semCounts = struct(); % Standard error of the mean

for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    if isfield(epochCounts, gen)
        % Calculate mean and std for NREM
        if ~isempty(epochCounts.(gen).nrem)
            meanCounts.(gen).nrem = mean(epochCounts.(gen).nrem, 1);
            stdCounts.(gen).nrem = std(epochCounts.(gen).nrem, 0, 1);
            semCounts.(gen).nrem = stdCounts.(gen).nrem / sqrt(size(epochCounts.(gen).nrem, 1));
        else
            fprintf('No NREM epoch data found for genotype: %s\n', gen);
            meanCounts.(gen).nrem = zeros(1, numBins);
            stdCounts.(gen).nrem = zeros(1, numBins);
            semCounts.(gen).nrem = zeros(1, numBins);
        end
        
        % Calculate mean and std for REM
        if ~isempty(epochCounts.(gen).rem)
            meanCounts.(gen).rem = mean(epochCounts.(gen).rem, 1);
            stdCounts.(gen).rem = std(epochCounts.(gen).rem, 0, 1);
            semCounts.(gen).rem = stdCounts.(gen).rem / sqrt(size(epochCounts.(gen).rem, 1));
        else
            fprintf('No REM epoch data found for genotype: %s\n', gen);
            meanCounts.(gen).rem = zeros(1, numBins);
            stdCounts.(gen).rem = zeros(1, numBins);
            semCounts.(gen).rem = zeros(1, numBins);
        end
        
        % Calculate mean and std for Wake
        if ~isempty(epochCounts.(gen).wake)
            meanCounts.(gen).wake = mean(epochCounts.(gen).wake, 1);
            stdCounts.(gen).wake = std(epochCounts.(gen).wake, 0, 1);
            semCounts.(gen).wake = stdCounts.(gen).wake / sqrt(size(epochCounts.(gen).wake, 1));
        else
            fprintf('No Wake epoch data found for genotype: %s\n', gen);
            meanCounts.(gen).wake = zeros(1, numBins);
            stdCounts.(gen).wake = zeros(1, numBins);
            semCounts.(gen).wake = zeros(1, numBins);
        end
    end
end

%% Export statistics to multiple sheets in an Excel file
fprintf('Creating Excel export with multiple sheets...\n');

% Create a consistent bin labels array that includes "Total"
allBinLabels = ['Total'; binLabels']; 

% 1. Create table for individual mouse data
mouseDataTable = array2table(zeros(length(allBinLabels), 0));
mouseDataTable.Bin = allBinLabels;

fprintf('Preparing individual mouse data sheet...\n');
% Add columns for each individual mouse
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    
    if isfield(animalIDs, gen) && ~isempty(animalIDs.(gen))
        for m = 1:length(animalIDs.(gen))
            mouseID = animalIDs.(gen){m};
            fprintf('  Adding data for mouse: %s\n', mouseID);
            
            % Create complete data columns including totals and binned data
            if isfield(totalCounts, gen) && length(totalCounts.(gen).nrem) >= m
                nremData = [totalCounts.(gen).nrem(m); epochCounts.(gen).nrem(m,:)'];
                remData = [totalCounts.(gen).rem(m); epochCounts.(gen).rem(m,:)'];
                wakeData = [totalCounts.(gen).wake(m); epochCounts.(gen).wake(m,:)'];
                
                % Add as full columns to avoid dimension warnings
                mouseDataTable.([mouseID '_NREM']) = nremData;
                mouseDataTable.([mouseID '_REM']) = remData;
                mouseDataTable.([mouseID '_Wake']) = wakeData;
            end
        end
    end
end

% 2. Create table for genotype statistics
genotypeStatsTable = array2table(zeros(length(allBinLabels), 0));
genotypeStatsTable.Bin = allBinLabels;

fprintf('Preparing genotype statistics sheet...\n');
% Add columns for each genotype with simplified names
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    display_name = strrep(gen, '_', '-'); % Convert 'wild_type' to 'wild-type'
    
    if isfield(totalCounts, gen)
        % Create complete data columns including total statistics and binned statistics
        % Use simplified genotype names for column headers
        
        % Mean columns
        genotypeStatsTable.([display_name '_NREM_Mean']) = [mean(totalCounts.(gen).nrem); meanCounts.(gen).nrem'];
        genotypeStatsTable.([display_name '_REM_Mean']) = [mean(totalCounts.(gen).rem); meanCounts.(gen).rem'];
        genotypeStatsTable.([display_name '_Wake_Mean']) = [mean(totalCounts.(gen).wake); meanCounts.(gen).wake'];
        
        % SD columns
        genotypeStatsTable.([display_name '_NREM_SD']) = [std(totalCounts.(gen).nrem); stdCounts.(gen).nrem'];
        genotypeStatsTable.([display_name '_REM_SD']) = [std(totalCounts.(gen).rem); stdCounts.(gen).rem'];
        genotypeStatsTable.([display_name '_Wake_SD']) = [std(totalCounts.(gen).wake); stdCounts.(gen).wake'];
        
        % SEM columns
        totalSEM_nrem = std(totalCounts.(gen).nrem)/sqrt(length(totalCounts.(gen).nrem));
        totalSEM_rem = std(totalCounts.(gen).rem)/sqrt(length(totalCounts.(gen).rem));
        totalSEM_wake = std(totalCounts.(gen).wake)/sqrt(length(totalCounts.(gen).wake));
        
        genotypeStatsTable.([display_name '_NREM_SEM']) = [totalSEM_nrem; semCounts.(gen).nrem'];
        genotypeStatsTable.([display_name '_REM_SEM']) = [totalSEM_rem; semCounts.(gen).rem'];
        genotypeStatsTable.([display_name '_Wake_SEM']) = [totalSEM_wake; semCounts.(gen).wake'];
    end
end

% 3. Create a summary table mapping mice to genotypes
mouseGenotypeSummary = table();
mouseGenotypeSummary.MouseID = [animalIDs.wild_type(:); animalIDs.mutant(:)];
genotypes_list = [repmat({'wild-type'}, length(animalIDs.wild_type), 1); 
                  repmat({'mutant'}, length(animalIDs.mutant), 1)];
mouseGenotypeSummary.Genotype = genotypes_list;

% 4. Write all tables to different sheets in the Excel file
xlsFilePath = fullfile(mainFolder, 'sleep_epoch_analysis.xls');
fprintf('Writing data to Excel file: %s\n', xlsFilePath);

% Write to Excel file - different sheets
writetable(mouseDataTable, xlsFilePath, 'Sheet', 'Mouse_Data');
writetable(genotypeStatsTable, xlsFilePath, 'Sheet', 'Genotype_Statistics');
writetable(mouseGenotypeSummary, xlsFilePath, 'Sheet', 'Mouse_Genotypes');

fprintf('Excel file created successfully.\n');

%% Create figures
% Colors for plotting
wtColor = [0, 0, 0.8]; % Blue for wild-type
mutColor = [0.8, 0, 0]; % Red for mutant

% Create figures for each sleep state (NREM, REM, Wake)
states = {'nrem', 'rem', 'wake'};
stateLabels = {'NREM', 'REM', 'Wake'};

for s = 1:length(states)
    state = states{s};
    stateLabel = stateLabels{s};
    
    %% 1. Line Plot
    figure('Name', [stateLabel ' Epoch Durations - Line Plot'], 'Position', [100, 100, 800, 500]);
    hold on;
    
    % Plot wild-type data with error bars
    if isfield(meanCounts, 'wild_type') && all(isfinite(meanCounts.wild_type.(state)))
        errorbar(1:numBins, meanCounts.wild_type.(state), semCounts.wild_type.(state), ...
            'Color', wtColor, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', wtColor, 'MarkerSize', 8);
    end
    
    % Plot mutant data with error bars
    if isfield(meanCounts, 'mutant') && all(isfinite(meanCounts.mutant.(state)))
        errorbar(1:numBins, meanCounts.mutant.(state), semCounts.mutant.(state), ...
            'Color', mutColor, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', mutColor, 'MarkerSize', 8);
    end
    
    % Add labels and legend
    title([stateLabel ' Sleep Epoch Durations']);
    xlabel('Epoch Duration');
    ylabel('Number of Bouts');
    set(gca, 'XTick', 1:numBins, 'XTickLabel', binLabels);
    xtickangle(45);
    legend('Wild-type (Mean ± SEM)', 'Mutant (Mean ± SEM)', 'Location', 'best');
    grid on;
    hold off;
    
    % Save the figure
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Line.fig']));
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Line.png']));
    
    %% 2. Bar Plot
    figure('Name', [stateLabel ' Epoch Durations - Bar Plot'], 'Position', [100, 100, 800, 500]);
    hold on;
    
    % Bar width and positions
    barWidth = 0.35;
    wtPos = (1:numBins) - barWidth/2;
    mutPos = (1:numBins) + barWidth/2;
    
    % Plot wild-type bars
    if isfield(meanCounts, 'wild_type') && all(isfinite(meanCounts.wild_type.(state)))
        barHandles(1) = bar(wtPos, meanCounts.wild_type.(state), barWidth, 'FaceColor', wtColor);
        
        % Add error bars
        errorbar(wtPos, meanCounts.wild_type.(state), stdCounts.wild_type.(state), '.k');
    end
    
    % Plot mutant bars
    if isfield(meanCounts, 'mutant') && all(isfinite(meanCounts.mutant.(state)))
        barHandles(2) = bar(mutPos, meanCounts.mutant.(state), barWidth, 'FaceColor', mutColor);
        
        % Add error bars
        errorbar(mutPos, meanCounts.mutant.(state), stdCounts.mutant.(state), '.k');
    end
    
    % Add labels and legend
    title([stateLabel ' Sleep Epoch Durations']);
    xlabel('Epoch Duration');
    ylabel('Number of Bouts');
    set(gca, 'XTick', 1:numBins, 'XTickLabel', binLabels);
    xtickangle(45);
    
    % Add legend if both genotypes have data
    if exist('barHandles', 'var') && length(barHandles) >= 2
        legend(barHandles, {'Wild-type (Mean ± SD)', 'Mutant (Mean ± SD)'}, 'Location', 'best');
    end
    
    grid on;
    hold off;
    
    % Save the figure
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Bar.fig']));
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Bar.png']));
    
    %% 3. Dot Plot (Individual mice with mean)
    figure('Name', [stateLabel ' Epoch Durations - Dot Plot'], 'Position', [100, 100, 800, 500]);
    hold on;
    
    % Initialize handles for legend
    plotHandles = [];
    legendTexts = {};
    
    % Plot individual data points for wild-type
    if isfield(epochCounts, 'wild_type') && ~isempty(epochCounts.wild_type.(state))
        for i = 1:size(epochCounts.wild_type.(state), 1)
            scatter(1:numBins, epochCounts.wild_type.(state)(i,:), 50, wtColor, 'o', 'filled', 'MarkerFaceAlpha', 0.3);
        end
        
        % Plot mean with error bars and capture handle
        h_wt = errorbar(1:numBins, meanCounts.wild_type.(state), semCounts.wild_type.(state), ...
            'Color', wtColor, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', wtColor, 'MarkerSize', 10);
        
        % Add to legend arrays
        plotHandles = [plotHandles, h_wt];
        legendTexts{end+1} = 'Wild-type (Mean ± SEM)';
    end
    
    % Plot individual data points for mutant
    if isfield(epochCounts, 'mutant') && ~isempty(epochCounts.mutant.(state))
        for i = 1:size(epochCounts.mutant.(state), 1)
            scatter((1:numBins)+0.2, epochCounts.mutant.(state)(i,:), 50, mutColor, 'o', 'filled', 'MarkerFaceAlpha', 0.3);
        end
        
        % Plot mean with error bars and capture handle
        h_mut = errorbar((1:numBins)+0.2, meanCounts.mutant.(state), semCounts.mutant.(state), ...
            'Color', mutColor, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', mutColor, 'MarkerSize', 10);
        
        % Add to legend arrays
        plotHandles = [plotHandles, h_mut];
        legendTexts{end+1} = 'Mutant (Mean ± SEM)';
    end
    
    % Add labels and legend
    title([stateLabel ' Sleep Epoch Durations']);
    xlabel('Epoch Duration');
    ylabel('Number of Bouts');
    set(gca, 'XTick', 1:numBins, 'XTickLabel', binLabels);
    xtickangle(45);
    
    % Create legend with handles
    if ~isempty(plotHandles)
        legend(plotHandles, legendTexts, 'Location', 'best');
    end
    
    grid on;
    hold off;
    
    % Save the figure
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Dot.fig']));
    saveas(gcf, fullfile(outputFolder, [stateLabel '_Epochs_Dot.png']));
end

fprintf('All figures saved to %s\n', outputFolder);