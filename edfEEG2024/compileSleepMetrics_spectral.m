% Script to analyze mouse sleep data by genotype
% This script:
% 1. Finds all XLS files in subfolders (one folder per mouse)
% 2. Groups mice by genotype (wild-type or mutant)
% 3. Retrieves relative power metrics for each mouse
% 4. Computes averages and standard deviations by genotype
% 5. Plots results as line graphs with error bands

%% Parameters and Setup
mainFolder = '/Users/davidrivas/Documents/research/eeg/eeg-data/Artemis'; % Use current directory, or specify your path
genotypes = {'wild-type', 'mutant'}; % Define genotypes 
batchAnalysisFolder = 'batch_analysis_results'; % Name of the subfolder containing .xls files
summaryFilename = 'processed_files_summary.txt'; % Name of the summary file

% Create output folder for saving figures
outputFolder = fullfile(mainFolder, 'compiled_plots');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    fprintf('Created output folder: %s\n', outputFolder);
else
    fprintf('Using existing output folder: %s\n', outputFolder);
end

% Create structures to store data by genotype
wakeData = struct('wild_type', [], 'mutant', []);
nremData = struct('wild_type', [], 'mutant', []);
remData = struct('wild_type', [], 'mutant', []);

% Create structure to store per-mouse averages by genotype
perMouseAvg = struct('wild_type', struct('wake', [], 'nrem', [], 'rem', []), ...
                     'mutant', struct('wake', [], 'nrem', [], 'rem', []));

% Define frequency range using linspace for precise control
% This guarantees exactly 159 points from 0.5 to 40 Hz
freqPoints = 159;
freqStart = 0.5;
freqEnd = 40;
freqRange = linspace(freqStart, freqEnd, freqPoints);

% Define data extraction rows based on the frequency range length
dataStartRow = 4;
dataEndRow = dataStartRow + length(freqRange) - 1; % Should be 162
spectralRows = dataStartRow:dataEndRow;

% Double-check that everything matches
fprintf('Frequency range has %d points from %.1f to %.1f Hz\n', ...
    length(freqRange), freqRange(1), freqRange(end));
