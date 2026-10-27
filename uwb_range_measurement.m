function [z, mu, sigma] = uwb_range_measurement(d, env)
%UWB_RANGE_MEASUREMENT  Simulate a UWB range measurement, SPAWN paper's model.
%
%   z = UWB_RANGE_MEASUREMENT(d)            % LIDS-LOS, the default
%   z = UWB_RANGE_MEASUREMENT(d, 'CSAIL-LOS')
%   [z, mu, sigma] = UWB_RANGE_MEASUREMENT(d, env)
%
%   d : true distance(s) [m], any size.  z : measured distance(s) [m].
%
%   WHAT THIS IS
%   Wymeersch, Lien & Win, Proc. IEEE 97(2), 2009, equation (43):
%
%       p(d_hat | d, E) = N( P_{E,mu,2}(d) , P_{E,sigma2,2}(d) )
%
%   a Gaussian whose mean AND variance are quadratic polynomials in the true
%   distance, alpha*d^2 + beta*d + delta, with the coefficients of Table 2
%   (p. 443). Those polynomials were fitted to 1000 measurements per
%   separation from five measurement campaigns around MIT with commercial
%   FCC-compliant UWB radios (Table 1).
%
%   WHY (43) AND NOT (42)
%   Equation (42) is the full model: a THREE-component Gaussian mixture, with
%   components 1 and 3 capturing lower and upper outliers. But Table 2 only
%   tabulates the coefficients for the MAIN mode, because "w_{E,k}(d_sep) << 1
%   for k = 1 and k = 3". So (42) cannot be reproduced from the paper, and the
%   paper itself settles on (43): "Our final model of the UWB ranging
%   measurements d_hat as a function of true distance d in environment E is a
%   Gaussian density described by (43)."
%
%   What you lose: the third output of the weight polynomial tells you what
%   fraction of real measurements the main mode actually covers --
%   99% at 1 m but only 76% at 10 m for LIDS-LOS. The remaining quarter are
%   outliers "consistently located at large distances from the main peak,
%   sometimes producing negative range measurements". Your simulation will
%   therefore be OPTIMISTIC relative to the real radios. Say so in the text;
%   it is also a ready-made future-work item (heavy-tailed ranging).
%
%   WHICH ENVIRONMENT TO USE
%   'LIDS-LOS'. Two reasons: the static-network simulations are in LOS
%   conditions (p. 444), and of the five campaigns it is the ONLY one whose
%   measured separations (0.25-19.25 m, Table 1) reach the 20 m ranging radius
%   used in the simulations. Everything else would be extrapolation.
%
%   It gives an essentially unbiased measurement with a constant
%   sigma = 2.65 cm:
%
%       d true      mean      bias     sigma
%            1    0.9774   -0.0226    0.0265
%            5    5.0002    0.0002    0.0265
%           10   10.0152    0.0152    0.0265
%           20   20.0002    0.0002    0.0265
%
%   A WARNING ABOUT THE OTHER CAMPAIGNS
%   The variance polynomials are fits, not physical models, and two of them go
%   NEGATIVE inside their own measured range: LIDS-NLOS beyond 7.00 m and
%   Hangar beyond 0.25 m. This function clamps the variance at a small floor
%   and warns. Do not use those two without saying what you did.

if nargin < 2 || isempty(env), env = 'LIDS-LOS'; end

%                            mu: [a b c]            sigma2: [a b c]        valid d
T = struct( ...
 'LIDS_LOS',   {{[-0.0003 1.0075 -0.0298], [ 0       0       0.0007], [0.25 19.25]}}, ...
 'LIDS_NLOS',  {{[ 0.0099 0.8623  0.6908], [ 0.0001 -0.0015  0.0056], [2.75  9.00]}}, ...
 'CSAIL_LOS',  {{[-0.0006 1.0130 -0.0480], [ 0       0       0.0002], [0.25 13.50]}}, ...
 'CSAIL_NLOS', {{[-0.0002 1.0119 -0.0470], [ 0       0       0.0002], [1.50 13.50]}}, ...
 'Hangar',     {{[-0.0005 1.0120 -0.0204], [-0.0002  0.0022 -0.0030], [0.25 12.00]}});

key = strrep(upper(env), '-', '_');
key = regexprep(key, '^(LIDS|CSAIL)', '$1');
fn  = fieldnames(T);
idx = find(strcmpi(fn, key), 1);
if isempty(idx)
    error('uwb_range_measurement:env', ...
        'Unknown environment "%s". Use one of: %s', env, strjoin(fn, ', '));
end
c = T.(fn{idx});
pmu = c{1};  pvar = c{2};  lim = c{3};

mu  = polyval(pmu,  d);
var = polyval(pvar, d);

% the fitted variance polynomial can go negative -- clamp and say so
bad = var <= 0;
if any(bad(:))
    warning('uwb_range_measurement:negvar', ...
        ['The %s variance polynomial is negative for %d of %d distances ' ...
         '(from d = %.2f m). Clamped to 1e-6 m^2. This is a limitation of ' ...
         'the quadratic fit, not of your simulation -- document it.'], ...
        env, nnz(bad), numel(var), min(d(bad)));
    var(bad) = 1e-6;
end

sigma = sqrt(var);
z     = mu + sigma .* randn(size(d));

% the polynomials are fits over the measured separations only
out = d < lim(1) | d > lim(2);
if any(out(:))
    warning('uwb_range_measurement:extrap', ...
        ['%d of %d distances fall outside the %s measured range ' ...
         '(%.2f-%.2f m, Table 1). The polynomials are extrapolating.'], ...
        nnz(out), numel(d), env, lim(1), lim(2));
end
end
