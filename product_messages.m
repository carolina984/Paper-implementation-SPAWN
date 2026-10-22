function [samples_kept] = product_messages(iteration_number, current_belief, messages, intranode_sample, internode_samples, k, M )
num_messages = numel(messages);
samples_drawn_total = [];
draw_from_message = ceil(k * M/(num_messages));

if num_messages == 0
    samples_kept = current_belief;
else
    for i = 1:1:(num_messages)
        message = messages{i};
        y = randsample(size(message,1),draw_from_message);
        samples_drawn = message(y, :);
        samples_drawn_total =  cat(1, samples_drawn_total, samples_drawn);
    end


    % %calculate weight of samples
    % for i = 1:1:size(samples_drawn_total,1) %(k*M)
    %     sum = 0;
    %     for j = 1:1:num_messages
    %         v = evaluate_point(samples_drawn_total(i, 1:2), messages{j}, 0.5);
    %         if j == 1
    %             product = v;
    %         else
    %             product = product * v;
    %         end
    % 
    %         sum = sum + v;
    %     end
    %     weight = product/sum;
    %     samples_drawn_total(i, 3) = weight;
    % end

    %calculate weight of samples
    prod_v = ones(size(samples_drawn_total,1), 1);
    sum_v  = zeros(size(samples_drawn_total,1), 1);
    for j = 1:num_messages
        v = evaluate_all_points(samples_drawn_total, messages{j}, 0.5);
        prod_v = prod_v .* v;
        sum_v  = sum_v  + v;
    end
    samples_drawn_total(:,3) = prod_v ./ sum_v;

    
    %resample
    w = randsample(size(samples_drawn_total,1), intranode_sample, true, samples_drawn_total(:, 3));
    samples_kept = samples_drawn_total(w, :);
    samples_kept(:, 3) = 1/intranode_sample;
    samples_kept(:, 4) = 1;
end
end