fprintf('Data extraction rows: %d to %d (%d rows)\n', ...
    dataStartRow, dataEndRow, length(spectralRows));

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
    
    % Process each XLS file for this mouse
    for j = 1:length(xlsFiles)
        xlsPath = fullfile(xlsFiles(j).folder, xlsFiles(j).name);
        fprintf('  Processing file: %s\n', xlsFiles(j).name);
            
        try
            % Read spectral data (sheet 2)
            % Read data by column position instead of column names
            % Use readmatrix for direct column access:
            % Column C (3) = wake-p1, Column E (5) = NREM-p1, Column G (7) = REM-p1
            spectralData = readmatrix(xlsPath, 'Sheet', 2);
            
            % Check if the data has enough columns
            if size(spectralData, 2) >= 7
                % Extract the relative power data by column indices
                
                % For wake, NREM, and REM relative power data
                wake_rel_power_raw = spectralData(spectralRows, 3);
                nrem_rel_power_raw = spectralData(spectralRows, 5);
                rem_rel_power_raw = spectralData(spectralRows, 7);
                
                % Check if these arrays contain NaN values at the end
                if isnan(wake_rel_power_raw(end)) || isnan(nrem_rel_power_raw(end)) || isnan(rem_rel_power_raw(end))
                    fprintf('    Note: NaN values found at the end of power data in file %s\n', xlsFiles(j).name);
                    
                    % Find the last valid index in each array
                    lastValidWake = find(~isnan(wake_rel_power_raw), 1, 'last');
                    lastValidNREM = find(~isnan(nrem_rel_power_raw), 1, 'last');
                    lastValidREM = find(~isnan(rem_rel_power_raw), 1, 'last');
                    
                    % Use the minimum valid index as a safe point for all arrays
                    lastValid = min([lastValidWake, lastValidNREM, lastValidREM]);
                    
                    % If we have fewer valid points than expected, extrapolate the last value
                    if lastValid < length(freqRange)
                        fprintf('    Extrapolating data for last %d frequency points\n', length(freqRange) - lastValid);
                        
                        wake_rel_power = zeros(1, length(freqRange));
                        nrem_rel_power = zeros(1, length(freqRange));
                        rem_rel_power = zeros(1, length(freqRange));
                        
                        % Copy all valid data
                        wake_rel_power(1:lastValid) = wake_rel_power_raw(1:lastValid);
                        nrem_rel_power(1:lastValid) = nrem_rel_power_raw(1:lastValid);
                        rem_rel_power(1:lastValid) = rem_rel_power_raw(1:lastValid);
                        
                        % Extrapolate the remaining points using the last valid value
                        wake_rel_power(lastValid+1:end) = wake_rel_power_raw(lastValid);
                        nrem_rel_power(lastValid+1:end) = nrem_rel_power_raw(lastValid);
                        rem_rel_power(lastValid+1:end) = rem_rel_power_raw(lastValid);
                    else
                        % Just use the data as is, ensuring correct length
                        wake_rel_power = wake_rel_power_raw(1:length(freqRange));
                        nrem_rel_power = nrem_rel_power_raw(1:length(freqRange));
                        rem_rel_power = rem_rel_power_raw(1:length(freqRange));
                    end
                else
                    % No NaN values, just ensure correct length
                    wake_rel_power = wake_rel_power_raw(1:length(freqRange));
                    nrem_rel_power = nrem_rel_power_raw(1:length(freqRange));
                    rem_rel_power = rem_rel_power_raw(1:length(freqRange));
                end
                
                % Ensure vectors are row vectors for consistent concatenation
                if size(wake_rel_power, 1) > size(wake_rel_power, 2)
                    wake_rel_power = wake_rel_power';
                end
                if size(nrem_rel_power, 1) > size(nrem_rel_power, 2)
                    nrem_rel_power = nrem_rel_power';
                end
                if size(rem_rel_power, 1) > size(rem_rel_power, 2)
                    rem_rel_power = rem_rel_power';
                end
                
                % Append to the data arrays
                wakeData.(mouseGenotype) = [wakeData.(mouseGenotype); wake_rel_power];
                nremData.(mouseGenotype) = [nremData.(mouseGenotype); nrem_rel_power];
                remData.(mouseGenotype) = [remData.(mouseGenotype); rem_rel_power];
            else
                fprintf('    Warning: File %s does not have enough columns.\n', xlsFiles(j).name);
            end     
        catch e
            fprintf('    Error processing file %s: %s\n', xlsFiles(j).name, e.message);
            continue;
        end
    end

    % Average the relative power per mouse (across all XLS files)
    avgWakePower = mean(wakeData.(mouseGenotype), 1);
    avgNremPower = mean(nremData.(mouseGenotype), 1);
    avgRemPower  = mean(remData.(mouseGenotype), 1);
    
    % Store in a new structure for averaging by genotype later
    perMouseAvg.(mouseGenotype).wake = [perMouseAvg.(mouseGenotype).wake; avgWakePower];
    perMouseAvg.(mouseGenotype).nrem = [perMouseAvg.(mouseGenotype).nrem; avgNremPower];
    perMouseAvg.(mouseGenotype).rem  = [perMouseAvg.(mouseGenotype).rem;  avgRemPower];

    % Store animal ID
    if ~isfield(perMouseAvg.(mouseGenotype), 'animalIDs')
        perMouseAvg.(mouseGenotype).animalIDs = {};
    end
    perMouseAvg.(mouseGenotype).animalIDs{end+1} = currentMouseID;
end

%% Add diagnostic output to help understand the data
fprintf('\nDiagnostic information before calculating statistics:\n');
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    if isfield(perMouseAvg, gen)
        fprintf('  %s mouse count: %d\n', gen, size(perMouseAvg.(gen).wake, 1));
        if ~isempty(perMouseAvg.(gen).wake)
            fprintf('  %s wake data dimensions: %dx%d\n', gen, size(perMouseAvg.(gen).wake, 1), size(perMouseAvg.(gen).wake, 2));
            fprintf('  %s wake data last column values: ', gen);
            fprintf('%.5f ', perMouseAvg.(gen).wake(:, end));
            fprintf('\n');
        end
    end
end

%% Calculate statistics by genotype
% Initialize structures for mean and confidence interval values
wakeMean = struct('wild_type', [], 'mutant', []);
wakeCI = struct('wild_type', [], 'mutant', []);
nremMean = struct('wild_type', [], 'mutant', []);
nremCI = struct('wild_type', [], 'mutant', []);
remMean = struct('wild_type', [], 'mutant', []);
remCI = struct('wild_type', [], 'mutant', []);

