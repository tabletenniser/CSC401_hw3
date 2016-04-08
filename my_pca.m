function pca_data = my_pca(data, k)
    
    % compute covariance matrix
    C = cov(data);
    
    % get eigenvectors and eigenvalues
    % D is the eval, V is evec
    [V,D] = eig(C);
    
    % we now extract the top K eigenvectors
    diagnal = diag(D);
    [sorted, index] = sort(-diagnal);
    top_k_eigen = V(:, index(1:k));
    
    pca_data = data * top_k_eigen;
end

