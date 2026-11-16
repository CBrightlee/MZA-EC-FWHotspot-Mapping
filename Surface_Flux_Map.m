%% Code to create Footprint-weighed Flux maps
%  This code takes the input from CalculateFootprint and plots a flux map
%  of the desired scalar.
% Created by Camilo Rey-Sanchez
% Last modified: Jun 30 2022

site='MZA';
cd('C:\MontezumaData\2024_Data\EC_data\FW_FluxMaps\Footprint_Output\continuous\');
DataDir=('C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\continuous\');% Modify the data directory where the footprint output was saved

FileList={'MWR-KM-2024193-0000-to-2024274-0000-both-50-80MZA.mat', 'MWR-KM-2024193-0000-to-2024274-0000-day-50-80MZA.mat', 'MWR-KM-2024193-0000-to-2024274-0000-night-50-80MZA.mat'};
for k=1:length(FileList)
    FileToLoad= FileList{k};
    
    load([DataDir FileToLoad])    
    
    FPall(1).name='Hsieh';
    FPall(2).name='Kljun';
    FPall(3).name='K&M';
    
    %% Surface Flux Map
    
    cutFP=80; %adjust to desired frequency of points (start at 100)
    
    F1=figure('position',[50,100,1100,370]);
    for j=3 % Number 3 is K&M model     
    
        % CH4 flux 
        subplot(1,3,1)
        Lflux=COMP(j).Fs0tile./COMP(j).footWeightS0;
        Lflux(FG(j).percF>cutFP)=nan; Lflux(isnan(FG(j).percF))=nan;   

        %FY2 = flipud(FY2);

        CH4_mat = Lflux;
        %pcolor(FX2,FY2(RT:-1:1,: ),Lflux);
        pcolor(FX2,-FY2, Lflux);
        shading('flat'); colormap('Turbo'); colorbar('Location','south'); 
        xlabel('x [m]'); 
        title(opt.FS0) 
        set(gca,'fontsize',12)
     
        
        % CO2 flux 
        subplot(1,3,2)
        Lflux=COMP(j).Fs1tile./COMP(j).footWeight;
        Lflux(FG(j).percF>cutFP)=nan; Lflux(isnan(FG(j).percF))=nan; 
        
        CO2_mat=Lflux;
    
        %pcolor(FX2,FY2(RT:-1:1,: ),Lflux);
        pcolor(FX2,-FY2, Lflux);
        shading('flat'); colormap('Turbo'); colorbar('Location','south');     
        xlabel('x [m]'); 
        title(opt.FS1) 
        set(gca,'fontsize',12)
        
         % H2O flux 
        subplot(1,3,3)
        Lflux=COMP(j).Fs2tile./COMP(j).footWeight;
        Lflux(FG(j).percF>cutFP)=nan; Lflux(isnan(FG(j).percF))=nan;   
    
        H2O_mat= Lflux;
    
        % pcolor(FX2,FY2(RT:-1:1,:),Lflux);
        pcolor(FX2,-FY2, Lflux);
        shading('flat'); colormap('Turbo'); colorbar('Location','south');     
        xlabel('x [m]');   
        title(opt.FS2)   
        set(gca,'fontsize',12)   
        
    end
    %saveas(F1, [FileToLoad '.fig']);
    saveas(F1, [FileToLoad '.png']);
    FY=-FY2(:,1);
    FX=FX2(1,:);

    footWeightS0 = COMP(3).footWeightS0;

    save(['SurfFluxMaps_' FileToLoad '.mat'],'FX','FY','CH4_mat','CO2_mat','H2O_mat', 'footWeightS0')
    %close all
end

%% Overlay Flux Maps on Orthomosaic
% 3-Panel Vertical Layout

MatrixDir = 'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\matrices\';
ContinuousDir = 'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\continuous\';

% Load MWR_map.mat once to get spatial grid and ortho background
mapData = load(fullfile(ContinuousDir, 'MWR_map.mat'));
FX = mapData.FX_MWR;
FY = mapData.FY_MWR;
OrthoBg = mapData.MWR1;

% Cases with precise manuscript-matching colorbar labels
Cases = struct( ...
    'label', {'CH4_BOTH', 'CO2_DAY', 'CO2_NIGHT'}, ...
    'cbarLabel', {'CH_4 Flux (\muol m^{-2} s^{-1})', 'CO_2 Day Flux (\muol m^{-2} s^{-1})', 'CO_2 Night Flux (\muol m^{-2} s^{-1})'}, ...
    'letter', {'(a)', '(b)', '(c)'});

% Create figure window
fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1, 1, 6.5, 9.5]);

% Use tiledlayout with compact spacing
t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for c = 1:numel(Cases)
    ax = nexttile;
    
    % 1. PLOT ORTHOMOSAIC BACKGROUND
    imagesc(FX, FY, OrthoBg);
    colormap(ax, gray); 
    hold on;

    % Load flux matrix and corresponding weight matrix
    fluxFile = fullfile(MatrixDir, [Cases(c).label '_3m_flux.csv']);
    weightFile = fullfile(MatrixDir, [Cases(c).label '_3m_weight.csv']);

    if ~isfile(fluxFile)
        fluxFile = fullfile(MatrixDir, [Cases(c).label '_flux.csv']);
        weightFile = fullfile(MatrixDir, [Cases(c).label '_weight.csv']);
    end

    Z = readmatrix(fluxFile);
    W = readmatrix(weightFile);

    Z(Z == -9999) = NaN;
    W(W == -9999) = NaN;

    % 2. PLOT FLUX OVERLAY WITH 0.6 OPACITY & DIRECT ALPHA MAPPING
    alphaData = double(isfinite(Z) & W > 0) * 0.6; 
    hSurface = imagesc(FX, FY, Z, 'AlphaData', alphaData);
    set(hSurface, 'AlphaDataMapping', 'none');
    
    % Switch active colormap to turbo for the flux overlay layer
    colormap(ax, turbo);
    
    % Panel Styling & Standardized Axis Font Formatting
    set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, 'LineWidth', 0.8);
    
    % Fine-tuned letter label positioning outside top-left of plot area
    text(-0.15, 1.05, Cases(c).letter, 'Units', 'normalized', ...
        'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

    grid off;
    axis image;
    set(ax, 'YDir', 'normal');

    % Axis labels & ticks matching Figure 3 conventions
    if c < 3
        set(ax, 'XTickLabel', []);
    else
        xlabel('E/W Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'normal');
    end
    ylabel('N/S Distance to Tower (m)', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'normal');

    % Individual colorbar with manuscript-matching label and font styling
    cb = colorbar;
    set(cb, 'FontName', 'Times New Roman', 'FontSize', 9);
    ylabel(cb, Cases(c).cbarLabel, 'FontName', 'Times New Roman', 'FontSize', 10);

    hold off;
end

% Save high-resolution publication figure
figName = fullfile(MatrixDir, 'Figure4_Publication_Overlays.png');
exportgraphics(fig, figName, 'Resolution', 300);
fprintf('Figure 4 successfully generated and saved to: %s\n', figName);