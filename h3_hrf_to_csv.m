function h3_hrf_to_csv(data_struct, prefix, output_dir)
% EXPORT_HRF_TO_CSV Processes a Homer3 data structure and exports HRF time
% series and standard deviation data, separating by stimuli condition.
%
% Args:
%   data_struct (struct): The loaded Homer3 data structure.
%   prefix (char): A prefix for the output files (e.g., 'before').
%   output_dir (char): The destination directory for the CSV files.

% Ensure the output directory exists
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    disp(['Created output directory: ', output_dir]);
end

% --- 1. Identify Unique Stimuli Conditions and Channel Indices ---
ml = data_struct.output.dcAvg.measurementList;
nChannels = length(ml);

% Get all unique dataTypeIndex values (i.e., the unique stimuli conditions)
all_stim_indices = [ml.dataTypeIndex];
unique_stim_indices = unique(all_stim_indices);

% Initialize a cell array to store the full list of export tasks
export_tasks = {};
task_counter = 1;

hemoglobin_types = {'HbO', 'HbR', 'HbT'};

for s_idx = 1:length(unique_stim_indices)
    stim_index = unique_stim_indices(s_idx);
    
    for h_idx = 1:length(hemoglobin_types)
        hb_type = hemoglobin_types{h_idx};
        
        % Build a logical mask to find channels matching both criteria
        current_indices = [];
        for i = 1:nChannels
            label = ml(i).dataTypeLabel;
            
            % Check both hemoglobin type and stimuli index
            if contains(label, ['HRF ', hb_type], 'IgnoreCase', true) && ml(i).dataTypeIndex == stim_index
                current_indices(end+1) = i;
            end
        end
        
        % If channels were found for this combination, create an export task
        if ~isempty(current_indices)
            % Determine the suffix for the filename
            % Example: stim1_hbo or stim2_hbr
            suffix = ['stim', num2str(stim_index), '_', lower(hb_type)];
            
            export_tasks{task_counter} = {current_indices, suffix};
            task_counter = task_counter + 1;
        end
    end
end

if isempty(export_tasks)
    warning('No HRF channels found matching any stimuli index and hemoglobin type.');
    return;
end

% --- 2. Extract Data and Export for each Task ---

% Extract the relevant matrices once
time_series = data_struct.output.dcAvg.dataTimeSeries;
time_std = data_struct.output.dcAvgStd.dataTimeSeries;

for k = 1:length(export_tasks)
    idx = export_tasks{k}{1};
    suffix = export_tasks{k}{2}; % e.g., 'stim1_hbo'
    % Extract the time series and std data for the current species/stimuli
    data_ts = time_series(:, idx);
    data_std = time_std(:, idx);
    
    % Combine Time Series (TS) and Standard Deviation (STD) columns
    combined_data = [data_ts, data_std];
    % ====================================
    % --- Determine Hemoglobin Type from Suffix ---
    % Get the last part of the suffix (e.g., 'hbo')
    parts = strsplit(suffix, '_');
    hb_type_code = parts{end}; % e.g., 'hbo', 'hbr', or 'hbt'
    
    % Define the species-specific output directory
    species_output_dir = fullfile(output_dir, hb_type_code); 
    
    % --- Create Species Folder ---
    if ~exist(species_output_dir, 'dir')
        mkdir(species_output_dir);
        disp(['Created species directory: ', species_output_dir]);
    end
    
    % ... (Data extraction and header creation remains the same) ...
    % --- Create Column Headers ---
    N_channels = length(idx);
    ts_headers = arrayfun(@(i) ['ts_ch', num2str(i)], 1:N_channels, 'UniformOutput', false);
    std_headers = arrayfun(@(i) ['std_ch', num2str(i)], 1:N_channels, 'UniformOutput', false);
    header_names = [ts_headers, std_headers];
    header_line = strjoin(header_names, ','); % <-- 'header_line' is defined here
    
    % --- Export Data using FOPEN/FPRINTF ---
    filename = [prefix, '_hrf_', suffix, '.csv'];
    % Crucial change: Use species_output_dir instead of output_dir
    full_path = fullfile(species_output_dir, filename); 
    
    disp(['Writing ', filename, ' to ', species_output_dir, '...']);
    
    % 1. Open the file for writing ('w')
    fid = fopen(full_path, 'w');
    if fid == -1
        error('Could not open file for writing: %s. Check permissions.', full_path);
    end
    
    % 2. Write the Header Line followed by a newline character
    fprintf(fid, '%s\n', header_line);
    
    % 3. Write the Numeric Data, row by row
    formatSpec = [repmat('%.6f,', 1, size(combined_data, 2) - 1), '%.6f\n'];
    for row = 1:size(combined_data, 1)
        fprintf(fid, formatSpec, combined_data(row, :));
    end
    
    % 4. Close the file
    fclose(fid);
end

disp(['Export complete for ', prefix, ' data structure.']);

end