function [message] = compute_message(neighbor_belief, internode_samples, intranode_samples, range_measurement, noise)

ratio_samples  = intranode_samples/internode_samples;
neighbor_belief = repmat(neighbor_belief,ratio_samples,1);

message = zeros(intranode_samples, 4);
flag = neighbor_belief(1, 4);

for i = 1:1:intranode_samples
    theta = rand * 2 * pi;
    message(i, 1:2) = neighbor_belief(i, 1:2) + ((range_measurement)+ noise )* [sin(theta), cos(theta)]; %
    message(i, 3) = neighbor_belief(i, 3); %particle weight
end
message(1, 4) = flag;
end
