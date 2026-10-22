function [belief] = dirac_distribution(coordinates,number_samples)
    belief  = [repmat(coordinates,number_samples,1), ones(number_samples, 1)/number_samples, 2*ones(number_samples, 1)]; 
end
