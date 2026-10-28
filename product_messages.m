% function [samples_kept, message_to_broadcast] = product_messages(iteration_number, current_belief, messages, intranode_sample, internode_samples, k, M, h)
% num_messages = numel(messages);
% samples_drawn_total = [];
% draw_from_message = ceil(k * M/(num_messages));
% 
% if num_messages == 0
%     samples_kept = current_belief;
% else
%     for i = 1:1:(num_messages)
%         message = messages{i};
%         y = randsample(size(message,1),draw_from_message);
%         samples_drawn = message(y, :);
%         samples_drawn_total =  cat(1, samples_drawn_total, samples_drawn);
%     end
% 
% 
%     % %calculate weight of samples
%     % for i = 1:1:size(samples_drawn_total,1) %(k*M)
%     %     sum = 0;
%     %     for j = 1:1:num_messages
%     %         v = evaluate_point(samples_drawn_total(i, 1:2), messages{j}, 0.5);
%     %         if j == 1
%     %             product = v;
%     %         else
%     %             product = product * v;
%     %         end
%     % 
%     %         sum = sum + v;
%     %     end
%     %     weight = product/sum;
%     %     samples_drawn_total(i, 3) = weight;
%     % end
% 
%     %calculate weight of samples
%     prod_v = ones(size(samples_drawn_total,1), 1);
%     sum_v  = zeros(size(samples_drawn_total,1), 1);
%     for j = 1:num_messages
%         v = evaluate_all_points(samples_drawn_total, messages{j}, h);
%         prod_v = prod_v .* v;
%         sum_v  = sum_v  + v;
%     end
%     samples_drawn_total(:,3) = prod_v ./ sum_v;
% 
% 
%     %resample
%     w = randsample(size(samples_drawn_total,1), intranode_sample, true, samples_drawn_total(:, 3));
%     samples_kept = samples_drawn_total(w, :);
%     samples_kept(:, 3) = 1/intranode_sample;
%     samples_kept(:, 4) = 1;
% 
%     %compute new message
%     message_to_broadcast = intrasamples_to_intersamples(samples_kept, internode_samples);
% 
% end
% end

function [samples_kept, message_to_broadcast] = product_messages(iteration_number, current_belief, messages, intranode_sample, internode_samples, k, M, h)
% PRODUCT_MESSAGES  Ihler Alg. 2 message product, log domain.
%
% messages      : cell of n x 4   [x y w flag]
% samples_kept  : intranode_sample x 4
%
% ONLY THE WEIGHT ARITHMETIC CHANGED. The candidate draw, the proposal, the
% resample and the broadcast are exactly as before. log(a*b) = log(a)+log(b),
% so these are the same weights, computed without losing the exponent.
%
% THE PRIOR IS CORRECTLY ABSENT FROM THE PRODUCT HERE.
% Algorithm 1 line 12 is  b_i ~ b~_i * prod_k c_{k->i},  and b~_i is the
% MOBILITY-UPDATED belief, which stays fixed across the cooperative
% iterations. In this static scenario the prior is uniform, so b~_i is a
% constant and dropping it changes nothing. Do NOT "fix" this by copying the
% drone version -- there the prior is not uniform and must be a factor.


num_messages = numel(messages);
samples_drawn_total = [];
draw_from_message = ceil(k * M/(num_messages));

if num_messages == 0
    % No neighbours in range: the correction is the identity. Previously
    % message_to_broadcast was left unassigned here, which throws as soon as
    % an agent has no anchor within range at iteration 1 (about 2% of agents
    % in this scenario).
    samples_kept = current_belief;
    message_to_broadcast = intrasamples_to_intersamples(samples_kept, internode_samples);
    return
end

for i = 1:1:(num_messages)
    message = messages{i};
    % y = randsample(size(message,1), draw_from_message);
    y = randsample(size(message,1), draw_from_message, true);
    samples_drawn = message(y, :);
    samples_drawn_total = cat(1, samples_drawn_total, samples_drawn);
end

% ======================= THE ONLY CHANGED BLOCK =========================
% Was:
%     prod_v = ones(K,1);  sum_v = zeros(K,1);
%     for j = 1:num_messages
%         v = evaluate_all_points(samples_drawn_total, messages{j}, h);
%         prod_v = prod_v .* v;
%         sum_v  = sum_v  + v;
%     end
%     samples_drawn_total(:,3) = prod_v ./ sum_v;
%
% Now: every multiply is a sum of logs, every sum is a log-sum-exp.
K = size(samples_drawn_total, 1);

log_v = zeros(K, num_messages);
for j = 1:num_messages
    log_v(:,j) = log_evaluate_all_points(samples_drawn_total, messages{j}, h);
end

log_prod = sum(log_v, 2);                    % log(prod_v)

mx  = max(log_v, [], 2);                     % log(sum_v), by log-sum-exp
fin = isfinite(mx);
mm  = mx;  mm(~fin) = 0;
log_sum = mm + log(sum(exp(log_v - mm), 2));
log_sum(~fin) = -Inf;

log_w = log_prod - log_sum;
log_w(~isfinite(log_prod)) = -Inf;           % violates at least one message

top = max(log_w);
if ~isfinite(top)
    error('product_messages:degenerate', ...
        ['All %d candidates violate at least one message at iteration %d ' ...
         '(h = %.4g, %d messages). The incoming rings share no support. ' ...
         'Check h against your ranging sigma before looking here.'], ...
        K, iteration_number, h, num_messages);
end

w_total = exp(log_w - top);                  % proportional to the old weights
w_total(~isfinite(w_total)) = 0;
samples_drawn_total(:,3) = w_total;
% ========================================================================

% resample
w = randsample(size(samples_drawn_total,1), intranode_sample, true, ...
               samples_drawn_total(:, 3));
samples_kept = samples_drawn_total(w, :);
samples_kept(:, 3) = 1/intranode_sample;
samples_kept(:, 4) = 1;

% compute new message
message_to_broadcast = intrasamples_to_intersamples(samples_kept, internode_samples);
end