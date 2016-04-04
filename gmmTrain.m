function gmms = gmmTrain( dir_train, max_iter, epsilon, M )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixture

speakers=dir(dir_train);
%gmms = {};
gmms = cell(1,33);
index = 1;

% Iterate through all speaker directories
%for i=1:size(speakers)
for i=1:4
    if speakers(i).name(1) == '.'
        continue
    end
    gmms{index} = struct();
    gmms{index}.name = speakers(i).name;
    speaker_mfccs = dir([dir_train, filesep, gmms{index}.name, filesep, '*mfcc']);
    
    % Iterate through all .mfcc files for the current speaker
    data = [];
    for j = 1:size(speaker_mfccs)
       fprintf('Loading file: %s %s %s\n', dir_train, speakers(i).name, speaker_mfccs(j).name);
       cur_mfcc_data = load(fullfile(dir_train, speakers(i).name, speaker_mfccs(j).name));
       data = [data; cur_mfcc_data];
    end
    disp(size(data));
    index = index + 1;
end
%disp(speakers);

return