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
	speaker_dir = dir(dir_train);
	speaker_dir(~[speaker_dir.isdir]) = [];

	gmms = cell(1,30);
	speakers = cell(1,30);
	speaker_data = cell(1,30);
	num_speaker = 1;

	dim_num = 14;

	%collect data
	%for i=1:length(speaker_dir)
    for i=1:4
		speaker_name = speaker_dir(i).name;
		if (length(speaker_name) == 5)
			data = [];
			file_path = [dir_train,filesep,speaker_name];
			mfcc_files = dir([file_path,filesep,'*mfcc']);
		    for j=1:length(mfcc_files)
		    	file_name = [file_path,filesep,mfcc_files(j).name];
		        lines = dlmread(file_name);
		        lines = lines(:,1:dim_num);
		        data = vertcat(data,lines);
		    end
		    speaker_data{num_speaker} = transpose(data);
		    speakers{num_speaker} = speaker_name;
		    num_speaker = num_speaker + 1;
		end
	end


	for j=1:4
		speakers{j};
	 	gmms{j} = trainGmm(speaker_data{j}, speakers{j}, max_iter, epsilon, M);
	end

	save('gmms.mat', 'gmms', '-mat');

end

function gmm = trainGmm(data, name, max_iter, epsilon, M)
	%initilize gmm
	gmm = struct();
	gmm.name = name;
	%all gaussian has same wieght in initialization
	gmm.weights = ones(1,M)/M;
	%initilize means and covariance to 0 for now
	gmm.means = zeros(14,M);
	gmm.cov = zeros(14,14,M);
	for i=1:M
		% select a random vector to be the centroid
		% does not matter which one here during initialization
	    gmm.means(:,i) = data(:,i);
	    %initilize covariance, cov(i,j) = 1 iff i = j
	    gmm.cov(:,:,i) = diag(ones(1,14));    
	end

	i = 0;
	prev_L = -Inf;
	improvement = Inf;

	while (i<=max_iter && improvement>=epsilon)
	    [L gmm] = EM(data,gmm,M);
        fprintf('Log probability: %g\n',L);
	    improvement = L - prev_L;
	    prev_L = L;
	    i = i + 1;
	end
end

function [L gmm] = EM(data, gmm, M)
	T = size(data,2);
	L = 0;
	% M-step
    for i=1:M
    	mean_vector = gmm.means(:,i);
    	mean_matrix = repmat(mean_vector,1,T);

    	cov_matrix = gmm.cov(:,:,i);
    	cov_diag = diag(cov_matrix);
    	cov_matrix = repmat(cov_diag,1,T);
    	
    	nom = -0.5*sum(((data - mean_matrix).^2) ./ cov_matrix,1);
    	nom = exp(nom);
    	denom = ((2*pi)^7)*sqrt(prod(cov_diag));
    	% 1 x T matrix for bm
    	bm = nom / denom;
    	%weighted probability
    	pm_noms(i,:) = gmm.weights(i) * bm;

    end

    L = sum(log(sum(pm_noms)));
    fprintf('L: %g',L);

    % E-step
    pms = pm_noms ./ repmat(sum(pm_noms,1),M,1);
    total_pm = sum(pms,2);


    gmm.weights = transpose(total_pm / T);
    mean_nom = data * transpose(pms);
    gmm.means = mean_nom ./ repmat(transpose(total_pm),14,1);
    cov_diag = data.^2 * transpose(pms) ./ repmat(transpose(total_pm),14,1) - gmm.means.^2;

    for i=1:M
    	gmm.cov(:,:,i) = diag(cov_diag(:,i));
    end

end
