
% This local function performs the extraction and file writing
function export_data(data_struct, hbo_idx, hbr_idx, hbt_idx, prefix)
    
    % Extract the relevant matrices
    % HRF Time Series Data
    time_series = data_struct.output.dcAvg.dataTimeSeries;
    % Standard Deviation Data (for plotting error bars in Python)
    time_std = data_struct.output.dcAvgStd.dataTimeSeries;
    
    % --- Prepare and Export Data for HbO, HbR, HbT ---
    
    % Data to process: a cell array of {data_indices, name_suffix}
    data_list = {
        {hbo_idx, 'hbo'};
        {hbr_idx, 'hbr'};
        {hbt_idx, 'hbt'};
    };

    
    for k = 1:length(data_list)
        idx = data_list{k}{1};
        suffix = data_list{k}{2};
        
        if isempty(idx)
            disp(['Skipping export for ', suffix, ' as no channels were found.']);
            continue;
        end

        % Extract the time series and std data for the current species
        data_ts = time_series(:, idx);
        data_std = time_std(:, idx);
        
        % Combine Time Series (TS) and Standard Deviation (STD) columns
        combined_data = [data_ts, data_std]; 
        
        % --- Create Column Headers (same as before) ---
        N_channels = length(idx); 
        ts_headers = arrayfun(@(i) ['ts_ch', num2str(i)], 1:N_channels, 'UniformOutput', false);
        std_headers = arrayfun(@(i) ['std_ch', num2str(i)], 1:N_channels, 'UniformOutput', false);
        header_names = [ts_headers, std_headers];
        header_line = strjoin(header_names, ',');
        
        % --- Export Data using FOPEN/FPRINTF (Backward-Compatible) ---
        filename = [prefix, '_hrf_', suffix, '.csv'];
        
        disp(['Writing ', filename, '...']);
        
        % 1. Open the file for writing ('w')
        fid = fopen(filename, 'w');
        if fid == -1
            error('Could not open file for writing: %s', filename);
        end
        
        % 2. Write the Header Line followed by a newline character
        fprintf(fid, '%s\n', header_line);
        
        % 3. Write the Numeric Data, row by row
        % Use '%s' format to specify a comma-separated format for each row
        formatSpec = [repmat('%.6f,', 1, size(combined_data, 2) - 1), '%.6f\n'];
        
        for row = 1:size(combined_data, 1)
            fprintf(fid, formatSpec, combined_data(row, :));
        end
        
        % 4. Close the file
        fclose(fid);
    end
    
    disp(['? Export complete for ', prefix, ' data structure.']);
end
