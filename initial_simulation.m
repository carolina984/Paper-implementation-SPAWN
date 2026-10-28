clear workspace

a = 0;
b = 0;


k = 1;                                                                       %sampling constant

h = 0.2; %.265;

cooperative = true;                                                          % false -> non-cooperative MMSE baseline


number_agents = 100;
number_anchors = 13;
number_iterations = 6;                      % the paper's Fig. 14 runs to 10
err = zeros(number_agents, number_iterations);

square_side = 100;

intranode_sample = 2000;                                                     %lets try not to break the code
internode_sample = 500;

max_detection_radius = 20;

anchors = anchors_data();
agents = agents_data(number_agents, square_side);

[neighbors, range_to_agents, range_to_anchors] = evaluate_neighbors(max_detection_radius, number_agents, number_anchors, agents, anchors);


%% Sampl

for i = 1:1:number_agents                                                    %for each agente, in this case only one
    bel_agents{i} = uniform_distribution(square_side, intranode_sample);
end

for i = 1:1:number_anchors                                                   %for each agente, in this case only one
    bel_anchors{i} = dirac_distribution(anchors(i,:), intranode_sample);
end


figure
for i = 1:1:number_agents                                                    %for each agente, in this case only one
    scatter(bel_agents{i}(:,1), bel_agents{i}(:,2), 20, '*')
    axis([0 100 0 100])
    axis square
    
    xlabel('x [m]') 
    ylabel('y [m]') 
    
    grid on

    hold on;
end



% after evaluate_neighbors, BEFORE  for f = 1:number_iterations
z_to_anchors = zeros(size(range_to_anchors));
z_to_agents  = zeros(size(range_to_agents));

for i = 1:number_agents
    for j = 1:number_anchors
        if range_to_anchors(i,j) ~= 0
            z_to_anchors(i,j) = uwb_range_measurement(range_to_anchors(i,j));
        end
    end
end

for i = 1:number_agents                 % one measurement per unordered pair
    for j = i+1:number_agents
        if range_to_agents(i,j) ~= 0
            z = uwb_range_measurement(range_to_agents(i,j));
            z_to_agents(i,j) = z;
            z_to_agents(j,i) = z;        % both ends see the same measurement
        end
    end
end



broadcasted_messages = [];

for f = 1:number_iterations
    a = 0;
    b = 0;
    old_bel_agents = bel_agents;
    old_message_agents = broadcasted_messages;

    for i = 1:1:number_agents                                                %for each agente, in this case only one
        a = 0;
        b = 0;
        message_agent  = {};                                                 % add these two lines
        message_anchor = {};
   
        for j = 1:1:number_anchors
            if range_to_anchors(i, j) ~= 0                                   %its a neighbor!
                b = b + 1;
                message_anchor{b} = compute_message(bel_anchors{j}, internode_sample, intranode_sample, z_to_anchors(i, j), 0.1);
            end
        end
        
        if f>1 && cooperative
            for j = 1:number_agents
                if range_to_agents(i, j) ~= 0 && old_bel_agents{j}(1,4) ~= 0 %its a neighbor! and they ahve information 
                    a = a + 1;
                    message_agent{a} = compute_message(old_message_agents{j}, internode_sample, intranode_sample, z_to_agents(i, j), 0.1);
                end
            end
            all_messages = [message_anchor, message_agent];

        else
            all_messages = message_anchor;
        end

        [new_result, new_message] = product_messages(f, old_bel_agents{i}, all_messages, intranode_sample, internode_sample, k, intranode_sample, h);
        
        new_bel_agents{i} = new_result;
        new_message_agents{i} = new_message;
    end

    bel_agents = new_bel_agents;
    broadcasted_messages = new_message_agents;



    for i = 1:number_agents
        err(i,f) = position_error(bel_agents{i}, agents(i,:));
    end


    figure
    for i = 1:1:number_anchors                                               %for each agente, in this case only one
        scatter(bel_anchors{i}(:,1), bel_anchors{i}(:,2), 50, 'x')
        hold on;
    
    end
    
    for i = 1:1:number_agents                                                %for each agente, in this case only one
        scatter(bel_agents{i}(:,1), bel_agents{i}(:,2), 20, '*')
        hold on;
    end
    axis([0 100 0 100])
    axis square
    
    xlabel('x [m]') 
    ylabel('y [m]') 
    
    grid on

end



spawn_error_contour(err)





figure
for i = 1:1:number_anchors                                                   %for each agente, in this case only one
    scatter(bel_anchors{i}(:,1), bel_anchors{i}(:,2), 50, 'x')
    hold on;

end

% for i = 1:1:number_agents  %for each agente, in this case only one
%     scatter(bel_agents{i}(:,1), bel_agents{i}(:,2), 50, '*')
%     hold on;
% end

% scatter(bel_agents{number_agents}(:,1), bel_agents{number_agents}(:,2), 50, '*')
% hold on;

scatter(anchors(:,1), anchors(:,2), 20, 's')
hold on;
%scatter(agents(:,1), agents(:,2), 50, 'o')
for i = 1:1:number_agents                                                    %for each agente, in this case only one
    scatter(agents(i,1), agents(i,2), 20, 'o')
    hold on;
end
axis([0 100 0 100])
axis square

% for i = 1:1:number_agents  %for each agente, in this case only one
%     scatter(agents(i,1), agents(i,2), 50, 'o')
%     hold on;
% end

xlabel('x [m]') 
ylabel('y [m]') 

grid on
