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
    gmms = cell(1,30);  % 30 speakers
    index = 1;

    % Iterate through all speaker directories
    for i=1:size(speakers)
    %for i=15:15
        % Skip non-speaker directories
        if speakers(i).name(1) == '.'
            continue
        end

        % Step #1: Assign speaker name to the proper gmms field
        gmms{index} = struct();
        gmms{index}.name = speakers(i).name;

        % Step #2: Iterate through all .mfcc files and save data to `data`
        speaker_mfccs = dir([dir_train, filesep, gmms{index}.name, filesep, '*mfcc']);
        data = [];      % A T*14 double matrix where T is the number of lines in all .mfcc files
        for j = 1:size(speaker_mfccs)
           %fprintf('Loading file: %s %s %s\n', dir_train, speakers(i).name, speaker_mfccs(j).name);
           cur_mfcc_data = load(fullfile(dir_train, speakers(i).name, speaker_mfccs(j).name));
           data = [data; cur_mfcc_data];
        end
        %disp(size(data));

        % Step #3: Initialize all parameters.
        numOfFeatures = size(data,2);
        means = data(M+1:2*M, :);   % first 8 vectors of the data
        %covs = repmat(eye(numOfFeatures),1,1,M);
        covs = ones(M,numOfFeatures)*1000;  % multiply 1000 to avoid NaN
        omegas = 1/M * ones(1,M);

        % Step #4: Iteratively applying the EM algorithm.
        cur_iter = 0;
        prev_L = -inf;
        improvement = inf;
        while cur_iter <= max_iter && (improvement >= epsilon || isnan(improvement))
            [softmax, L] = ComputeLikelihood(data, means, covs, omegas);
            %disp(size(softmax));
            [omegas, means, covs] = UpdateParameters (softmax, data);
            %L = sum(log(sum(softmax)));
            improvement = L - prev_L;
            fprintf('Log probability: %g; Improvement: %g\n', L, improvement);
            prev_L = L;
            cur_iter = cur_iter + 1;
        end
        
        % Step #5: Save computed values
        gmms{index}.weights = omegas;
        gmms{index}.means = transpose(means);
        diagonal_covs = zeros(numOfFeatures, numOfFeatures, M);
        covs = transpose(covs);
        for k = 1:M
            diagonal_covs(:,:,k) = diag(covs(:,k));
        end
        gmms{index}.cov = diagonal_covs;
        index = index + 1;
    end
    save('gmms.mat', 'gmms', '-mat');
end

function [new_prior, new_mean, new_covariance] = UpdateParameters(softmx, data)
    %UPDATEPARAMETERS Summary of this function goes here
    %   Detailed explanation goes here
    %   softmax: <array<array>> n_data x n_cluster
    %   data: <array<array>> n_data x n_dim
    tmp = size(softmx);
    tmp2 = size(data);
    n_data = tmp(1);
    n_cluster = tmp(2);
    n_dim = tmp2(2);

    % M step as per handout pg. 10
    total_weights = sum(softmx, 1);

    % compute new prior
    new_prior = total_weights / n_data;

    % compute new mean and covariance
    new_mean = zeros(n_cluster, n_dim);
    new_covariance = zeros(n_cluster, n_dim);

    for cluster_idx=1:n_cluster
        cluster_weights = softmx(:, cluster_idx);

        cluster_mean = repmat(cluster_weights, 1, n_dim) .* data;
        cluster_var = cluster_mean .* data;

        cluster_mean = sum(cluster_mean, 1) / total_weights(cluster_idx);
        cluster_var = sum(cluster_var, 1) / total_weights(cluster_idx);

        cluster_covariance = cluster_var - cluster_mean .^ 2;
        new_mean(cluster_idx, :) = cluster_mean;
        new_covariance(cluster_idx, :) = cluster_covariance;
    end
end

%%%%%%%%% E-step %%%%%%%%%%%
function [softmx, L] = ComputeLikelihood (data, mean, covariance, prior)
    %   Detailed explanation goes here
    %   data: <array<aaray>> n_data x n_dim
    %               T data points, each with d dimensions
    %   mean: <array<array>> n_cluster x n_dim
    %               the mean of M clusters
    %   covariance: <array<array>> n_cluster x n_dim
    %               the diagnal of covariance matrix of M clusters
    %   prior: <array> n_cluster
    %               the prior of M clusters

    n_cluster = size(mean, 1);
    n_data = size(data, 1);
    n_dim = size(data, 2);

    b = zeros(n_data, n_cluster);

    % calculate denom for all M clusters, M*1 double array
    covariance_prod = sqrt(prod(covariance, 2)) * (2 * pi) ^ (n_dim/2);

    % calculate new covariance mat for all clusters
    for data_idx=1:n_data
        sample = data(data_idx, :);

        % make n_cluster copies of this
        covariance_mat = repmat(sample, n_cluster, 1);

        % save the result
        covariance_mat = (covariance_mat - mean) .^ 2 ./ covariance;

        % element-wise divide by the covariance mat
        %covariance_mat = covariance_mat ./ covariance;

        % sum each row then exponentiate
        covariance_mat = exp(-0.5 * sum(covariance_mat, 2));

        % divide by denom
        covariance_mat = covariance_mat ./ covariance_prod;

        % save into new_likelihood
        b(data_idx, :) = transpose(covariance_mat);
        %disp(b);
    end
    
    % softmax step 1 => w_m*b_m(x_t)
    softmx = b .* repmat(prior, n_data, 1);
    L = sum(log(sum(softmx, 2)));
    softmx_sum = sum(softmx, 2);

    % softmax step 2 => normalize
    softmx = softmx ./ repmat(softmx_sum, 1, n_cluster);
end
