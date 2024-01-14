%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Randam AoA/AoD generation.
% Reference: IEEE 802.11n Indoor MIMO WLAN Channel Models
%
% Copyright (C) 2024  Shiyue He (hsy1995313@gmail.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function space_angle = rand_space_angle(angle_mean, angle_spread, N)
  
    if nargin == 2
        N = 1;
    endif

    p = rand(N, 1);
    space_angle = angle_mean - angle_spread * sign(p - 0.5) .* log(1 - 2 * abs(p - 0.5));

endfunction
