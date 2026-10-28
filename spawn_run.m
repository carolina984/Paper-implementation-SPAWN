function [err, info] = spawn_run(seed, cfg)
%SPAWN_RUN  One SPAWN realization. No plots. Returns error per agent per iteration.
%
%   [err, info] = spawn_run(seed, cfg)
%
%   err  : number_agents x number_iterations, position error [m]
%   info : struct of diagnostics -- ESS, unique particle counts, degrees
%
%   REQUIRES one change to your repo: delete the `rng(0)` inside agents_data.m,
%   or stop calling it (this function generates the layout itself so that the
%   seed actually varies). With rng(0) hardcoded inside, every Monte Carlo run
%   would use an identical layout and the spread would come out as zero.

if ~isfield(cfg,'number_agents'),      cfg.number_agents      = 100;   end
if ~isfield(cfg,'number_iterations'),  cfg.number_iterations  = 10;    end
if ~isfield(cfg,'square_side'),        cfg.square_side        = 100;   end
if ~isfield(cfg,'intranode_sample'),   cfg.intranode_sample   = 2000;  end
if ~isfield(cfg,'internode_sample'),   cfg.internode_sample   = 500;   end
if ~isfield(cfg,'max_detection_radius'),cfg.max_detection_radius = 20;  end
if ~isfield(cfg,'k'),                  cfg.k                  = 1;     end
if ~isfield(cfg,'h'),                  cfg.h                  = 0.265; end
if ~isfield(cfg,'cooperative'),        cfg.cooperative        = true;  end
if ~isfield(cfg,'env'),                cfg.env                = 'LIDS-LOS'; end

rng(seed);

nA   = cfg.number_agents;
nIt  = cfg.number_iterations;
anchors = anchors_data();
nAnc = size(anchors,1);

% layout: uniform over the square, driven by the seed
agents = cfg.square_side * rand(nA, 2);

[neighbors, range_to_agents, range_to_anchors] = evaluate_neighbors( ...
        cfg.max_detection_radius, nA, nAnc, agents, anchors);

% ---- measurements, drawn ONCE (reused across all BP iterations) ---------
z_to_anchors = zeros(size(range_to_anchors));
z_to_agents  = zeros(size(range_to_agents));
for i = 1:nA
    for j = 1:nAnc
        if range_to_anchors(i,j) ~= 0
            z_to_anchors(i,j) = uwb_range_measurement(range_to_anchors(i,j), cfg.env);
        end
    end
end
for i = 1:nA
    for j = i+1:nA
        if range_to_agents(i,j) ~= 0
            z = uwb_range_measurement(range_to_agents(i,j), cfg.env);
            z_to_agents(i,j) = z;  z_to_agents(j,i) = z;
        end
    end
end

% ---- initial beliefs ----------------------------------------------------
bel_agents  = cell(1,nA);
bel_anchors = cell(1,nAnc);
for i = 1:nA,   bel_agents{i}  = uniform_distribution(cfg.square_side, cfg.intranode_sample); end
for i = 1:nAnc, bel_anchors{i} = dirac_distribution(anchors(i,:),      cfg.intranode_sample); end

broadcasted_messages = cell(1,nA);
new_bel_agents       = cell(1,nA);
new_message_agents   = cell(1,nA);

err  = zeros(nA, nIt);
ess  = nan(nA, nIt);
uniq = nan(nA, nIt);
nmsg = zeros(nA, nIt);

% ---- iterations ---------------------------------------------------------
for f = 1:nIt
    old_bel_agents     = bel_agents;
    old_message_agents = broadcasted_messages;

    for i = 1:nA
        message_anchor = {};  message_agent = {};

        for j = 1:nAnc
            if range_to_anchors(i,j) ~= 0
                message_anchor{end+1} = compute_message(bel_anchors{j}, ...
                    cfg.internode_sample, cfg.intranode_sample, z_to_anchors(i,j), 0); %#ok<AGROW>
            end
        end

        if f > 1 && cfg.cooperative
            for j = 1:nA
                if range_to_agents(i,j) ~= 0 && old_bel_agents{j}(1,4) ~= 0
                    message_agent{end+1} = compute_message(old_message_agents{j}, ...
                        cfg.internode_sample, cfg.intranode_sample, z_to_agents(i,j), 0); %#ok<AGROW>
                end
            end
            all_messages = [message_anchor, message_agent];
        else
            all_messages = message_anchor;
        end

        nmsg(i,f) = numel(all_messages);

        [new_bel_agents{i}, new_message_agents{i}] = product_messages(f, ...
            old_bel_agents{i}, all_messages, cfg.intranode_sample, ...
            cfg.internode_sample, cfg.k, cfg.intranode_sample, cfg.h);
    end

    bel_agents           = new_bel_agents;
    broadcasted_messages = new_message_agents;

    for i = 1:nA
        err(i,f)  = position_error(bel_agents{i}, agents(i,:));
        uniq(i,f) = size(unique(round(bel_agents{i}(:,1:2), 9), 'rows'), 1);
    end
end

info = struct('agents', agents, 'anchors', anchors, 'neighbors', neighbors, ...
              'n_anchor_nbrs', sum(range_to_anchors ~= 0, 2), ...
              'n_agent_nbrs',  sum(range_to_agents  ~= 0, 2), ...
              'n_messages', nmsg, 'unique', uniq, 'ess', ess, 'cfg', cfg, 'seed', seed);
end
