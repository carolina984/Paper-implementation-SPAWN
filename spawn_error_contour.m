function spawn_error_contour(err, style, ttl)
%SPAWN_ERROR_CONTOUR  Reproduce Fig. 14 of Wymeersch, Lien & Win (2009).
%
%   spawn_error_contour(err)                 % contour, as in the paper
%   spawn_error_contour(err, 'image')        % imagesc, sharper per-cell read
%   spawn_error_contour(err, 'contour', 'my title')
%
%   err : n_agents x n_iterations, position error in metres.
%         err(i,l) = || mu_i^(l) - x_i_true ||
%
%   Reproduces: y-axis node index, x-axis iteration, logarithmic colour scale
%   from 1 mm to 10 m with the paper's tick labels, jet colormap (red = large
%   error, blue = small).
%
%   WHAT THE PAPER'S FIGURE SHOWS, SO YOU KNOW WHETHER YOURS MATCHES
%   Fig. 14 is one realisation, 100 agents, 13 anchors, 100x100 m, 20 m
%   ranging radius, 10 iterations, uniform priors. Three features to check:
%
%     1. Iteration 1 is almost entirely red (metres of error) -- only agents
%        with enough anchors in range are resolved.
%     2. By iteration 4 the plot is mostly green/cyan. The text says the
%        cooperative MMSE "converges in about four iterations", and at
%        e_th = 1 m the outage falls below 1%.
%     3. A small number of horizontal red STRIPES persist to iteration 10.
%        The text identifies one such agent: "connected to only two other
%        nodes (one agent and one anchor), and therefore unable to determine
%        its position without ambiguity." If your plot has no persistent
%        stripes at all, your geometry is more connected than theirs; if it
%        has many, something upstream is wrong.

if nargin < 2 || isempty(style), style = 'contour'; end
if nargin < 3, ttl = ''; end

err = max(err, 1e-4);                 % clamp so log10 is finite
L   = log10(err);

[nA, nI] = size(err);
it   = 1:nI;
node = 1:nA;

figure('Color','w');

switch lower(style)
    case 'image'
        imagesc(it, node, L);
        set(gca, 'YDir', 'normal');
    otherwise
        contourf(it, node, L, linspace(-3, 1, 24), 'LineStyle', 'none');
end

colormap(jet);
clim([-3 1]);                          % 1 mm .. 10 m   (use caxis on R2022a and older)

cb = colorbar;
cb.Ticks      = [-3 -2 -1 0 1];
cb.TickLabels = {'1 mm', '1 cm', '10 cm', '1 m', '10 m'};

xlabel('iteration');
ylabel('node index');
if ~isempty(ttl), title(ttl); end

xticks(1:max(1, round(nI/10)):nI);
yticks(0:10:nA);
box on;

% --- the numbers the paper quotes, printed so you can compare directly ----
fprintf('\n--- error summary (compare with Fig. 14 / Fig. 15) ---\n');
fprintf('%9s %10s %10s %10s %12s\n', 'iteration', 'median', 'mean', '90th pct', 'outage@1m');
for l = 1:nI
    e = err(:,l);
    fprintf('%9d %10.3f %10.3f %10.3f %11.1f%%\n', ...
        l, median(e), mean(e), prctile(e, 90), 100*mean(e > 1));
end
fprintf('\npaper: cooperative MMSE converges in ~4 iterations;\n');
fprintf('       outage at e_th = 1 m falls below 1%% (Fig. 15).\n');

% --- persistent failures: the agents that never resolve -------------------
final = err(:,end);
bad   = find(final > 1);
if isempty(bad)
    fprintf('\nno agent above 1 m at the last iteration.\n');
    fprintf('the paper has one; check your connectivity is not more generous.\n\n');
else
    fprintf('\n%d agent(s) still above 1 m at iteration %d: %s\n', ...
            numel(bad), nI, mat2str(bad(:).'));
    fprintf('cross-check these against their neighbour counts -- the paper''s\n');
    fprintf('one failure had exactly two neighbours (one agent, one anchor).\n\n');
end
end
