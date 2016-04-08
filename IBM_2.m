curl -u 07607d3a-37e9-4ec3-a8f8-700b58161832:dT3swy0NpmV3 -X POST --header "Content-Type: application/json" --header "Accept: audio/flac" --header "Voice: en-US_LisaVoice" --data "{\"text\":\"hello world\"}" "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize" > hello_world.flac

flac_files = dir('Testing/unkn*.flac');
text_files = dir('Testing/unkn*.txt');

if n_flac ~= n_text
    fprintf('ERROR: Number of flac and text files are not the same %d %d\n', n_flac, n_text);
    return
end

total_ref_word = 0;
total_err = 0;

for file_idx = 1:n_flac
    fprintf('File name: %s -- %s\n', flac_files(file_idx).name,  text_files(file_idx).name)
    % Do some stuff
    slash = char(92);
    cmd = ['env LD_LIBRARY_PATH="" curl -u 2b78670c-c890-477b-a54b-a4caeb27ad0e:JJgGDcOVXKxB -X POST --header "Content-Type: audio/flac" --header "Transfer-Encoding: chunked" --data-binary @Testing/', flac_files(file_idx).name, ' "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"'];
    [x, y] = unix(cmd);
end