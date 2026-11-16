
%% Interpolate flux maps and footprint weights to four raster resolutions
% Uses existing model outputs and saved raster grids.
% Does NOT rerun the footprint model.
%
% Outputs paired flux and footprint-weight CSV files for:
%   CH4 BOTH: 12 cm, 3 m, 10 m, 30 m
%   CO2 DAY:  12 cm, 3 m, 10 m, 30 m
%   CO2 NIGHT:12 cm, 3 m, 10 m, 30 m

clear;
clc;

%% 1. Folders
BaseDir = ...
    'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\continuous\';

MatrixDir = ...
    'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\matrices\';

if ~isfolder(BaseDir)
    error('Continuous folder not found: %s', BaseDir);
end

if ~isfolder(MatrixDir)
    error('Matrices folder not found: %s', MatrixDir);
end

%% 2. Define the three comparisons
% Each entry specifies the processed flux map, field, and weight file.

Cases = struct( ...
    'label', {'CH4_BOTH', 'CO2_DAY', 'CO2_NIGHT'}, ...
    'sourceFile', { ...
        'SurfFluxMaps_MWR-KM-2024193-0000-to-2024274-0000-both-50-80MZA.mat.mat', ...
        'SurfFluxMaps_MWR-KM-2024193-0000-to-2024274-0000-day-50-80MZA.mat.mat', ...
        'SurfFluxMaps_MWR-KM-2024193-0000-to-2024274-0000-night-50-80MZA.mat.mat'}, ...
    'fluxField', {'CH4_mat', 'CO2_mat', 'CO2_mat'}, ...
    'weightFile', { ...
        'FootWeights_both_CH4.mat', ...
        'FootWeights_day_CO2.mat', ...
        'FootWeights_night_CO2.mat'});

%% 3. Define the four saved target grids
GridFiles = { ...
    'MWR_map.mat', ...
    'MWR_map_3m.mat', ...
    'MWR_map_10m.mat', ...
    'MWR_map_30m.mat'};

GridLabels = {'12cm', '3m', '10m', '30m'};

%% 4. Process each comparison
for k = 1:numel(Cases)

    fprintf('\n========================================\n');
    fprintf('Processing %s\n', Cases(k).label);
    fprintf('========================================\n');

    FluxPath = fullfile(BaseDir, Cases(k).sourceFile);
    WeightPath = fullfile(BaseDir, Cases(k).weightFile);

    if ~isfile(FluxPath)
        error('Flux map file not found: %s', FluxPath);
    end

    if ~isfile(WeightPath)
        error('Weight file not found: %s', WeightPath);
    end

    % Load only the required variables from the processed flux map.
    F = load(FluxPath, Cases(k).fluxField, 'FX', 'FY');
    flux = F.(Cases(k).fluxField);
    FX = F.FX;
    FY = F.FY;
    clear F;

    % Load the corresponding footprint weights and coordinates.
    W = load(WeightPath, 'weight', 'FX', 'FY');

    % Correct the sign convention of the extracted weight Y coordinates.
    % The weight matrix row order is unchanged.
    W.FY = -W.FY;

    % Confirm that the weights and flux map use the same source grid.
    if ~isequal(size(flux), size(W.weight)) || ...
       ~isequal(size(flux), [numel(FY), numel(FX)]) || ...
       ~isequal(FX(:), W.FX(:)) || ~isequal(FY(:), W.FY(:))

        error(['Source grid mismatch for %s. ' ...
               'Check flux-map and weight-file coordinates.'], ...
               Cases(k).label);
    end

    % Source coordinates for interpolation.
    [SourceX, SourceY] = meshgrid(FX, FY);

    for g = 1:numel(GridFiles)

        GridPath = fullfile(BaseDir, GridFiles{g});

        if ~isfile(GridPath)
            error('Target grid not found: %s', GridPath);
        end

        G = load(GridPath, 'FX_MWR', 'FY_MWR');

        TargetFX = G.FX_MWR;
        TargetFY = G.FY_MWR;
        [TargetX, TargetY] = meshgrid(TargetFX, TargetFY);

        fprintf('\n  Target resolution: %s\n', GridLabels{g});

        % Interpolate flux and weights onto the same target coordinates.
        fluxTarget = interp2( ...
            SourceX, SourceY, double(flux), ...
            TargetX, TargetY, 'linear');

        weightTarget = interp2( ...
            SourceX, SourceY, double(W.weight), ...
            TargetX, TargetY, 'linear');

        % Use the same valid cells for flux and weight.
        valid = isfinite(fluxTarget) & ...
                isfinite(weightTarget) & ...
                weightTarget >= 0;

        fluxTarget(~valid) = NaN;
        weightTarget(~valid) = NaN;

        % Save CSVs; -9999 represents missing data.
        fluxOut = fluxTarget;
        weightOut = weightTarget;

        fluxOut(~isfinite(fluxOut)) = -9999;
        weightOut(~isfinite(weightOut)) = -9999;

        fluxName = sprintf('%s_%s_flux.csv', ...
            Cases(k).label, GridLabels{g});

        weightName = sprintf('%s_%s_weight.csv', ...
            Cases(k).label, GridLabels{g});

        writematrix(fluxOut, fullfile(MatrixDir, fluxName));
        writematrix(weightOut, fullfile(MatrixDir, weightName));

        fprintf('    Valid cells: %d\n', nnz(valid));
        fprintf('    Saved: %s\n', fluxName);
        fprintf('    Saved: %s\n', weightName);

        clear G TargetX TargetY TargetFX TargetFY
        clear fluxTarget weightTarget fluxOut weightOut valid
    end

    clear flux FX FY W SourceX SourceY
end

fprintf('\nAll flux and footprint-weight CSV files have been created.\n');
fprintf('Output folder: %s\n', MatrixDir);
