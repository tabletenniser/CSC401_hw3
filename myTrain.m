function myTrain(dir_train, max_iter, num_hidden_states, out_folder, M )
    % myTrain: usage myTrain('./Training', 10, 3, 'hmm.out', 8)
    %
    %  inputs:  dir_train  : e.g "./Training"
    %           max_iter   : maximum number of training iterations
    %                       (int) e.g 10
    %           num_hidden_states    : number of hidden states in HMM (int)
    %                                   e.g 3
    %           M          : number of Gaussians/mixture (integer) e.g 8
    %           out_file   : file of the trained HMM
    %
    disp('Hello world!');
    speakers = dir(dir_train);
    phonemes = struct();

    % Iterate through all speaker directories
    %for i=1:size(speakers)
    for i=1:6
        % Skip non-speaker directories
        if speakers(i).name(1) == '.'
            continue
        end

        speaker_dir = [dir_train, filesep, speakers(i).name];
        speaker_mfccs = dir([speaker_dir, filesep, '*.mfcc']);

        % Iterate through all training data under current speaker
        for j=1:size(speaker_mfccs)
        %for j=1:5
            mfcc_file = speaker_mfccs(j).name;
            phn_file = strrep(mfcc_file, 'mfcc', 'phn');

            % Load mfcc data
            mfcc_data = load(fullfile(dir_train, speakers(i).name, mfcc_file));
            % Reduce feature to the first 4
            mfcc_data = mfcc_data(:,1:4);

            % Read phoneme data for this speaker's utterance
            [phn_starts, phn_ends, phns] = textread(fullfile(dir_train, speakers(i).name, phn_file), '%d %d %s', 'delimiter','\n');

            % For each phoneme in utterance
            for k=1:size(phn_starts)
                start_mfcc_line = (phn_starts(k) / 128) + 1;
                end_mfcc_line   = min(phn_ends(k) / 128, size(mfcc_data));
                phon       = phns(k);
                
                if strcmp(phon, 'h#')
                    phon = 'sil';
                else
                    phon = phon{1,1};
                end

                % Create empty array if phon appears for the first time.
                if ~isfield(phonemes, phon)
                    phonemes.(phon) = {};
                end
                phonemes.(phon){length(phonemes.(phon))+1} = transpose(mfcc_data(start_mfcc_line:end_mfcc_line, :));
            end
        end
    end

    addpath(genpath('./FullBNT'));

    % Init and train an HMM for each of the unique phonemes seen
    unique_phonemes = fields(phonemes);
    for j=1:length(unique_phonemes)
        curr_phn_name = unique_phonemes{j};
        data = phonemes.(curr_phn_name);

        HMM = initHMM(data, M, num_hidden_states, 'kmeans');
        [HMM, LL] = trainHMM(HMM, data, max_iter);

        save([out_folder, curr_phn_name], 'HMM', '-mat');
    end
end