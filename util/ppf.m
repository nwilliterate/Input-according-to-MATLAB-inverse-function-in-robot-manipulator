% Copyright (C) 2022 All rights reserved.
% Authors:      Seonghyeon Jo <cpsc.seonghyeon@gmail.com>
%
% Date:         Feb, 03, 2022
% Last Updated: Feb, 03, 2022
%
% -------------------------------------------------
% get a prescribed perfomance function
%
% -------------------------------------------------
% Equation)
%       rho = (rho_0 - rho_inf)*exp(-beta*t) + rho_inf;
% Input)
%  t        : time
%  beta     : the exponential decay rate of perforamce function rho(t)
%  rho_0    : performance function value for t = 0.
%  rho_inf  : the steady state value of the performance function
%
% Output)
%  rho       : the value of the performance function in time t.
%
% the following code has been tested on Matlab 2021a
function rho = ppf(t, beta, rho_0, rho_inf)
    rho = (rho_0 - rho_inf)*exp(-beta*t) + rho_inf;
end