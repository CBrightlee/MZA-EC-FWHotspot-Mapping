%% Uniform Map Scaling & Spatial Grid Interpolation (UniformMapScaling.m)
% Written by Tim Morin (5/9/2025)
% Last updated by Christian Bright (10/22/2026)
% Linearly interpolates spatial layers (flux maps, DEM, land cover, canopy height)
% onto a common reference grid (orthoimagery coordinate framework) for direct comparison.

clear; clc;

%% User-Configurable Paths (Update to match your local directory structure)
input_dir  = './Footprint_Output/continuous/';
output_dir = './Footprint_Output/matrices/';

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Select Map Layers to Process
% j = 1: Surface flux maps (CH4, CO2, H2O)
% j = 2: Digital Elevation Model (DEM)
% j = 3: Supervised land cover classification map
% j = 4: Canopy height map
jj = [1, 2, 3, 4];

% Flux-weighted footprint map filenames (without 'SurfFluxMaps_' prefix or '.mat')
FileList = {
    'MWR-KM-2024193-0000-to-2024274-0000-both-50-80MZA.mat', ...
    'MWR-KM-2024193-0000-to-2024274-0000-day-50-80MZA.mat', ...
    'MWR-KM-2024193-0000-to-2024274-0000-night-50-80MZA.mat'
};

%% Load Base Reference Grid (Orthoimagery)
load(fullfile(input_dir, 'MWR_map.mat'));
orth.FX = FX_MWR;
orth.FY = FY_MWR;
[orth.FXX, orth.FYY] = meshgrid(orth.FX, orth.FY);

figure('Visible', 'on');
imagesc(orth.FX, orth.FY, MWR1);
axis image;
set(gca, 'YDir', 'normal');
xlabel('X (m)');
ylabel('Y (m)');
drawnow;

