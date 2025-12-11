%% Make Site Map

% Written by Christian Bright and Timothy H. Morin
%Designed to import maps generated in ArcGIS and exported as .tifs
%Resizes maps and places the tower at the origin for contours
%ONLY OPTION 5 WORKS FOR THE MODEL OUTPUTS


%% Select map for this run (only one can be chosen)
% j=1; %for orthoimagery mapping
% j=2; %for DEM mapping
% j=3; %for Land Cover classification map
% j=4; %for Vegetation Height map
% j=5; %for the ACTUAL surface flux map calculations. Map has to have the
% tower exactly at the center for model to work correctly

cd('C:\MontezumaData\2024_Data\EC_data\FW_FluxMaps\')

j=3;

%% Code to produce footprint over orthoimagery map
if j==1
MWR=imread('FW_maps\Ortho_Hidden_2024.tif');
MWR1 = imresize(MWR, 0.25);
[rows1,cols1,height] = size(MWR1)
%cols1 = cols1/3

x1_pix=683;        %pixel number (X) where map space stops to direct left of tower location
x1_len=-388.31;    %the distance to the left side of the map from tower (found with measure tool in GIS)
x2_pix=5020;       %pixel number where map space stops to direct right of tower location
x2_len=129.76;     %the distance to the right side of the map from tower (found with measure tool in GIS)

y1_pix=6350;       %pixel number (Y) where map space stops (top)
y1_len=-419;       %the distance to the top of the map (found with measure tool in GIS)
y2_pix=533;        %pixel number (Y) where map space stops (bottom)
y2_len=282;        %the distance to the bottom of the map (found with measure tool in GIS)

FX_MWR=interp1([x1_pix x2_pix],[x1_len x2_len],1:cols1,'linear','extrap');
FY_MWR=(interp1([y1_pix y2_pix],[y1_len y2_len],1:rows1,'linear','extrap'));

image(FX_MWR, -FY_MWR, MWR1);
figure;
plot(FY_MWR);

end

%% Code to produce footprint over DEM map
if j==2 
DEM=imread('FW_maps\TowerAreaDEM.tif');
[rows2, cols2] = size(DEM)

x1_pix=164; 
x1_len=-481.74; 
x2_pix=6001; 
x2_len=238.6; 

y1_pix=4437;
y1_len=-261.6;
y2_pix=199; 
y2_len=272.23;

FX_DEM=interp1([x1_pix x2_pix],[x1_len x2_len],1:cols2,'linear','extrap');
FY_DEM=interp1([y1_pix y2_pix],[y1_len y2_len],1:rows2,'linear','extrap');

DEM(DEM<=10)=nan;
pcolor(FX_DEM, FY_DEM, DEM), shading flat;

end 

%% Code to Produce Classified Map 
if j==3
Class_Map=imread('FW_maps\HiddenVegClass.tif');
Class_Map(Class_Map==-9999)=nan;
Class_Map1 = imresize(Class_Map, 0.25);
[rows, cols] = size(Class_Map1);
%pcolor(flipud(Class_Map1)), shading flat;

x1_pix=0;
x1_len=-303.94;
x2_pix=3656;
x2_len=133.32;

y1_pix=5106;
y1_len= -381.03; 
y2_pix=0;
y2_len= 230.3 ; 

FX_CLASS = interp1([x1_pix x2_pix], [x1_len x2_len], 1:cols, 'linear', 'extrap');
FY_CLASS = interp1([y1_pix y2_pix], [y1_len y2_len], 1:rows, 'linear', 'extrap');

pcolor(FX_CLASS,FY_CLASS,Class_Map1), shading flat;colorbar(); 
figure;
plot(FY_CLASS);

end

%% Code to Produce Plant Height Map from Sina
if j==4
Height_Map=imread('FW_maps\HeightMap.tif');
Height_Map(Height_Map==0)=nan;
[rows3, cols3]=size(Height_Map)
pcolor(flipud(Height_Map)), shading flat;

x1_pix=599;        
x1_len=-389.29;    
x2_pix=4793;       
x2_len=116.78;

y1_pix=6050-5249;      
y1_len=279.3;   
y2_pix=6050-498;        
y2_len=-292.78;   

FX_Height=interp1([x1_pix x2_pix],[x1_len x2_len],1:cols3,'linear','extrap');
FY_Height=interp1([y1_pix y2_pix],[y1_len y2_len],1:rows3,'linear','extrap');

 pcolor(FX_Height, FY_Height, Height_Map), shading flat;colorbar();
 figure;
plot(FY_Height);

end

%% Code to produce footprint over CENTERED map
if j==5
CENTER=imread('FW_maps\Center_TEST2.tif');
CENTER = imresize(CENTER, 0.25);
[rows1,cols1] = size(CENTER);
cols1 = cols1/3;
%imagesc(CENTER);

 x1_pix=0;
 x1_len=-168.85;
 x2_pix=2495;
 x2_len=130.28;
 
 y1_pix=3664;
 y1_len=-219.8;   
 y2_pix=0;
 y2_len=219.8;
 
 FX_CENTER=interp1([x1_pix x2_pix],[x1_len x2_len],1:cols1,'linear','extrap');
 FY_CENTER=interp1([y1_pix y2_pix],[y1_len y2_len],1:rows1,'linear','extrap');

imagesc(FX_CENTER, -FY_CENTER, CENTER);

end
%% Write the outputs to a .mat file
if j==1
    save('MWR_map.mat','MWR1','FX_MWR','FY_MWR')
elseif j==2
    save('MWR_DEM_map.mat','DEM','FX_DEM','FY_DEM')
elseif j==3
    save('MWR_CLASS_map.mat', 'Class_Map1', "FX_CLASS", "FY_CLASS")
elseif j==4
    save('MWR_Height_map.mat', "Height_Map", "FX_Height", "FY_Height")
elseif j==5
    save("CENTER_map.mat","CENTER", "FX_CENTER", "FY_CENTER")
end


