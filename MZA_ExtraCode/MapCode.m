%% Make Site Map (MapCode.m)
% Written by Christian Bright and Timothy H. Morin
% Designed to import maps generated in ArcGIS and exported as .tif files.
% Resizes maps and places the eddy covariance tower at the origin (0,0) for contours.
% NOTE: Only Option 5 (j = 5) is centered on the tower for flux model outputs.

clear; clc;

%% User-Configurable Paths (Update to match your local directory structure)
input_dir  = './data/FW_maps/';
output_dir = './Footprint_Output/continuous/';

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Select Map Layer for This Run (Choose only one)
% j = 1; % Orthoimagery mapping
% j = 2; % DEM mapping
% j = 3; % Land Cover classification map
% j = 4; % Vegetation Height map
% j = 5; % Centered surface flux map (tower strictly at center)
j = 3;

%% Option 1: Produce footprint over orthoimagery map
if j == 1
    MWR = imread(fullfile(input_dir, 'Ortho_Hidden_2024.tif'));

    % Define image resolutions (m/pixel)
    original_res = 0.03;    % Original = 3 cm/pixel
    old_res      = 0.12;    % Reference MWR1 = 12 cm/pixel
    target_res   = 0.12;    % Target resolution: 0.12 (12 cm), 3 (3 m), 10 (10 m), or 30 (30 m)

    % Resize original image directly to target resolution
    resize_factor = original_res / target_res;
    MWR1 = imresize(MWR, resize_factor);
    [rows1, cols1, ~] = size(MWR1);

    % Manual calibration points (pixel locations in reference 12-cm image)
    x1_pix_old = 683;       % Left side
    x1_len     = -388.31;   % Distance from tower (m)
    x2_pix_old = 5020;      % Right side
    x2_len     = 129.76;    % Distance from tower (m)

    y1_pix_old = 6350;      % Top
    y1_len     = -419;      % Distance from tower (m)
    y2_pix_old = 533;       % Bottom
    y2_len     = 282;       % Distance from tower (m)

    % Convert calibration pixels to target resolution
    pixel_scale = old_res / target_res;
    x1_pix = x1_pix_old * pixel_scale;
    x2_pix = x2_pix_old * pixel_scale;
    y1_pix = y1_pix_old * pixel_scale;
    y2_pix = y2_pix_old * pixel_scale;

    FX_MWR = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols1, 'linear', 'extrap');
    FY_MWR = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows1, 'linear', 'extrap');

    figure;
    image(FX_MWR, -FY_MWR, MWR1);
    figure;
    plot(FY_MWR);
end

%% Option 2: Produce footprint over DEM map
if j == 2
    DEM = imread(fullfile(input_dir, 'TowerAreaDEM.tif'));
    [rows2, cols2] = size(DEM);

    x1_pix = 164;   x1_len = -481.74;
    x2_pix = 6001;  x2_len = 238.6;
    y1_pix = 4437;  y1_len = -261.6;
    y2_pix = 199;   y2_len = 272.23;

    FX_DEM = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols2, 'linear', 'extrap');
    FY_DEM = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows2, 'linear', 'extrap');

    DEM(DEM <= 10) = NaN;
    figure;
    pcolor(FX_DEM, FY_DEM, DEM);
    shading flat;
end

%% Option 3: Produce Classified Land-Cover Map
if j == 3
    Class_Map = imread(fullfile(input_dir, 'HiddenVegClass.tif'));
    Class_Map(Class_Map == -9999) = NaN;
    Class_Map1 = imresize(Class_Map, 0.25);
    [rows, cols] = size(Class_Map1);

    x1_pix = 0;     x1_len = -303.94;
    x2_pix = 3656;  x2_len = 133.32;
    y1_pix = 5106;  y1_len = -381.03;
    y2_pix = 0;     y2_len = 230.3;

    FX_CLASS = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols, 'linear', 'extrap');
    FY_CLASS = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows, 'linear', 'extrap');

    figure;
    pcolor(FX_CLASS, FY_CLASS, Class_Map1);
    shading flat;

    % 7 discrete colors for the 7 land-cover classes
    cmap = [
        0.60 0.80 0.30   % Class 1: Phragmites
        0.13 0.55 0.13   % Class 2: Cattail
        0.00 0.45 0.74   % Class 3: Water
        0.85 0.65 0.13   % Class 4: Dead
        0.80 0.20 0.20   % Class 5: Road
        1.00 1.00 0.00   % Class 6: Upland
        0.55 0.30 0.70   % Class 7: Non-Living
    ];
    colormap(cmap);
    clim([0.5 7.5]);

    cb = colorbar;
    cb.Ticks = 1:7;
    cb.TickLabels = {
        'Phragmites'
        'Cattail'
        'Water'
        'Dead'
        'Road'
        'Upland'
        'Non-Living'
    };

    Class_Map1(isnan(Class_Map1)) = -9999;
end

%% Option 4: Produce Plant Height Map
if j == 4
    Height_Map = imread(fullfile(input_dir, 'HeightMap.tif'));
    Height_Map(Height_Map == 0) = NaN;
    [rows3, cols3] = size(Height_Map);

    x1_pix = 599;           x1_len = -389.29;
    x2_pix = 4793;          x2_len = 116.78;
    y1_pix = 6050 - 5249;   y1_len = 279.3;
    y2_pix = 6050 - 498;    y2_len = -292.78;

    FX_Height = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols3, 'linear', 'extrap');
    FY_Height = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows3, 'linear', 'extrap');

    figure;
    pcolor(FX_Height, FY_Height, Height_Map);
    shading flat;
    colorbar();
    figure;
    plot(FY_Height);
end

%% Option 5: Produce footprint over CENTERED map
if j == 5
    CENTER = imread(fullfile(input_dir, 'Center_TEST2.tif'));
    CENTER = imresize(CENTER, 0.25);
    [rows1, cols1] = size(CENTER);
    cols1 = cols1 / 3;

    x1_pix = 0;     x1_len = -168.85;
    x2_pix = 2495;  x2_len = 130.28;
    y1_pix = 3664;  y1_len = -219.8;
    y2_pix = 0;     y2_len = 219.8;

    FX_CENTER = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols1, 'linear', 'extrap');
    FY_CENTER = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows1, 'linear', 'extrap');

    figure;
    imagesc(FX_CENTER, -FY_CENTER, CENTER);
end

%% Save processed outputs to .mat file
if j == 1
    save(fullfile(output_dir, 'MWR_map.mat'), 'MWR1', 'FX_MWR', 'FY_MWR');
elseif j == 2
    save(fullfile(output_dir, 'MWR_DEM_map.mat'), 'DEM', 'FX_DEM', 'FY_DEM');
elseif j == 3
    save(fullfile(output_dir, 'MWR_CLASS_map.mat'), 'Class_Map1', 'FX_CLASS', 'FY_CLASS');
elseif j == 4
    save(fullfile(output_dir, 'MWR_Height_map.mat'), 'Height_Map', 'FX_Height', 'FY_Height');
elseif j == 5
    save(fullfile(output_dir, 'CENTER_map.mat'), 'CENTER', 'FX_CENTER', 'FY_CENTER');
end