%% Interpolate Selected Layers onto Common Reference Grid
for j_ct = 1:length(jj)
    j = jj(j_ct);

    %% Option 1: Surface Flux Maps (CH4, CO2, H2O)
    if j == 1
        for k = 1:length(FileList)
            FileToLoad = FileList{k};
            load(fullfile(input_dir, ['SurfFluxMaps_' FileToLoad '.mat']));
            [FXX, FYY] = meshgrid(FX, FY);

            x = orth.FX;
            y = orth.FY;

            % --- Interpolate and Export CH4 Flux ---
            CH4_ortho = interp2(FXX, FYY, CH4_mat, orth.FXX, orth.FYY, 'linear');

            figure('Visible', 'on');
            h = imagesc(x, y, CH4_ortho);
            axis image;
            set(gca, 'YDir', 'normal');
            colormap(flipud(hot));
            set(h, 'AlphaData', ~isnan(CH4_ortho));
            xlabel('X (m)');
            ylabel('Y (m)');
            ax = gca;
            ax.FontSize = 11;

            cb = colorbar;
            cb.Label.String = 'CH_4 Flux (nmol m^{-2}s^{-1})';
            cb.Label.Interpreter = 'tex';
            cb.FontSize = 11;
            cb.Label.FontSize = 14;
            drawnow;

            CH4_ortho(isnan(CH4_ortho)) = -9999;
            writematrix(CH4_ortho, fullfile(output_dir, [FileToLoad '_CH4_ortho.csv']));

            % --- Interpolate and Export CO2 Flux ---
            CO2_ortho = interp2(FXX, FYY, CO2_mat, orth.FXX, orth.FYY, 'linear');

            figure('Visible', 'on');
            i = imagesc(x, y, CO2_ortho);
            axis image;
            set(gca, 'YDir', 'normal');
            colormap(flipud(hot));
            set(i, 'AlphaData', ~isnan(CO2_ortho));
            xlabel('X (m)');
            ylabel('Y (m)');
            ax = gca;
            ax.FontSize = 11;

            cb = colorbar;
            cb.Label.String = 'CO_2 Flux (umol m^{-2}s^{-1})';
            cb.Label.Interpreter = 'tex';
            cb.FontSize = 11;
            cb.Label.FontSize = 14;
            drawnow;

            CO2_ortho(isnan(CO2_ortho)) = -9999;
            writematrix(CO2_ortho, fullfile(output_dir, [FileToLoad '_CO2_ortho.csv']));

            % --- Interpolate and Export H2O Flux ---
            H2O_ortho = interp2(FXX, FYY, H2O_mat, orth.FXX, orth.FYY, 'linear');

            figure('Visible', 'on');
            r = imagesc(x, y, H2O_ortho);
            colormap(flipud(hot));
            set(r, 'AlphaData', ~isnan(H2O_ortho));
            xlabel('X (m)');
            ylabel('Y (m)');
            ax = gca;
            ax.FontSize = 11;

            cb = colorbar;
            cb.Label.String = 'H_2O Flux (nmol m^{-2}s^{-1})';
            cb.Label.Interpreter = 'tex';
            cb.FontSize = 11;
            cb.Label.FontSize = 14;
            drawnow;

            H2O_ortho(isnan(H2O_ortho)) = -9999;
            writematrix(H2O_ortho, fullfile(output_dir, [FileToLoad '_H2O_ortho.csv']));

            fprintf('Finished %d\n', k);
        end
    end

    %% Option 2: Digital Elevation Model (DEM)
    if j == 2
        load(fullfile(input_dir, 'MWR_DEM_map.mat'));
        [FXX, FYY] = meshgrid(FX_DEM, FY_DEM);

        DEM_scale = -9999 * ones(size(orth.FXX));
        inside = orth.FXX >= min(FX_DEM) & orth.FXX <= max(FX_DEM) & ...
                 orth.FYY >= min(FY_DEM) & orth.FYY <= max(FY_DEM);

        DEM_scale(inside) = interp2(FXX, FYY, DEM, orth.FXX(inside), orth.FYY(inside), 'linear');

        DEM_plot = DEM_scale;
        DEM_plot(DEM_plot == -9999) = NaN;

        writematrix(DEM_scale, fullfile(output_dir, 'DEM.csv'));

        x = orth.FX;
        y = orth.FY;
        figure('Visible', 'on');
        h = imagesc(x, y, DEM_plot);
        axis image;
        set(gca, 'YDir', 'normal');
        set(h, 'AlphaData', ~isnan(DEM_plot));
        set(gca, 'Color', [0 0 0]);
        colormap(gca, 'turbo');
        xlabel('X (m)');
        ylabel('Y (m)');
        ax = gca;
        ax.FontSize = 11;

        cb = colorbar;
        cb.Label.String = 'Elevation (m)';
        cb.FontSize = 11;
        cb.Label.FontSize = 14;
        drawnow;
    end

    %% Option 3: Supervised Land-Cover Classification Map
    if j == 3
        load(fullfile(input_dir, 'MWR_CLASS_map.mat'));
        [FXX, FYY] = meshgrid(FX_CLASS, FY_CLASS);

        Class_scale = -9999 * ones(size(orth.FXX));
        inside = orth.FXX >= min(FX_CLASS) & orth.FXX <= max(FX_CLASS) & ...
                 orth.FYY >= min(FY_CLASS) & orth.FYY <= max(FY_CLASS);

        Class_scale(inside) = interp2(FXX, FYY, Class_Map1, orth.FXX(inside), orth.FYY(inside), 'nearest');

        Class_plot = Class_scale;
        Class_plot(Class_plot == -9999) = NaN;

        for c = 1:7
            fprintf('Class %d: %d pixels\n', c, sum(Class_scale(:) == c));
        end

        writematrix(Class_scale, fullfile(output_dir, 'Class_Map.csv'));

        x = orth.FX;
        y = orth.FY;
        figure('Visible', 'on');
        imagesc(x, y, Class_plot);
        axis image;
        xlabel('X (m)');
        ylabel('Y (m)');
        set(gca, 'YDir', 'normal');
        colormap("turbo");
        ax = gca;
        ax.FontSize = 11;

        cb = colorbar;
        cb.Label.String = 'Land Cover Class';
        cb.FontSize = 11;
        cb.Label.FontSize = 14;
        drawnow;
    end

    %% Option 4: Canopy Height Map
    if j == 4
        load(fullfile(input_dir, 'MWR_Height_map.mat'));
        [FXX, FYY] = meshgrid(FX_Height, FY_Height);

        Height_scale = -9999 * ones(size(orth.FXX));
        inside = orth.FXX >= min(FX_Height) & orth.FXX <= max(FX_Height) & ...
                 orth.FYY >= min(FY_Height) & orth.FYY <= max(FY_Height);

        Height_scale(inside) = interp2(FXX, FYY, Height_Map, orth.FXX(inside), orth.FYY(inside), 'linear');

        Height_plot = Height_scale;
        Height_plot(Height_plot == -9999) = NaN;

        writematrix(Height_scale, fullfile(output_dir, 'Height_Map.csv'));

        x = orth.FX;
        y = orth.FY;
        figure('Visible', 'on');
        h = imagesc(x, y, Height_plot);
        axis image;
        set(gca, 'YDir', 'normal');
        set(h, 'AlphaData', ~isnan(Height_plot));
        set(gca, 'Color', [0 0 0]);
        colormap(gca, 'turbo');
        xlabel('X (m)');
        ylabel('Y (m)');
        ax = gca;
        ax.FontSize = 11;

        cb = colorbar;
        cb.Label.String = 'Plant Height (m)';
        cb.FontSize = 11;
        cb.Label.FontSize = 14;
        drawnow;
    end
