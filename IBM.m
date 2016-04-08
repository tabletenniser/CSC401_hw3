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

for file_idx = 1:n_flac
    fprintf('File name: %s -- %s\n', flac_files(file_idx).name,  text_files(file_idx).name)
    % Do some stuff
    cmd = ['env LD_LIBRARY_PATH="" curl -u 2b78670c-c890-477b-a54b-a4caeb27ad0e:JJgGDcOVXKxB -X POST --header "Content-Type: audio/flac" --header "Transfer-Encoding: chunked" --data-binary @Testing/', flac_files(file_idx).name, ' "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"'];
    [x, y] = unix(cmd);
    %fprintf('IBM result: %s\n', y);
    confidence = regexp(y, '"confidence": (\d+\.\d+)', 'tokens');
    transcript = regexp(y, '"transcript": "([^"]+)"', 'tokens');
    confidence = confidence{1};
    confidence = strtrim(confidence{:});
    transcript = transcript{1};
    transcript = strtrim(transcript{:});
    fprintf('Translated string: %s with confidence %s\n', transcript, confidence);
    [xxx1, xxx2, hypothesis] = textread(['Testing/', text_files(file_idx).name], '%d %d %s', 'delimiter','\n');
    [SE, IE, DE, LEV_DIST, N_HYP] = edit_distance(hypothesis, transcript);
    fprintf('Edit distance between %s and %s is %d\n', hypothesis, transcript, LEV_DIST);

end
