%% Compare Footprint-Weighted Semivariograms Across Resolutions
% Publication-Ready 3-Panel Vertical Figure Generation (Including 30m Diagnostics)
% Font: Times New Roman | Colors: Colorblind-Safe (Okabe-Ito)

clear;
clc;
rng(1);  % Reproducible random sampling

MatrixDir = ...
    'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\matrices\';

ResLabels = {'12cm','3m','10m','30m'};
PixelSize = [0.12, 3, 10, 30];

Cases = struct( ...
    'label', {'CH4_BOTH','CO2_DAY','CO2_NIGHT'}, ...
    'title', {'CH_4','CO_2 Day','CO_2 Night'}, ...
    'letter', {'(a)', '(b)', '(c)'});

maxLag = 60;
lagWidth = 10;
nPairsTarget = 20000;
maxAttempts = 50;

lagEdges = 0:lagWidth:maxLag;
lagCenters = lagEdges(1:end-1) + lagWidth/2;
nBins = numel(lagCenters);

% Colorblind-friendly palette (Okabe-Ito)
% 12cm = Blue, 3m = Vermillion, 10m = Amber, 30m = Bluish Green
Colors = [
    0.00, 0.45, 0.70;  % 12cm (#0072B2)
    0.84, 0.37, 0.00;  % 3m   (#D55E00)
    0.90, 0.62, 0.00;  % 10m  (#E69F00)
    0.00, 0.60, 0.50   % 30m  (#009E73)
];
Markers = {'o', 's', '^', 'd'};

Summary = table();

% Create single publication figure with 3 vertical subplots
fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1, 1, 6.5, 8.5]);

for c = 1:numel(Cases)

    ax = subplot(3, 1, c);
    hold on;

    for r = 1:numel(ResLabels)

        label = sprintf('%s_%s', Cases(c).label, ResLabels{r});
        fluxFile = fullfile(MatrixDir, [label '_flux.csv']);
        weightFile = fullfile(MatrixDir, [label '_weight.csv']);

        if ~isfile(fluxFile) || ~isfile(weightFile)
            fprintf('Missing CSV files for %s. Skipping.\n', label);
            continue;
        end

        Z = readmatrix(fluxFile);
        W = readmatrix(weightFile);

        Z(Z == -9999) = NaN;
        W(W == -9999) = NaN;

        valid = isfinite(Z) & isfinite(W) & W > 0;
        validIdx = find(valid);
        nValidCells = numel(validIdx);

        % Diagnostic printout in command window
        fprintf('Case: %-10s | Resolution: %-5s | Valid Footprint Cells: %d\n', ...
            Cases(c).label, ResLabels{r}, nValidCells);

        if nValidCells < 50
            fprintf('  --> Skipped on graph: Insufficient valid cells (%d) for spatial analysis.\n', nValidCells);
            continue;
        end

        [nRows, nCols] = size(Z);
        cellSize = PixelSize(r);

        z = double(Z(validIdx));
        w = double(W(validIdx));
        zMean = sum(w .* z) / sum(w);
        zVariance = sum(w .* (z - zMean).^2) / sum(w);

        if ~isfinite(zVariance) || zVariance <= 0
            continue;
        end

        gammaNorm = nan(1, nBins);
        pairCount = zeros(1, nBins);

        for b = 1:nBins
            lowLag = lagEdges(b);
            highLag = lagEdges(b+1);

            maxOffset = ceil(highLag / cellSize);
            [dCol, dRow] = meshgrid(-maxOffset:maxOffset, -maxOffset:maxOffset);
            dist = cellSize .* hypot(dRow, dCol);

            useOffset = dist >= lowLag & dist < highLag & dist > 0;
            offsets = [dRow(useOffset), dCol(useOffset)];

            if isempty(offsets)
                continue;
            end

            sumWDiff2 = 0;
            sumPairW = 0;
            accepted = 0;
            attempts = 0;

            while accepted < nPairsTarget && attempts < maxAttempts
                nTry = max(1000, 3 * (nPairsTarget - accepted));
                attempts = attempts + 1;

                startIdx = validIdx(randi(nValidCells, nTry, 1));
                [rr, cc] = ind2sub([nRows, nCols], startIdx);

                offsetChoice = randi(size(offsets, 1), nTry, 1);
                dr = offsets(offsetChoice, 1);
                dc = offsets(offsetChoice, 2);

                rr2 = rr + dr;
                cc2 = cc + dc;

                inside = rr2 >= 1 & rr2 <= nRows & cc2 >= 1 & cc2 <= nCols;
                rr = rr(inside); cc = cc(inside);
                rr2 = rr2(inside); cc2 = cc2(inside);

                if isempty(rr), continue; end

                idx1 = sub2ind([nRows, nCols], rr, cc);
                idx2 = sub2ind([nRows, nCols], rr2, cc2);

                good = valid(idx1) & valid(idx2);
                idx1 = idx1(good); idx2 = idx2(good);

                if isempty(idx1), continue; end

                take = min(numel(idx1), nPairsTarget - accepted);
                idx1 = idx1(1:take); idx2 = idx2(1:take);

                z1 = double(Z(idx1)); z2 = double(Z(idx2));
                w1 = double(W(idx1)); w2 = double(W(idx2));

                pairW = w1 .* w2;
                sumWDiff2 = sumWDiff2 + sum(pairW .* (z1 - z2).^2);
                sumPairW = sumPairW + sum(pairW);
                accepted = accepted + take;
            end

            pairCount(b) = accepted;

            if accepted > 0 && sumPairW > 0
                gamma = sumWDiff2 / (2 * sumPairW);
                gammaNorm(b) = gamma / zVariance;
            end
        end

        usable = isfinite(gammaNorm);
        if any(usable)
            plot(lagCenters(usable), gammaNorm(usable), ...
                'LineStyle', '-', ...
                'LineWidth', 1.5, ...
                'Color', Colors(r,:), ...
                'Marker', Markers{r}, ...
                'MarkerSize', 6, ...
                'MarkerFaceColor', 'w', ...
                'DisplayName', ResLabels{r});
        end

        T = table( ...
            repmat(string(Cases(c).label), nBins, 1), ...
            repmat(string(ResLabels{r}), nBins, 1), ...
            lagCenters(:), gammaNorm(:), pairCount(:), ...
            'VariableNames', {'Case', 'Resolution', 'Lag_m', 'NormalizedSemivariance', 'PairsUsed'});

        Summary = [Summary; T]; %#ok<AGROW>
    end

    % Subplot Formatting & Styling
    set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, 'LineWidth', 0.8);
    title(Cases(c).title, 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Letter label outside the top-left of the plot area
    text(-0.08, 1.15, Cases(c).letter, 'Units', 'normalized', ...
        'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

    grid off;

    % Shared X-axis settings
    if c < 3
        set(ax, 'XTickLabel', []);
    else
        xlabel('Lag distance (m)', 'FontName', 'Times New Roman', 'FontSize', 11);
    end

    if c == 2
        ylabel('Normalized weighted semivariance', 'FontName', 'Times New Roman', 'FontSize', 11);
    end

    if c == 1
        legend('Location', 'southeast', 'FontName', 'Times New Roman', 'FontSize', 9);
    end
end

% Save publication figure and table
figName = fullfile(MatrixDir, 'Publication_Semivariograms_3Panel.png');
exportgraphics(fig, figName, 'Resolution', 300);

writetable(Summary, fullfile(MatrixDir, 'WeightedSemivariogram_Summary.csv'));
fprintf('\nAnalysis finished. Publication figure saved to: %s\n', figName);