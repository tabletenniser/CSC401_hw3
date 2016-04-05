function new_likelihood = ComputeLikelihood (data, mean, covariance, prior)
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
    end

    % softmax step 1 => w_m*b_m(x_t)
    softmx = b .* repmat(prior, n_data, 1);
    softmx_sum = sum(softmx, 2);

    % softmax step 2 => normalize
    softmx = softmx ./ repmat(softmx_sum, 1, n_cluster);

    % output
    new_likelihood = softmx;
end