% Calculate mean and 95% confidence interval for each state and genotype
for i = 1:length(genotypes)
    genotype = strrep(genotypes{i}, '-', '_');
    
    % Wake state
    if isfield(perMouseAvg, genotype) && ~isempty(perMouseAvg.(genotype).wake)
        % Get number of animals
        n = size(perMouseAvg.(genotype).wake, 1);
        
        % Calculate mean
        wakeMean.(genotype) = mean(perMouseAvg.(genotype).wake, 1);
        
        % Calculate standard error of the mean
        sem = std(perMouseAvg.(genotype).wake, 0, 1) / sqrt(n);
        
        % Calculate 95% confidence interval (using t-distribution)
        % For small sample sizes, t-distribution is more appropriate than normal distribution
        tCritical = tinv(0.975, n-1);  % 95% CI (two-tailed)
        wakeCI.(genotype) = tCritical * sem;
    else
        fprintf('No averaged wake data found for genotype: %s\n', genotype);
    end
    
    % NREM state
    if isfield(perMouseAvg, genotype) && ~isempty(perMouseAvg.(genotype).nrem)
        % Get number of animals
        n = size(perMouseAvg.(genotype).nrem, 1);
        
        % Calculate mean
        nremMean.(genotype) = mean(perMouseAvg.(genotype).nrem, 1);
        
        % Calculate standard error of the mean
        sem = std(perMouseAvg.(genotype).nrem, 0, 1) / sqrt(n);
        
        % Calculate 95% confidence interval
        tCritical = tinv(0.975, n-1);
        nremCI.(genotype) = tCritical * sem;
    else
        fprintf('No averaged NREM data found for genotype: %s\n', genotype);
    end
    
    % REM state
    if isfield(perMouseAvg, genotype) && ~isempty(perMouseAvg.(genotype).rem)
        % Get number of animals
        n = size(perMouseAvg.(genotype).rem, 1);
        
        % Calculate mean
        remMean.(genotype) = mean(perMouseAvg.(genotype).rem, 1);
        
        % Calculate standard error of the mean
        sem = std(perMouseAvg.(genotype).rem, 0, 1) / sqrt(n);
        
        % Calculate 95% confidence interval
        tCritical = tinv(0.975, n-1);
        remCI.(genotype) = tCritical * sem;
    else
        fprintf('No averaged REM data found for genotype: %s\n', genotype);
    end
end

%% Export statistics to Excel with separate sheets
fprintf('Preparing data for Excel export...\n');

% Create frequency data for both tables
freqs = freqRange';  % Transpose to column vector for table

% 1. Create table for individual mouse data
mouseDataTable = table(freqs, 'VariableNames', {'F_Hz'});

fprintf('Preparing individual mouse data sheet...\n');
% Add columns for each individual mouse
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    
    % Check if we have any data for this genotype
    if isfield(perMouseAvg, gen) && isfield(perMouseAvg.(gen), 'animalIDs') && ~isempty(perMouseAvg.(gen).animalIDs)
        % For each mouse in this genotype
        for m = 1:length(perMouseAvg.(gen).animalIDs)
            mouseID = perMouseAvg.(gen).animalIDs{m};
            fprintf('  Adding spectral data for mouse: %s\n', mouseID);
            
            % Add the individual mouse data
            if size(perMouseAvg.(gen).wake, 1) >= m
                mouseDataTable.([mouseID '_wakeMean']) = perMouseAvg.(gen).wake(m,:)';
            end
            
            if size(perMouseAvg.(gen).nrem, 1) >= m
                mouseDataTable.([mouseID '_nremMean']) = perMouseAvg.(gen).nrem(m,:)';
            end
            
            if size(perMouseAvg.(gen).rem, 1) >= m
                mouseDataTable.([mouseID '_remMean']) = perMouseAvg.(gen).rem(m,:)';
            end
        end
    end
end

% 2. Create table for genotype statistics
genotypeStatsTable = table(freqs, 'VariableNames', {'F_Hz'});

