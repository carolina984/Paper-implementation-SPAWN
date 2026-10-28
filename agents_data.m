function [agents_pos] = agents_data(n_agents, square_size)
rng(0)

agents_pos = zeros(n_agents,2);

% for i = 1:1:n_agents
%     agents_pos(i, :) = [randi(square_size), randi(square_size)];
% end

agents_pos(:, :) = randi(square_size, n_agents, 2); %square_size*rand(n_agents,2);

end
