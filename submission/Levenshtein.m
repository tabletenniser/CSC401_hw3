function [SE, IE, DE, LEV_DIST] =Levenshtein(hypothesis,annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	LEV_DIST: proportion of overall error in all hypotheses

% open hypothesis file + annotation dir
[xxx1, xxx2, hypothesis_text] = textread(hypothesis, '%d %d %s', 'delimiter','\n');
text_files = dir(strcat(annotation_dir, '/unkn_*.txt'));

% init some parameters
SE = 0;
IE = 0;
DE = 0;
total_words = 0;

for text_file=text_files'
    file_name = strsplit(text_file.name, '_');
    file_name = strrep(file_name, '.txt', '');
    % fprintf('Processing file #%s\n', file_name{2});
    [xxx1, xxx2, actual_text] = textread(strcat(annotation_dir, text_file.name), '%d %d %s', 'delimiter','\n');
    % fprintf('Actual text: %s\n', actual_text{1});
    % fprintf('Hypothesis text: %s\n', hypothesis_text{str2num(file_name{2})});

    [se, ie, de, lev_dist, n_words] = edit_distance(hypothesis_text{str2num(file_name{2})}, actual_text{1});
    % fprintf('Distance: SE=%d, IE=%d, DE=%d, LEV_DIST=%d out of %d\n', se, ie, de, lev_dist, n_words)
    SE = SE + se;
    IE = IE + ie;
    DE = DE + de;
    total_words = total_words + n_words;
end

% total_words is the number of words in REFERENCE TEXT
DE = DE / total_words;
SE = SE / total_words;
IE = IE / total_words;
LEV_DIST = DE + SE + IE;

end

