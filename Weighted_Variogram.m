

%% Compare footprint-weighted semivariograms across resolutions
% CH4 BOTH, CO2 DAY, CO2 NIGHT
% Requires the paired flux and weight CSV files already created.

clear;
clc;
rng(1);  % Reproducible sampling

MatrixDir = ...
    'C:\MontezumaData\2024_Data\EC_Data\FW_FluxMaps\Footprint_Output\matrices\';

OutputDir = MatrixDir;

ResLabels = {'12cm','3m','10m','30m'};
PixelSize = [0.12, 3, 10, 30];

Cases = struct( ...
    'label', {'CH4_BOTH','CO2_DAY','CO2_NIGHT'}, ...
    'title', {'CH_4 BOTH','CO_2 DAY','CO_2 NIGHT'});

maxLag = 60;
lagWidth = 10;
nPairsPerBin = 20000;
maxAttempts = 30;

lagEdges = 0:lagWidth:maxLag;
lagCenters = lagEdges(1:end-1) + lagWidth/2;

Summary = table();

for c = 1:numel(Cases)

    figure('Color','w');
    hold on;
    plotted = false;

    for r = 1:numel(ResLabels)

        label = sprintf('%s_%s', Cases(c).label, ResLabels{r});
        fluxFile = fullfile(MatrixDir, [label '_flux.csv']);
        weightFile = fullfile(MatrixDir, [label '_weight.csv']);

        if ~isfile(fluxFile) || ~isfile(weightFile)
            error('Missing flux or weight CSV for %s.', label);
        end

        fprintf('\nLoading %s...\n', label);

        Z = readmatrix(fluxFile);
        W = readmatrix(weightFile);

        if ~isequal(size(Z), size(W))
            error('Flux and weight dimensions differ for %s.', label);
        end

        % Convert the missing-data sentinel to NaN.
        Z(Z == -9999) = NaN;
        W(W == -9999) = NaN;

        valid = isfinite(Z) & isfinite(W) & W >= 0;
        valid = valid & W > 0;

        validIdx = find(valid);
        if numel(validIdx) < 100
            warning('Too few valid weighted cells for %s.', label);
            clear Z W valid validIdx;
            continue;
        end

        z = double(Z(validIdx));
        w = double(W(validIdx));

        % Weighted mean and weighted variance.
        weightedMean = sum(w .* z) / sum(w);
        weightedVariance = sum(w .* (z - weightedMean).^2) / sum(w);

        if ~isfinite(weightedVariance) || weightedVariance <= 0
            warning('Invalid weighted variance for %s.', label);
            clear Z W valid validIdx z w;
            continue;
        end

        [nRows,nCols] = size(Z);
        cellSize = PixelSize(r);

        % Store weighted normalized semivariance by lag bin.
        gammaNorm = nan(size(lagCenters));
        pairCount = zeros(size(lagCenters));

        for b = 1:numel(lagCenters)

            lowLag = lagEdges(b);
            highLag = lagEdges(b+1);

            % Sample pairs using randomly selected start cells and
            % offsets whose distances fall in the requested lag bin.
            sumWeightedSquaredDiff = 0;
            sumPairWeights = 0;
            accepted = 0;
            attempts = 0;

            while accepted < nPairsPerBin && attempts < maxAttempts

                nTry = max(5000, 3*(nPairsPerBin-accepted));
                attempts = attempts + 1;

                startIdx = validIdx(randi(numel(validIdx),nTry,1));
                [rr,cc] = ind2sub([nRows,nCols],startIdx);

                % Random distance and direction, converted to pixel offsets.
                distance = lowLag + (highLag-lowLag)*rand(nTry,1);
                angle = 2*pi*rand(nTry,1);

                dc = round((distance .* cos(angle))/cellSize);
                dr = round((distance .* sin(angle))/cellSize);

                % Avoid zero-offset pairs.
                zeroOffset = (dr == 0 & dc == 0);
                dr(zeroOffset) = 1;

                rr2 = rr + dr;
                cc2 = cc + dc;

                inside = rr2 >= 1 & rr2 <= nRows & ...
                         cc2 >= 1 & cc2 <= nCols;

                if ~any(inside)
                    continue;
                end

                rr = rr(inside);
                cc = cc(inside);
                rr2 = rr2(inside);
                cc2 = cc2(inside);
                dr = dr(inside);
                dc = dc(inside);

                % Use actual distance between pixel centers.
                actualDistance = cellSize .* hypot(double(dr),double(dc));
                inBin = actualDistance >= lowLag & actualDistance < highLag;

                rr = rr(inBin);
                cc = cc(inBin);
                rr2 = rr2(inBin);
                cc2 = cc2(inBin);

                if isempty(rr)
                    continue;
                end

                idx1 = sub2ind([nRows,nCols],rr,cc);
                idx2 = sub2ind([nRows,nCols],rr2,cc2);

                z1 = Z(idx1);
                z2 = Z(idx2);
                w1 = W(idx1);
                w2 = W(idx2);

                good = isfinite(z1) & isfinite(z2) & ...
                       isfinite(w1) & isfinite(w2) & ...
                       w1 > 0 & w2 > 0;

                z1 = double(z1(good));
                z2 = double(z2(good));
                w1 = double(w1(good));
                w2 = double(w2(good));

                if isempty(z1)
                    continue;
                end

                take = min(numel(z1),nPairsPerBin-accepted);
                z1 = z1(1:take);
                z2 = z2(1:take);
                w1 = w1(1:take);
                w2 = w2(1:take);

                pairW = w1 .* w2;
                sumWeightedSquaredDiff = sumWeightedSquaredDiff + ...
                    sum(pairW .* (z1-z2).^2);

                sumPairWeights = sumPairWeights + sum(pairW);
                accepted = accepted + take;
            end

            pairCount(b) = accepted;

            if accepted > 0 && sumPairWeights > 0
                gamma = sumWeightedSquaredDiff / (2*sumPairWeights);
                gammaNorm(b) = gamma / weightedVariance;
            end
        end

        % Plot only bins containing sampled pairs.
        usable = isfinite(gammaNorm);
        if any(usable)
            plot(lagCenters(usable),gammaNorm(usable),'-o', ...
                'LineWidth',1.5, ...
                'DisplayName',ResLabels{r});
            plotted = true;
        end

        % Save results for this case and resolution.
        T = table( ...
            repmat(string(Cases(c).label),numel(lagCenters),1), ...
            repmat(string(ResLabels{r}),numel(lagCenters),1), ...
            lagCenters(:), gammaNorm(:), pairCount(:), ...
            'VariableNames', ...
            {'Case','Resolution','Lag_m','NormalizedSemivariance','PairsUsed'});

        Summary = [Summary; T]; %#ok<AGROW>

        fprintf('  %s: valid cells = %d\n', ...
            ResLabels{r}, numel(validIdx));

        clear Z W valid validIdx z w;
    end

    xlabel('Lag distance (m)');
    ylabel('Normalized weighted semivariance');
    title(['Footprint-weighted semivariogram: ' Cases(c).title]);
    legend('Location','best');
    grid on;
    xlim([0 maxLag]);

    if ~plotted
        warning('No usable lag bins for %s.', Cases(c).label);
    end

    figName = fullfile(OutputDir, ...
        ['WeightedSemivariogram_' Cases(c).label '.png']);

    saveas(gcf,figName);
    fprintf('Saved figure: %s\n',figName);
    hold off;
end

summaryFile = fullfile(OutputDir,'WeightedSemivariogram_Summary.csv');
writetable(Summary,summaryFile);

fprintf('\nAll comparisons finished.\n');
fprintf('Summary saved to: %s\n',summaryFile);
