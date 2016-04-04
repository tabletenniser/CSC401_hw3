function [new_prior, new_mean, new_covariance] = UpdateParameters(softmax, data)
%UPDATEPARAMETERS Summary of this function goes here
%   Detailed explanation goes here
%   softmax: <array<array>> n_data x n_cluster
%   data: <array<array>> n_data x n_dim
tmp = size(softmax);
tmp2 = size(data);
n_data = tmp(1);
n_cluster = tmp(2);
n_dim = tmp2(2);

% M step as per handout pg. 10
total_weights = sum(softmax, 1);

% compute new prior
new_prior = total_weights / n_data;

% compute new mean and covariance
new_mean = zeros(n_cluster, n_dim);
new_covariance = zeros(n_cluster, n_dim);

for cluster_idx=1:n_cluster
    cluster_weights = softmax(:, cluster_idx);
    
    cluster_mean = repmat(cluster_weights, 1, n_dim) .* data;
    cluster_var = cluster_mean .* data;
    
    cluster_mean = sum(cluster_mean, 1) / total_weights(cluster_idx);
    cluster_var = sum(cluster_var, 1) / total_weights(cluster_idx);
    
    cluster_covariance = cluster_var - cluster_mean .^ 2;
    new_mean(cluster_idx, :) = cluster_mean;
    new_covariance(cluster_idx, :) = cluster_covariance;
end


end

