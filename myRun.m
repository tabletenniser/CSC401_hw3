function myRun(testDir, hmmDir)
    % myRun: usage myRun('./Testing')
    %
    %  inputs:  testDir  : e.g "./Testing"
    %           hmmDir   : Directory containinig trained hmm model for diff trained phoneme
    disp('Hello world!');
    phonemes = dir([testDir, filesep, '*.phn']);

    totalNumClfs   = 0;
    correctNumClfs = 0;
    addpath(genpath('./FullBNT'));

    % Iterate through all testing phonemes
    for i=1:length(phonemes)
    %for i = 1:4
        phn_file = phonemes(i).name
        mfcc_file = strrep(phn_file, 'phn', 'mfcc');
        
        % Read MFCC data
        mfcc_data = load([testDir, filesep, mfcc_file]);
        % Reduce feature to the first 4
        mfcc_data = mfcc_data(:,1:4);

         % Read phoneme data
        [phn_starts, phn_ends, phns] = textread(fullfile(testDir, phn_file), '%d %d %s', 'delimiter','\n');
        phn_length = length(phn_starts);
        totalNumClfs = totalNumClfs + phn_length;

        % For each phoneme in unknown speaker's utterance
        for j=1:phn_length
            start_mfcc_line = (phn_starts(j) / 128) + 1;
            end_mfcc_line   = min(phn_ends(j) / 128, size(mfcc_data,1));
            phon       = phns(j);
            
            % Ignore the phoneme if the start line is after or equal to the
            % end line like Line 34 in unkn_29.phn.
            if start_mfcc_line >= end_mfcc_line
                continue
            end
            
            if strcmp(phon, 'h#')
                phon = 'sil';
            else
                phon = phon{1,1};
            end

            % Evaluate each phonneme log likelihood
            HMMPhonemes = dir(hmmDir);
            %trained_hmms = trained_hmms(3:end); % Skip . and ..

            highest_log_prob = -Inf;
            most_probable_phn = 'NULL';

            for k=1:length(HMMPhonemes)
                HMMPhonemesName = HMMPhonemes(k).name;
                % Skip '.', '..' and '.DS_Store' for MAC
                if HMMPhonemesName(1) == '.'
                    continue
                end
                
                load([hmmDir, filesep, HMMPhonemesName], 'HMM', '-mat');
                curr_log_prob = loglikHMM(HMM, transpose(mfcc_data(start_mfcc_line:end_mfcc_line, :)));

                if curr_log_prob > highest_log_prob
                    highest_log_prob  = curr_log_prob;
                    most_probable_phn = HMMPhonemesName;
                end
            end

    %       if the HMM for the phoneme PHN gives the highest probability,
    %       this is a correct classification, otherwise it's wrong.
            if strcmp(phon, most_probable_phn)
                correctNumClfs = correctNumClfs + 1;
            end
        end
    end

    % Report on the proportion of correct classifications,
    % divided by the total number of all phones in all *phn files in Testing/
    percent_correct = correctNumClfs / totalNumClfs;
    disp(percent_correct)
end
