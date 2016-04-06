function [SE IE DE LEV_DIST] =Levenshtein(hypothesis,annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	LEV_DIST: proportion of overall error in all hypotheses

% open hypothesis file 
%hypothesis_text = tdfread(hypothesis,' ');
text_files = dir(strcat(annotation_dir, '/unkn_*.txt'));

for text_file=text_files'
    file_name = strsplit(text_file.name, '_');
    file_name = strrep(file_name, '.txt', '');
    fprintf('Processing file #%s\n', file_name{2});
    [xxx1, xxx2, actual_text] = textread(strcat(annotation_dir, text_file.name), '%d %d %s', 'delimiter','\n');
    fprintf('Actual text: %s\n', actual_text{1});
    edit_distance('now here is', actual_text{1});
    
end

end

function [SE IE DE LEV_DIST] = edit_distance(hypothesis, actual)
    % first get rid of the period
    actual = regexprep(actual, '\.|\?|!', '');
    actual = lower(actual);
    
    actual = strsplit(actual, ' ');
    hypothesis = strsplit(hypothesis, ' ');
    
    actual = ['_', actual];
    hypothesis = ['_', hypothesis];
    
    % init to max possible edit distance
    distance_mat = inf(length(actual), length(hypothesis));
    distance_mat(1,1) = 0;

    % compute the distance table
    for actual_idx=1:length(actual)
        for hypothesis_idx=1:length(hypothesis)
            fprintf('Actual: %d, hypo: %d\n', actual_idx, hypothesis_idx);
            if strcmp(actual{actual_idx}, hypothesis{hypothesis_idx})
                distance_mat(actual_idx, hypothesis_idx) = distance_mat(max(1, actual_idx-1), max(1, hypothesis_idx-1));
            else
                d1 = distance_mat(max(1, actual_idx - 1), max(1, hypothesis_idx - 1)) + 1;
                d2 = distance_mat(actual_idx, max(1, hypothesis_idx - 1)) + 1;
                d3 = distance_mat(max(1, actual_idx - 1), hypothesis_idx) + 1;
                distance_mat(actual_idx, hypothesis_idx) = min([d1, d2, d3]);
            end
        end
    end
    
    % backtrack to get SE IE DE LEV_DIST
    SE = 0;
    IE = 0;
    DE = 0;
    LEV_DIST = distance_mat(length(actual), length(hypothesis));
    fprintf('MIN distance is: %d\n', LEV_DIST);
    
    actual_idx = length(actual);
    hypothesis_idx = length(hypothesis);
    
    while actual_idx ~= 1 && hypothesis_idx ~= 1
        d1 = distance_mat(max(1, actual_idx - 1), max(1, hypothesis_idx - 1)) + 1;
        d2 = distance_mat(actual_idx, max(1, hypothesis_idx - 1)) + 1;
        d3 = distance_mat(max(1, actual_idx - 1), hypothesis_idx) + 1;
    end

end