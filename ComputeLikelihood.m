function new_likelihood = ComputeLikelihood (data, mean, covariance, prior)
%COMPUTE Summary of this function goes here
%   Detailed explanation goes here
%   data: <array<aaray>> - T data points, each with d dimensions
%   mean: <array<array>> - the mean of M clusters
%   covariance: <array<array>> - the covariance matrix of M clusters
%   prior: <array> - the prior of M clusters

n_cluster = length(mean);
tmp = size(data);
n_data = tmp(1);
n_dim = tmp(2);

b = zeros(n_data, n_dim);

% calculate denom for all M clusters
covariance_prod = sqrt(prod(covariance, 2)) * (2 * pi) ^ (n_dim/2);

% calculate new covariance mat for all clusters
for data_idx=1:n_data
    sample = data(data_idx, :);
    
    % make n_cluster copies of this
    covariance_mat = repmat(sample, n_cluster, 1);
    
    % save the result
    covariance_mat = (covariance_mat - mean) .^ 2;
    
    % element-wise divide by the covariance mat
    covariance_mat = covariance_mat ./ covariance;
   
    % sum each row then exponentiate
    covariance_mat = exp(-0.5 * sum(covariance_mat, 2));
    
    % divide by denom
    covariance_mat = covariance_mat ./ covariance_prod;
    
    % save into new_likelihood
    b(data_idx, :) = transpose(covariance_mat);
    
end

% softmax step 1 => w_m*b_m(x_t)
softmax = b .* repmat(prior, n_data, 1);

% softmax step 2 => normalize 
softmax = softmax ./ repmat(sum(softmax, 2), 1, n_dim);

% output
new_likelihood = softmax;
end