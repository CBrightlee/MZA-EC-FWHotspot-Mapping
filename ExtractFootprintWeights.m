
%% Extract the footprint weights needed for semivariogram analysis
% Uses existing model outputs; does NOT rerun the footprint model.

clear;
clc;

DataDir = 'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\continuous\';
cd(DataDir);

FileList = {
    'MWR-KM-2024193-0000-to-2024274-0000-both-50-80MZA.mat'
    'MWR-KM-2024193-0000-to-2024274-0000-day-50-80MZA.mat'
    'MWR-KM-2024193-0000-to-2024274-0000-night-50-80MZA.mat'
};

OutputList = {
    'FootWeights_both_CH4.mat'
    'FootWeights_day_CO2.mat'
    'FootWeights_night_CO2.mat'
};

WeightField = {'footWeightS0', 'footWeight', 'footWeight'};

for k = 1:numel(FileList)

    fprintf('\nLoading %s\n', FileList{k});

    S = load(FileList{k}, 'COMP', 'FX', 'FY');

    % COMP(3) is the K&M model used in your workflow
    FX = S.FX;
    FY = S.FY;
    weight = S.COMP(3).(WeightField{k});

    % Check that the weight grid matches the coordinates
    if size(weight,1) ~= numel(FY) || ...
       size(weight,2) ~= numel(FX)
        error('Weight dimensions do not match FX and FY.');
    end

    % Save only the required weight grid and coordinates
    save(OutputList{k}, 'weight', 'FX', 'FY', '-v7.3');

    fprintf('Saved %s (%d rows x %d columns)\n', ...
        OutputList{k}, size(weight,1), size(weight,2));

    clear S weight FX FY;
end

fprintf('\nFinished extracting footprint weights.\n');
