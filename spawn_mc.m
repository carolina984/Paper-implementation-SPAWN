function R = spawn_mc(n_mc, cfg)
%SPAWN_MC  Monte Carlo over network realizations, as the paper does for Fig. 15.
%
%   R = spawn_mc(20)                      % defaults
%   R = spawn_mc(20, struct('k',4,'h',0.265))
%
%   WHAT THE PAPER AVERAGES AND WHAT IT DOES NOT
%   Fig. 13 and Fig. 14 are SINGLE realizations ("for a particular realization
%   of the network"). Fig. 15 -- the outage curves, and the source of the
%   "below 1% at e_th = 1 m" claim -- is "over an ensemble of 20 random
%   network instantiations". So a single run cannot be compared against that
%   number; the layout lottery is part of the result.
%
%   R.err      : nA x nIt x n_mc
%   R.outage   : nIt x n_mc, fraction above 1 m
%   R.summary  : per-iteration table, mean and spread across runs

if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'number_agents'),     cfg.number_agents     = 100; end
if ~isfield(cfg,'number_iterations'), cfg.number_iterations = 10;  end

nA = cfg.number_agents;  nIt = cfg.number_iterations;
R.err  = zeros(nA, nIt, n_mc);
R.uniq = zeros(nA, nIt, n_mc);
R.nmsg = zeros(nA, nIt, n_mc);
R.degA = zeros(nA, n_mc);
R.degN = zeros(nA, n_mc);

fprintf('running %d realizations', n_mc);
t0 = tic;
for m = 1:n_mc
    [e, info] = spawn_run(1000 + m, cfg);     % seed varies -> layout AND noise vary
    R.err(:,:,m)  = e;
    R.uniq(:,:,m) = info.unique;
    R.nmsg(:,:,m) = info.n_messages;
    R.degA(:,m)   = info.n_agent_nbrs;
    R.degN(:,m)   = info.n_anchor_nbrs;
    fprintf('.');
end
fprintf(' done in %.1f s\n', toc(t0));

R.cfg = cfg;
R.outage = squeeze(mean(R.err > 1, 1));        % nIt x n_mc
if n_mc == 1, R.outage = R.outage(:); end

%% ---- per-iteration table -----------------------------------------------
fprintf('\n=== %d realizations, %d agents  (k = %g, h = %g) ===\n', ...
        n_mc, nA, cfg.k, cfg.h);
fprintf('%5s %10s %10s %10s %16s %10s\n', ...
        'iter','median','mean','90th pct','outage@1m','uniq');
for l = 1:nIt
    e = reshape(R.err(:,l,:), [], 1);
    o = R.outage(l,:);
    fprintf('%5d %10.3f %10.3f %10.3f %8.2f%% +- %-4.2f %10.0f\n', ...
        l, median(e), mean(e), prctile(e,90), 100*mean(o), 100*std(o), ...
        mean(reshape(R.uniq(:,l,:),[],1)));
end

%% ---- outage vs iteration, with the spread across runs ------------------
figure('Color','w');
mo = 100*mean(R.outage,2);  so = 100*std(R.outage,0,2);
errorbar(1:nIt, mo, so, '-o', 'LineWidth', 1.6); hold on
yline(1, '--', 'paper: <1%', 'LabelHorizontalAlignment','left');
xline(4, ':', 'paper: ~4 iter');
set(gca,'YScale','log'); grid on
xlabel('iteration'); ylabel('P_{out}(e_{th} = 1 m)  [%]');
title(sprintf('outage vs iteration, %d realizations', n_mc));

%% ---- Fig. 15 style: outage vs allowable error --------------------------
eth = linspace(0, 5, 120);
figure('Color','w'); hold on
for l = unique([1 2 4 nIt])
    e = reshape(R.err(:,l,:), [], 1);
    plot(eth, arrayfun(@(t) mean(e > t), eth), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('iteration %d', l));
end
set(gca,'YScale','log'); grid on; legend('Location','northeast');
xlabel('e_{th} [m]'); ylabel('P_{out}(e_{th})');
title('outage vs allowable error  (compare Fig. 15)');
ylim([1e-3 1]);

%% ---- who is in the tail, and why ---------------------------------------
final = reshape(R.err(:,end,:), [], 1);
degA  = R.degA(:);  degN = R.degN(:);
bad   = final > 1;
fprintf('\n=== the tail at iteration %d ===\n', nIt);
fprintf('  %d of %d agent-runs above 1 m (%.1f%%)\n', sum(bad), numel(bad), 100*mean(bad));
fprintf('  their degree: %.2f agents + %.2f anchors   (vs %.2f + %.2f for the rest)\n', ...
        mean(degA(bad)), mean(degN(bad)), mean(degA(~bad)), mean(degN(~bad)));
fprintf('  fraction of the tail with < 3 total neighbours: %.0f%%\n', ...
        100*mean(degA(bad)+degN(bad) < 3));
fprintf('\n  If that last number is high, the tail is STARVATION (geometry).\n');
fprintf('  If it is low, the tail is agents with plenty of neighbours that\n');
fprintf('  still failed -- which is MODE SELECTION, and more particles or a\n');
fprintf('  higher k is the lever, not more anchors.\n\n');

R.summary = struct('outage_mean', mo, 'outage_std', so);
end
