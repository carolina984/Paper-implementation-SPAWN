function [err, ratio] = position_error(belief, true_pos)
% POSITION_ERROR  Actual error and calibration ratio for one agent.
%
%   err   : || mu - true_pos ||               [m]
%   ratio : err / sigma
%
%   ratio ~ 1  : the belief is honest
%   ratio >> 1 : OVER-CONFIDENT -- the filter claims more certainty than it has.
%                This is the loopy-BP variance pathology (Weiss & Freeman 2001):
%                on cyclic graphs the means stay correct but the variances
%                come out too small.

[mu, ~, sigma] = belief_estimate(belief);
err = norm(mu - true_pos(:)');
ratio = err / max(sigma, eps);
end
