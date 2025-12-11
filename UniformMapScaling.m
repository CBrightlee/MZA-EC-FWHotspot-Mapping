%% Written by Tim Morin on 5/9/2025
%% Last updated by Christian Bright 10/22/25
% Aiming to get all maps into one gridwork to easily compare them
% Linearly interpolate between pixels to get everything in the same

clear;

%% Set the map type that was setup in MapCode.m
% j=1 %for orthoimagery mapping
% j=2 %for DEM mapping
% j=3 %for NDVI classification mapping
% j=4 %for Sina height maps

 jj=[1,2,3,4];
 cd('C:\MontezumaData\2024_Data\EC_data\FW_FluxMaps\Footprint_Output\continuous')
DataDir=('C:\MontezumaData\2024_Data\EC_data\FW_FluxMaps\Footprint_Output\matrices\');

FileList={'MWR-KM-2024193-0000-to-2024274-0000-both-50-80MZA.mat', 'MWR-KM-2024193-0000-to-2024274-0000-day-50-80MZA.mat', 'MWR-KM-2024193-0000-to-2024274-0000-night-50-80MZA.mat'};
 %for the flux weighted maps

load('../../MWR_map.mat')     % Loading up the orthoimagery
    orth.FX=FX_MWR;         % Tim: I was worried about getting confused with all the maps, so I wanted to give orthimagery it's own object
    orth.FY=FY_MWR;
    
    [orth.FXX,orth.FYY]=meshgrid(orth.FX,orth.FY); % orth.FX and orth.FX are 1D vectors. they need to be 2D for the interp2 command. This makes them big 2D fields
    
            figure('Visible','on');
            imagesc(orth.FX, orth.FY, MWR1);
            axis image;
            set(gca, 'YDir', 'normal');
            xlabel('X (m)');
            ylabel('Y (m)');
            drawnow;


for k=1:length(FileList)
    FileToLoad= FileList{k};% Modify the name of the file accordingly
    
    
    % jj=[1,2];
    for j_ct=1:length(jj)
        j=jj(j_ct);
        %% Get Surface Flux Maps onto same scale as orthoimagery
        if j==1        
            load(['SurfFluxMaps_' FileToLoad '.mat']);
            [FXX,FYY]=meshgrid(FX,FY); %Makes 2D field for X and Y
            
            % Interpolates CH4 flux map and saves the data to a csv
            CH4_ortho = interp2(FXX, FYY, CH4_mat, orth.FXX, orth.FYY, 'linear');
        
            x = orth.FX;  % meters
            y = orth.FY;  % meters

            figure('Visible','on');
            h = imagesc(x, y, CH4_ortho);
            axis image;
            set(gca, 'YDir', 'normal');
            colormap(flipud(hot));
            set(h, 'AlphaData', ~isnan(CH4_ortho));
            
            xlabel('X (m)');
            ylabel('Y (m)');
            
            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'CH_4 Flux (nmol m^{-2}s^{-1})';  % TeX version
            cb.Label.Interpreter = 'tex';                        % ensures superscripts
            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size
            
            drawnow;
            CH4_ortho(isnan(CH4_ortho))=-9999;
            writematrix(CH4_ortho, [DataDir FileToLoad '_CH4_ortho.csv']);

            %Interpolates CO2 flux map and saves data to a csv
            CO2_ortho=interp2(FXX,FYY,CO2_mat,orth.FXX,orth.FYY,'linear');
            
            x = orth.FX;  % 1D vector of X in meters
            y = orth.FY;  % 1D vector of Y in meters
            figure('Visible','on');

            i=imagesc(x,y,CO2_ortho);
            axis image;
            set(gca, 'YDir', 'normal');
            colormap(flipud(hot));
            set(i, 'AlphaData', ~isnan(CO2_ortho));
            
            xlabel('X (m)');
            ylabel('Y (m)');
            
            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'CO_2 Flux (umol m^{-2}s^{-1})';  % TeX version
            cb.Label.Interpreter = 'tex'; 
            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size
            
            drawnow;
    

            CO2_ortho(isnan(CO2_ortho))=-9999;
            writematrix(CO2_ortho, [DataDir FileToLoad '_CO2_ortho.csv']);
            
            %Interpolates H2O flux map and saves data to a csv
            H2O_ortho=interp2(FXX,FYY,H2O_mat,orth.FXX,orth.FYY,'linear');
            
            x = orth.FX;  % 1D vector of X in meters
            y = orth.FY;  % 1D vector of Y in meters

            figure('Visible','on');
            r=imagesc(x,y,H2O_ortho);
            colormap(flipud(hot));
            set(r, 'AlphaData', ~isnan(H2O_ortho));
            
            xlabel('X (m)');
            ylabel('Y (m)');
            
            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'H_2_O Flux (nmol/m2s)';
            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size
            
            drawnow;
         

            H2O_ortho(isnan(H2O_ortho))=-9999;
            writematrix(H2O_ortho, [DataDir FileToLoad '_H2O_ortho.csv']);
            
        end

        fprintf('Finished %d\n',k);
        
        %% Get DEM into correct gridspace
        if j==2 %k==1
            load('MWR_DEM_map.mat');
            [FXX,FYY]=meshgrid(FX_DEM,FY_DEM); %Makes 2D field for X and Y
            
            % Interpolates CH4 flux map and saves the data to a csv
            DEM_scale=interp2(FXX,FYY,DEM,orth.FXX,orth.FYY,'linear'); %Stretch and compresses map as needed to fit the desired coordinate system
            DEM_scale(isnan(DEM_scale))=-9999;
        
            writematrix(DEM_scale, [DataDir 'DEM.csv']);
            
            DEM_scale(DEM_scale == -9999) = NaN;
            x = orth.FX;  % 1D vector of X in meters
            y = orth.FY;  % 1D vector of Y in meters
            figure('Visible','on');
            imagesc(x,y,DEM_scale);
            axis image;
            colormap("turbo");
            
            
            xlabel('X (m)');
            ylabel('Y (m)');

            set(gca, 'YDir', 'normal');
            colormap("turbo");

            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'Elevation (m)';
            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size
            
            drawnow;
            
        end
        %% Get Supervised Classification Map into correct gridspace
        if j==3 %& k==1
            load('MWR_CLASS_mapPIX.mat');
            [FXX,FYY]=meshgrid(FX_CLASS,FY_CLASS); %Makes 2D field for X and Y
            
            % Interpolates CH4 flux map and saves the data to a csv
            Class_scale=interp2(FXX,FYY,Class_Map1,orth.FXX,orth.FYY,'nearest'); %Stretch and compresses map as needed to fit the desired coordinate system
            Class_scale(isnan(Class_scale))=-9999;
            
            writematrix(Class_scale, [DataDir 'Class_Map.csv']);

            x = orth.FX;  % 1D vector of X in meters
            y = orth.FY;  % 1D vector of Y in meters
            figure('Visible','on');
            imagesc(x,y, Class_scale);
            axis image;
            set(gca, 'YDir', 'normal');
            axis image;
            colormap("turbo");
            
            xlabel('X (m)');
            ylabel('Y (m)');

            set(gca, 'YDir', 'normal');
            colormap("turbo");

            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'Land Cover Class';

            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size

            drawnow;
        end
        %% Get Height Map into correct gridspace
        if j==4 %& k==1
            load('MWR_Height_map.mat')
            [FXX,FYY]=meshgrid(FX_Height,FY_Height); %Makes 2D field for X and Y
            
            % Interpolates CH4 flux map and saves the data to a csv
            Height_scale=interp2(FXX,FYY,Height_Map,orth.FXX,orth.FYY,'linear'); %Stretch and compresses map as needed to fit the desired coordinate system
            % Height_scale(isnan(Height_scale))=-9999;
            
            x = orth.FX;  % 1D vector of X in meters
            y = orth.FY;  % 1D vector of Y in meters

            figure('Visible','on');
            imagesc(x,y,Height_scale);
            axis image;
            set(gca, 'YDir', 'normal');
            axis image;
            colormap("turbo");
            
            xlabel('X (m)');
            ylabel('Y (m)');

            set(gca, 'YDir', 'normal');
            colormap("turbo");

            % Set axes font size
            ax = gca;
            ax.FontSize = 11;         % axes numbers
            
            % Create colorbar and enforce font size
            cb = colorbar;
            cb.Label.String = 'Plant Height (m)';
            cb.FontSize = 11;         % tick numbers
            cb.Label.FontSize = 14;   % label size
          
            drawnow;


            writematrix(Height_scale, [DataDir 'Height_Map.csv']);

        end

        %% Get Colored Bands into correct gridspace
        if j==5
            cd('C:\MontezumaData\2024_Data\EC_data\FW_FluxMaps\')
            load('BLUE_map.mat') %change file depending on the band of interest
            [FXX,FYY]=meshgrid(FX_BANDS,FY_BANDS); %Makes 2D field for X and Y
            BANDS = double(BANDS);
            
            % Interpolates map and saves the data to a csv
            Band_scale=interp2(FXX,FYY,BANDS,orth.FXX,orth.FYY,'linear'); %Stretch and compresses map as needed to fit the desired coordinate system
            Band_scale(isnan(Band_scale))=-9999;
            
            figure('Visible','on');
            imagesc(Band_scale);
            axis image;
            set(gca, 'YDir', 'normal');
            colormap("turbo");
            colorbar;
            title('Reprojected Color Band Map');
            xlabel('Column (X pixel)');
            ylabel('Row (Y pixel)');
            drawnow;


            writematrix(Band_scale, [DataDir 'BLUE_Map.csv']);



        end
    end
end

x = orth.FX;
y = orth.FY;

figure('Visible','on');
t = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

% Define the labels and font properties
subplot_labels = {'a)', 'b)', 'c)'};
label_fontsize = 14;
label_fontweight = 'bold';
label_color = 'k'; 

% Define normalized coordinates for the labels
% X-position: -0.15 (More negative to move further left, over the Y-axis labels)
normalized_X = -0.2; 
% Y-position: 1.05 (Slightly above the top edge of the plot area)
normalized_Y = 1.05; 
Common_Label_Size = 16;

% --- DEM Map (Subplot a) ---
ax1 = nexttile;
imagesc(x,y,DEM_scale);
axis image;
set(gca,'YDir','normal');

% Set Y-axis label with the new font size
ylabel('N/S Distance to Tower (m)', 'FontSize', Common_Label_Size); 

ax1.XTick = [];
colormap(ax1,"turbo");
cb1 = colorbar;
cb1.Label.String = 'Elevation (m)';
% Set colorbar label with the same font size variable
cb1.Label.FontSize = Common_Label_Size;
cb1.Label.FontUnits = 'points'; % Ensure units are explicit
cb1.Label.FontWeight = 'bold';  % Make it bold to ensure it matches the axis titles' visual weight
cb1.FontSize = 10;

% Place label 'a)'
text(ax1, normalized_X, normalized_Y, subplot_labels{1}, ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, ...
    'FontWeight', label_fontweight, ...
    'Color', label_color);


% --- Height Map (Subplot b) ---
ax2 = nexttile;
imagesc(x,y,Height_scale);
axis image;
set(gca,'YDir','normal');

% Set Y-axis label with the new font size
ylabel('N/S Distance to Tower (m)', 'FontSize', Common_Label_Size);

ax2.XTick = [];
colormap(ax2,"turbo");
cb2 = colorbar;
cb2.Label.String = 'Height (m)';
cb2.Label.FontSize = Common_Label_Size;
cb2.Label.FontUnits = 'points'; % Ensure units are explicit
cb2.Label.FontWeight = 'bold';  % Make it bold to ensure it matches the axis titles' visual weight
cb2.FontSize = 10;

% Place label 'b)'
text(ax2, normalized_X, normalized_Y, subplot_labels{2}, ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, ...
    'FontWeight', label_fontweight, ...
    'Color', label_color);


% --- Class Map (Subplot c) ---
ax3 = nexttile;
imagesc(x,y,Class_scale);
axis image;
set(gca,'YDir','normal');

ylabel('N/S Distance to Tower (m)', 'FontSize', Common_Label_Size);
xlabel('E/W Distance to Tower (m)', 'FontSize', Common_Label_Size);
colormap(ax3,"turbo");
cb3 = colorbar;
cb3.Label.String = 'Class';
cb3.Label.FontSize = Common_Label_Size;
cb3.Label.FontUnits = 'points'; % Ensure units are explicit
cb3.Label.FontWeight = 'bold';  % Make it bold to ensure it matches the axis titles' visual weight
cb3.FontSize = 10;

% Place label 'c)'
text(ax3, normalized_X, normalized_Y, subplot_labels{3}, ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', label_fontsize, ...
    'FontWeight', label_fontweight, ...
    'Color', label_color);


% Link x-axes so horizontal zoom/pan is consistent
linkaxes([ax1, ax2, ax3],'x');