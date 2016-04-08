
function [SE, IE, DE, LEV_DIST, N_HYP] = edit_distance(hypothesis, actual)
    % first get rid of all punct. and split into words,
    % convert all chars to lower case and 
    % append "_" to the front of the array 
    actual = regexprep(actual, '\.|\?|!|,', '');
    actual = lower(actual);
    actual = strsplit(actual, ' ');
    actual = ['_', actual];

    hypothesis = regexprep(hypothesis, '\.|\?|!|,', '');
    hypothesis = lower(hypothesis);
    hypothesis = strsplit(hypothesis, ' ');
    hypothesis = ['_', hypothesis];
    
    N_HYP = length(actual) - 1;
    
    % init distances to inf, dist(1,1) is 0
    distance_mat = inf(length(actual), length(hypothesis));
    distance_mat(1,1) = 0;

    % compute the edit distance table
    for actual_idx=1:length(actual)
        for hypothesis_idx=1:length(hypothesis)
            %fprintf('Actual: %d, hypo: %d\n', actual_idx, hypothesis_idx);
            if strcmp(actual{actual_idx}, hypothesis{hypothesis_idx})
                % same char, no error here
                distance_mat(actual_idx, hypothesis_idx) = distance_mat(max(1, actual_idx-1), max(1, hypothesis_idx-1));
            else
                % SE | DE | IE
                d1 = distance_mat(max(1, actual_idx - 1), max(1, hypothesis_idx - 1));
                d2 = distance_mat(actual_idx, max(1, hypothesis_idx - 1));
                d3 = distance_mat(max(1, actual_idx - 1), hypothesis_idx);
                
                % pick the one with lowest edit distance
                distance_mat(actual_idx, hypothesis_idx) = min([d1, d2, d3]) + 1;
            end
        end
    end
    
    % backtrack to get SE IE DE LEV_DIST
    SE = 0;
    IE = 0;
    DE = 0;
    LEV_DIST = distance_mat(length(actual), length(hypothesis));
    %fprintf('MIN distance is: %d\n', LEV_DIST);
    
    actual_idx = length(actual);
    hypothesis_idx = length(hypothesis);
    current_distance = LEV_DIST;
    
    while actual_idx ~= 1 || hypothesis_idx ~= 1
        %fprintf('Backtracking ... (%d, %d)\n', actual_idx, hypothesis_idx);
        
        d1 = inf;
        d2 = inf;
        d3 = inf;
        
        if actual_idx ~= 1 && hypothesis_idx ~= 1
            d1 = distance_mat(actual_idx - 1, hypothesis_idx - 1);
        end
        
        if actual_idx ~= 1
            d3 = distance_mat(actual_idx - 1, hypothesis_idx);
        end
        
        if hypothesis_idx ~= 1
            d2 = distance_mat(actual_idx, hypothesis_idx - 1);
        end
        
        next_step = min([d1, d2, d3]);
        if next_step == current_distance
            % No error
            assert(next_step == d1);
            
            actual_idx = actual_idx - 1;
            hypothesis_idx = hypothesis_idx - 1;
        elseif d2 == next_step
            % Deletion
            DE = DE + 1;
            hypothesis_idx = hypothesis_idx - 1;
        elseif d3 == next_step
            % Insertion
            IE = IE + 1;
            actual_idx = actual_idx - 1;
        else
            % SE
            SE = SE + 1;
            actual_idx = actual_idx - 1;
            hypothesis_idx = hypothesis_idx - 1;
        end
        
        % update current lev distance
        current_distance = next_step; 
    end

    % make sure the result makes sense
    assert(LEV_DIST == IE + SE + DE);
end
