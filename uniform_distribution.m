function [belief] = uniform_distribution(room_side,number_samples)
    belief  = [room_side*rand(number_samples,1), room_side*rand(number_samples,1), ones(number_samples, 1)/number_samples, zeros(number_samples, 1)]; 
end
