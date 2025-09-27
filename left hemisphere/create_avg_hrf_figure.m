% Load Before. mat
before = load('C:\nirs\beetroot\left hemisphere\derivatives\homer\before\before.mat')

% Load After.mat
after = load('C:\nirs\beetroot\left hemisphere\derivatives\homer\after\after.mat')

%Go into file.output, into output.dcAvg has the HRF timeseries data
%output.dcAvgStd has the standard deviations, useful for plotting

%dcAvg.dataTimeSeries is a [timepoints x (3x channels)] array, one channel
%per wavelength (HbO, HbR, and HbT)
%dcAvg.measurementList is an array of structs containging the infromation
%for each channel such as what source and detector and what wavelengvth it
%is

%I want to get the HRF channel data sepearted into HbO, HbR and HbT, 
% and export it to a csv such that i can continue analysis in Python
% isntead 

% Initialize arrays to store channel indices
hbo_indices = [];
hbr_indices = [];
hbt_indices = [];

% Iterate through the measurementList to classify channels
for i = 1:nChannels
    label = ml(i).dataTypeLabel;
    
    if contains(label, 'HRF HbO', 'IgnoreCase', true)
        % This identifies Oxy-hemoglobin (HbO)
        hbo_indices(end+1) = i;
    elseif contains(label, 'HRF HbR', 'IgnoreCase', true)
        % This identifies Deoxy-hemoglobin (HbR)
        hbr_indices(end+1) = i;
    elseif contains(label, 'HRF HbT', 'IgnoreCase', true)
        % This identifies Total-hemoglobin (HbT)
        hbt_indices(end+1) = i;
    end
end


% Check if indices were found (good practice)
if isempty(hbo_indices) || isempty(hbr_indices) || isempty(hbt_indices)
    warning('One or more hemoglobin species indices were not found. Check dataTypeLabel values.');
end


% The files will be saved in your current MATLAB working directory.
export_data(before, hbo_indices, hbr_indices, hbt_indices, 'before');
export_data(after, hbo_indices, hbr_indices, hbt_indices, 'after');