fprintf('Preparing genotype statistics sheet...\n');
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    display_name = strrep(gen, '_', '-'); % Convert 'wild_type' to 'wild-type'
    
    if isfield(wakeMean, gen) && ~isempty(wakeMean.(gen))
        genotypeStatsTable.([display_name '_wakeMean']) = wakeMean.(gen)';
        genotypeStatsTable.([display_name '_wake95CI']) = wakeCI.(gen)';
    end
    
    if isfield(nremMean, gen) && ~isempty(nremMean.(gen))
        genotypeStatsTable.([display_name '_nremMean']) = nremMean.(gen)';
        genotypeStatsTable.([display_name '_nrem95CI']) = nremCI.(gen)';
    end
    
    if isfield(remMean, gen) && ~isempty(remMean.(gen))
        genotypeStatsTable.([display_name '_remMean']) = remMean.(gen)';
        genotypeStatsTable.([display_name '_rem95CI']) = remCI.(gen)';
    end
end

% 3. Create a summary table mapping mice to genotypes
mouseGenotypeSummary = table();
allAnimalIDs = [];
genotypes_list = [];

for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    if isfield(perMouseAvg, gen) && isfield(perMouseAvg.(gen), 'animalIDs') && ~isempty(perMouseAvg.(gen).animalIDs)
        allAnimalIDs = [allAnimalIDs; perMouseAvg.(gen).animalIDs(:)];
        genotypes_list = [genotypes_list; repmat({strrep(gen, '_', '-')}, length(perMouseAvg.(gen).animalIDs), 1)];
    end
end

% If we have any mouse IDs, add them to the summary
if ~isempty(allAnimalIDs)
    mouseGenotypeSummary.MouseID = allAnimalIDs;
    mouseGenotypeSummary.Genotype = genotypes_list;
end

% Check for any NaN values in the tables before writing to Excel
function checkNaNValues(T, tableName)
    nanCheck = false;
    varNames = T.Properties.VariableNames;
    for i = 1:length(varNames)
        if any(isnan(T.(varNames{i})))
            fprintf('WARNING: Found NaN values in column %s of %s\n', varNames{i}, tableName);
            nanCheck = true;
        end
    end
    if ~nanCheck
        fprintf('No NaN values found in %s. The data should be clean.\n', tableName);
    end
end

checkNaNValues(mouseDataTable, 'mouse data table');
checkNaNValues(genotypeStatsTable, 'genotype statistics table');

% 4. Write all tables to different sheets in the Excel file
xlsFilePath = fullfile(mainFolder, 'spectral_power_analysis.xlsx');
fprintf('Writing data to Excel file: %s\n', xlsFilePath);

% Write to Excel file - different sheets
writetable(mouseDataTable, xlsFilePath, 'Sheet', 'Individual_Mouse_Data');
writetable(genotypeStatsTable, xlsFilePath, 'Sheet', 'Genotype_Statistics');
if ~isempty(allAnimalIDs)
    writetable(mouseGenotypeSummary, xlsFilePath, 'Sheet', 'Mouse_Genotypes');
end

% 5. Add metadata as a text file
metadataFile = fullfile(mainFolder, 'spectral_analysis_metadata.txt');
fid = fopen(metadataFile, 'w');
fprintf(fid, 'Spectral Analysis Metadata\n');
fprintf(fid, '------------------------\n\n');
fprintf(fid, 'Analysis Date: %s\n\n', datestr(now));
fprintf(fid, 'Frequency Range: %.1f to %.1f Hz (%d points)\n\n', freqStart, freqEnd, freqPoints);

fprintf(fid, 'Mouse Information:\n');
for genotype = {'wild_type', 'mutant'}
    gen = genotype{1};
    display_name = strrep(gen, '_', '-');
    
    if isfield(perMouseAvg, gen) && isfield(perMouseAvg.(gen), 'animalIDs') && ~isempty(perMouseAvg.(gen).animalIDs)
        fprintf(fid, '%s: %d mice\n', display_name, length(perMouseAvg.(gen).animalIDs));
        fprintf(fid, '%s IDs: %s\n', display_name, strjoin(perMouseAvg.(gen).animalIDs, ', '));
    end
end
fclose(fid);

fprintf('Exported statistics to Excel: %s\n', xlsFilePath);
fprintf('Metadata written to: %s\n', metadataFile);