end

%% Generate Publication 3-Panel Figure (DEM, Canopy Height, Land Cover)
x = orth.FX;
y = orth.FY;
figure('Visible', 'on', 'Units', 'inches', 'Position', [1, 1, 6.5, 9.5]);
t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

subplot_labels   = {'(a)', '(b)', '(c)'};
label_fontsize   = 11;
label_fontweight = 'bold';
label_color      = 'k';
normalized_X     = -0.15;
normalized_Y     = 1.05;

Axis_Font_Size  = 10;
Label_Font_Size = 11;
Cbar_Label_Size = 10;
Cbar_Tick_Size  = 9;

% --- Subplot (a): DEM Map ---
ax1 = nexttile;
h1 = imagesc(x, y, DEM_plot);
set(h1, 'AlphaData', ~isnan(DEM_plot));
ax1.Color = [0 0 0];
axis image;
set(ax1, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', Axis_Font_Size, 'LineWidth', 0.8);
ylabel('N/S Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', Label_Font_Size, 'FontWeight', 'normal');
ax1.XTickLabel = [];
colormap(ax1, "bone");

cb1 = colorbar;
set(cb1, 'FontName', 'Times New Roman', 'FontSize', Cbar_Tick_Size);
ylabel(cb1, 'Elevation (m)', 'FontName', 'Times New Roman', 'FontSize', Cbar_Label_Size);

text(ax1, normalized_X, normalized_Y, subplot_labels{1}, ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, 'FontWeight', label_fontweight, 'Color', label_color, ...
    'FontName', 'Times New Roman');

% --- Subplot (b): Canopy Height Map ---
ax2 = nexttile;
h2 = imagesc(x, y, Height_plot);
set(h2, 'AlphaData', ~isnan(Height_plot));
ax2.Color = [0 0 0];
axis image;
set(ax2, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', Axis_Font_Size, 'LineWidth', 0.8);
ylabel('N/S Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', Label_Font_Size, 'FontWeight', 'normal');
ax2.XTickLabel = [];
colormap(ax2, "turbo");

cb2 = colorbar;
clim(ax2, [0 3]);
cb2.Ticks = 0:1:3;
cb2.TickLabels = compose('%.2f', cb2.Ticks);
set(cb2, 'FontName', 'Times New Roman', 'FontSize', Cbar_Tick_Size);
ylabel(cb2, 'Height (m)', 'FontName', 'Times New Roman', 'FontSize', Cbar_Label_Size);

text(ax2, normalized_X, normalized_Y, subplot_labels{2}, ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, 'FontWeight', label_fontweight, 'Color', label_color, ...
    'FontName', 'Times New Roman');

% --- Subplot (c): Land-Cover Classification Map ---
ax3 = nexttile;
h3 = imagesc(x, y, Class_plot);
axis image;
set(ax3, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', Axis_Font_Size, 'LineWidth', 0.8);
set(h3, 'AlphaData', ~isnan(Class_plot));
ax3.Color = [0 0 0];

ylabel('N/S Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', Label_Font_Size, 'FontWeight', 'normal');
xlabel('E/W Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', Label_Font_Size, 'FontWeight', 'normal');

cmap = [
    0.60 0.80 0.30   % Class 1: Phragmites
    0.13 0.55 0.13   % Class 2: Typha
    0.00 0.45 0.74   % Class 3: Water
    0.85 0.65 0.13   % Class 4: Dead
    0.80 0.20 0.20   % Class 5: Road
    1.00 1.00 0.00   % Class 6: Upland
    0.55 0.30 0.70   % Class 7: Non-Living
];
colormap(ax3, cmap);
clim(ax3, [0.5 7.5]);

cb3 = colorbar;
cb3.Ticks = 1:7;
cb3.TickLabels = {'Phrag', 'Typha', 'Water', 'Dead', 'Road', 'Uplnd', 'NonLiv'};
set(cb3, 'FontName', 'Times New Roman', 'FontSize', Cbar_Tick_Size);
ylabel(cb3, 'Class', 'FontName', 'Times New Roman', 'FontSize', Cbar_Label_Size);

text(ax3, normalized_X, normalized_Y, subplot_labels{3}, ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, 'FontWeight', label_fontweight, 'Color', label_color, ...
    'FontName', 'Times New Roman');

linkaxes([ax1, ax2, ax3], 'x');
