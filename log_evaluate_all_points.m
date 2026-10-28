function lp = log_evaluate_all_points(q, mixture, h)
%LOG_EVALUATE_ALL_POINTS  log of evaluate_all_points, via log-sum-exp.
%
%   lp = LOG_EVALUATE_ALL_POINTS(q, mixture, h)
%
%   q       K x >=2   points to evaluate at (columns 1:2 used)
%   mixture M x >=3   kernel centres in columns 1:2, weights in column 3
%   lp      K x 1     log of the kernel density at each point
%
%   Same quantity as evaluate_all_points, same weights, computed without
%   throwing away the exponent. Drop-in: wherever you had
%
%       v = evaluate_all_points(q, m, h);     prod_v = prod_v .* v;
%
%   you now have
%
%       lv = log_evaluate_all_points(q, m, h);  log_prod = log_prod + lv;
%
%   WHY IT IS NEEDED
%   In binary64, exp(x) returns exactly 0 for x < -745.13. A single kernel
%   therefore contributes exactly nothing beyond d = 38.6*h. Worse, a PRODUCT
%   of J message densities vanishes once
%
%       sum_j d_j^2 / (2h^2) > 745      i.e.    d_rms > 38.6*h / sqrt(J)
%
%   so the tolerance shrinks as 1/sqrt(J): with 12 incoming messages the
%   product dies at 11.1*h where one factor survives to 38.6*h. More
%   neighbours makes the product MORE fragile, which is the signature of an
%   arithmetic failure rather than an inferential one.
%
%   Before every weight reaches zero, the small ones get there first, so the
%   linear domain silently replaces the weight distribution with a truncated
%   one. That is worse than crashing: the code runs and returns a number.
%
%   This is also what the SPAWN literature prescribes. Lien et al. (2012),
%   section 4.3.1: "For numerical stability reasons, weights are often
%   computed and stored in the logarithmic domain... Once all R log-domain
%   weights are computed, they are translated, exponentiated, and normalized:
%   w_k ~ exp(lambda_k - max_l lambda_l)."
%
%   Memory-chunked: the full distance matrix for 8000 candidates against 2000
%   kernels is 128 MB, and exp() of it is another 128 MB.

M = size(mixture, 1);
K = size(q, 1);
lp = -inf(K, 1);

if M == 0, return; end

lw   = log(max(mixture(:,3), realmin)).';     % 1 x M
cx   = mixture(:,1).';
cy   = mixture(:,2).';
logZ = log(2*pi*h^2);

chunk = max(1, floor(4e6 / M));               % ~32 MB per block

for a = 1:chunk:K
    b  = min(a + chunk - 1, K);
    d2 = (q(a:b,1) - cx).^2 + (q(a:b,2) - cy).^2;
    e  = -d2/(2*h^2) + lw;                    % log of each kernel's term
    m  = max(e, [], 2);

    ok       = isfinite(m);                   % all-zero-weight rows stay -Inf
    mm       = m;  mm(~ok) = 0;
    s        = sum(exp(e - mm), 2);
    out      = mm + log(s) - logZ;
    out(~ok) = -Inf;

    lp(a:b) = out;
end
end