%% Create figures for each state
% Colors for plotting
wtColor = [0, 0, 0.8]; % Blue for wild-type
mutColor = [0.8, 0, 0]; % Red for mutant

% WAKE state plot
figure('Name', 'Wake Relative Power', 'Position', [100, 100, 800, 500]);
hold on;

% Plot wild-type data with 95% CI region
if ~isempty(wakeMean.wild_type)
    % Main line
    plot(freqRange, wakeMean.wild_type, 'Color', wtColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = wakeMean.wild_type + wakeCI.wild_type;
    lowerBound = wakeMean.wild_type - wakeCI.wild_type;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h1 = fill(x2, y2, wtColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

% Plot mutant data with 95% CI region
if ~isempty(wakeMean.mutant)
    % Main line
    plot(freqRange, wakeMean.mutant, 'Color', mutColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = wakeMean.mutant + wakeCI.mutant;
    lowerBound = wakeMean.mutant - wakeCI.mutant;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h2 = fill(x2, y2, mutColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

title('Wake Relative Power Spectrum');
xlabel('Frequency (Hz)');
ylabel('Relative Power');
legend('Wild-type', 'Wild-type 95% CI', 'Mutant', 'Mutant 95% CI');
xlim([freqStart, freqEnd]);
grid on;
hold off;

% NREM state plot
figure('Name', 'NREM Relative Power', 'Position', [100, 100, 800, 500]);
hold on;

% Plot wild-type data with 95% CI region
if ~isempty(nremMean.wild_type)
    % Main line
    plot(freqRange, nremMean.wild_type, 'Color', wtColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = nremMean.wild_type + nremCI.wild_type;
    lowerBound = nremMean.wild_type - nremCI.wild_type;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h1 = fill(x2, y2, wtColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

% Plot mutant data with 95% CI region
if ~isempty(nremMean.mutant)
    % Main line
    plot(freqRange, nremMean.mutant, 'Color', mutColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = nremMean.mutant + nremCI.mutant;
    lowerBound = nremMean.mutant - nremCI.mutant;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h2 = fill(x2, y2, mutColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

title('NREM Relative Power Spectrum');
xlabel('Frequency (Hz)');
ylabel('Relative Power');
legend('Wild-type', 'Wild-type 95% CI', 'Mutant', 'Mutant 95% CI');
xlim([freqStart, freqEnd]);
grid on;
hold off;

% REM state plot
figure('Name', 'REM Relative Power', 'Position', [100, 100, 800, 500]);
hold on;

% Plot wild-type data with 95% CI region
if ~isempty(remMean.wild_type)
    % Main line
    plot(freqRange, remMean.wild_type, 'Color', wtColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = remMean.wild_type + remCI.wild_type;
    lowerBound = remMean.wild_type - remCI.wild_type;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h1 = fill(x2, y2, wtColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

% Plot mutant data with 95% CI region
if ~isempty(remMean.mutant)
    % Main line
    plot(freqRange, remMean.mutant, 'Color', mutColor, 'LineWidth', 2);
    
    % Add 95% CI region (shaded area)
    upperBound = remMean.mutant + remCI.mutant;
    lowerBound = remMean.mutant - remCI.mutant;
    x2 = [freqRange, fliplr(freqRange)];
    y2 = [upperBound, fliplr(lowerBound)];
    h2 = fill(x2, y2, mutColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

title('REM Relative Power Spectrum');
xlabel('Frequency (Hz)');
ylabel('Relative Power');
legend('Wild-type', 'Wild-type 95% CI', 'Mutant', 'Mutant 95% CI');
xlim([freqStart, freqEnd]);
grid on;
hold off;

%% Save figures to the compiled_plots folder
saveas(1, fullfile(outputFolder, 'Wake_Relative_Power.fig'));
saveas(1, fullfile(outputFolder, 'Wake_Relative_Power.png'));
saveas(2, fullfile(outputFolder, 'NREM_Relative_Power.fig'));
saveas(2, fullfile(outputFolder, 'NREM_Relative_Power.png'));
saveas(3, fullfile(outputFolder, 'REM_Relative_Power.fig'));
saveas(3, fullfile(outputFolder, 'REM_Relative_Power.png'));

fprintf('Plots saved to %s\n', outputFolder);