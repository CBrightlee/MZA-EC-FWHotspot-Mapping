function[tempMap2]=CalcPercF_fast(footD)
    percOpts  = sort(unique(footD),'descend');
    maxBins=1000;
    if length(percOpts)<maxBins
        tempMap2=nan(size(footD));
        for i=1:length(percOpts)
            curPerc=percOpts(i);
            good=footD>=curPerc;
            score=sum(sum(footD(good)));
            tempMap2(good & isnan(tempMap2))=score;
            if score>0.99*nansum(nansum(footD)) % If the score is higher than 99% of the total, break the process to save resources
                break
            end    
        end
    else
        nbins=maxBins;
        
        percBins=linspace(percOpts(1),percOpts(end),nbins);   % Pick bins for percOpts that can be run in a reasonable period of time
        tempMap2=nan(size(footD));
        for i=1:length(percBins)
        % Locate bins that have footD values between the two bin sides
            curPerc=percBins(i);
            % good=percOpts>=curPerc;
            good=footD>=curPerc;
            score=sum(sum(footD(good)));
            tempMap2(good & isnan(tempMap2))=score;
            % Use those to make tempMap2(good & isnan(tempMap2))=score;the good matrix, score matrix, tempMap2
            if score>0.99*nansum(nansum(footD)) % If the score is higher than 99% of the total, break the process to save resources
                break
            end  
            if mod(i,100)==0
                fprintf('Run %d done\n',i);
            end
        end
    end
end