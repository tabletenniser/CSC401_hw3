lines = textread('Predict.out', '%s', 'delimiter','\n');
n_speakers = length(lines);

for speaker_idx=1:n_speakers
    line = strsplit(lines{speaker_idx});
    
    file_base_name = line{1};
    gender = line{2}(1);
    
    fprintf('File base name is: %s, user gender is %c\n', file_base_name, gender);
    
    % To get around Matlab's horrible character escape mechanism, we chose
    % to work around by having a bash script to perform all required
    % functionalities
    text_file_name = ['Testing/', strrep(file_base_name, 'mfcc', 'txt')];
    flac_file_name = ['Testing/', strrep(file_base_name, 'mfcc', 'flac')];
    save_file_name = ['TextToSpeech/', strrep(file_base_name, 'mfcc', 'flac')];
    
    if gender == 'M'
        voice = 'en-US_MichaelVoice';
    elseif gender == 'F'
        voice = 'en-US_LisaVoice';
    else
        assert(0);
    end
    [xxx1, xxx2, text_to_speech] = textread(text_file_name, '%d %d %s', 'delimiter','\n');
    text_to_speech = text_to_speech{:};
        
    cmd = ['env LD_LIBRARY_PATH="" bash onMyCommand.sh "', text_to_speech , '" ', voice , ' ', save_file_name];
    fprintf('Executing command: %s', cmd);
    unix(cmd);
end

IBM('TextToSpeech');