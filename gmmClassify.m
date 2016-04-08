function gmmClassify ()
    trainDir = './Training';
    testDir = './Testing';
    testLabelFile = './Testing/TestingIDs1-15.txt';
    M = 8;
    load('gmms.mat', 'gmms');
    fileID = fopen(testLabelFile);
    labels = textscan(fileID,'%s %s %s','Delimiter',':');
    labelID = labels{1};
    speakerIDLabels = labels{2};
    
    fclose(fileID);

    %TestingMFCCFiles = dir([testDir, filesep, '*mfcc']);

    outSumFile = fopen('Predict.out', 'w');
    fprintf(outSumFile, 'unkn_x : speaker_ID : utterance_ID\n');
    numCorrectLabels = 0;
    %for i=1:length(TestingMFCCFiles)
    for i = 1:30
        MFCCFile = ['unkn_', int2str(i), '.mfcc'];
        fname = ['unkn', int2str(i), '.lik'];
        outputFile = fopen(fname,'w');

        data = load([testDir, filesep, MFCCFile]);
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
            
            L = findLikelihood(data, means, covs, omegas);
            logLikelihoods(s,1) = L;
        end
        %disp(logLikelihoods);
        [sortedLikelihoods,sortedIndices] = sort(logLikelihoods,'descend');
        if i <= 15
            fprintf('%d - %s : %s: %g\n', i, speakerIDLabels{i+1}, gmms{sortedIndices(1)}.name, sortedLikelihoods(1));
            if strcmp(speakerIDLabels{i+1}, gmms{sortedIndices(1)}.name) ~= 0
                numCorrectLabels = numCorrectLabels+1;
            end
        else
            %fprintf('%d - %s : %s: %g\n', i, TestingMFCCFiles(i).name, gmms{sortedIndices(1)}.name, sortedLikelihoods(1));
        end
        fprintf(outputFile, 'Filename: %s: \n', MFCCFile);
        for k=1:5
            fprintf(outputFile, '   Speaker: %s, Likelihood: %d\n', gmms{sortedIndices(k)}.name, sortedLikelihoods(k));
        end
        fprintf(outSumFile, '%s : %s: %s: %s\n', MFCCFile, gmms{sortedIndices(1)}.name, gmms{sortedIndices(2)}.name, gmms{sortedIndices(3)}.name);
        
        fclose(outputFile);
    end
    fclose(outSumFile);
    fprintf('Classification rate: %g\n', numCorrectLabels/15.0);
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
