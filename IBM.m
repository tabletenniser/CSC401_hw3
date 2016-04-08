% curl -u 2b78670c-c890-477b-a54b-a4caeb27ad0e:JJgGDcOVXKxB -X POST --header "Content-Type: audio/flac" --header "Transfer-Encoding: chunked" --data-binary @./unkn_1.flac "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"
% [x, y] = unix('env LD_LIBRARY_PATH="" /usr/bin/curl -u 2b78670c-c890-477b-a54b-a4caeb27ad0e:JJgGDcOVXKxB -X POST --header "Content-Type: audio/flac" --header "Transfer-Encoding: chunked" --data-binary @Testing/unkn_1.flac "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"')

flac_files = dir('Testing/unkn*.flac');
text_files = dir('Testing/unkn*.txt');

n_flac = length(flac_files);
n_text = length(text_files);

if n_flac ~= n_text
    fprintf('ERROR: Number of flac and text files are not the same %d %d\n', n_flac, n_text);
    return
end

total_ref_word = 0;
total_err = 0;

for file_idx = 1:n_flac
    fprintf('File name: %s -- %s\n', flac_files(file_idx).name,  text_files(file_idx).name)
    % Do some stuff
    cmd = ['env LD_LIBRARY_PATH="" curl -u 2b78670c-c890-477b-a54b-a4caeb27ad0e:JJgGDcOVXKxB -X POST --header "Content-Type: audio/flac" --header "Transfer-Encoding: chunked" --data-binary @Testing/', flac_files(file_idx).name, ' "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"'];
    [x, y] = unix(cmd);
    %fprintf('IBM result: %s\n', y);
    
    % I REALLY REALLY REALLY wish i had a json library
    confidence = regexp(y, '"confidence": (\d+\.\d+)', 'tokens');
    transcript = regexp(y, '"transcript": "([^"]+)"', 'tokens');
    
    % pull the string out of cell, trim away trailing spaces
    confidence = confidence{1};
    confidence = strtrim(confidence{:});
    transcript = transcript{1};
    transcript = strtrim(transcript{:});
    [xxx1, xxx2, hypothesis] = textread(['Testing/', text_files(file_idx).name], '%d %d %s', 'delimiter','\n');
    [SE, IE, DE, LEV_DIST, N_WD] = edit_distance(hypothesis{:}, transcript);
    
    fprintf('Translated string: %s -- confidence %s\n', transcript, confidence);
    fprintf('Referecne string : %s\n', hypothesis{:});

    fprintf('Edit distance between is %d => WER is %f\n', LEV_DIST, LEV_DIST/N_WD);
    total_ref_word = total_ref_word + N_WD;
    total_err = total_err + LEV_DIST;
    fprintf('\n')
end

fprintf('Average WER is %f\n', 1.0 * total_err/total_ref_word);
