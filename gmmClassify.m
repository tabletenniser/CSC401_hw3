function clf = gmmClassify ()
    trainDir = './Training';
    testDir = './Testing';
    M = 8;
    epsilon = 0.001;

    %gmms = gmmTrain(trainDir, 10, epsilon, M);
    load('gmms.mat', 'gmms');

    TestingMFCCFiles = dir([testDir, filesep, '*mfcc']);

    for i=1:length(TestingMFCCFiles)

        fprintf('test MFCC file: %s\n', TestingMFCCFiles(i).name);

        data = load([testDir, filesep, TestingMFCCFiles(i).name]);
        logLikelihoods = zeros(length(gmms),1);

        % Iterate through all GMMS for each speaker and find the one with
        % largest probability
        for s=1:length(gmms)
            means = transpose(gmms{s}.means);
            omegas = gmms{s}.weights;
            diagonal_covs = gmms{s}.cov;
            numOfFeatures = size(means, 2);

            covs = zeros(numOfFeatures, M);
            for k = 1:M
                covs(:,k) = diag(diagonal_covs(:,:,k));
            end
            covs = transpose(covs);
            
            if s == 2
                fprintf('%d', s);
            end
            L = findLikelihood(data, means, covs, omegas);
            logLikelihoods(s,1) = L;
        end
        %disp(logLikelihoods);
        [sortedLikelihoods,sortedIndices] = sort(logLikelihoods,'descend');
        fprintf('Top guess: %s with prob: %g\n', gmms{sortedIndices(1)}.name, sortedLikelihoods(1));
    end
end

function L = findLikelihood(data, mean, covariance, prior)
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
end
