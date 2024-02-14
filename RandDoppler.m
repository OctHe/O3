%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Randam Doppler generation.
% Reference: IEEE 802.11n Indoor MIMO WLAN Channel Models
%
% Copyright (C) 2024 OctHe
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f = RandDoppler(v, f0)

    global c

    A = 9; % Coefficient of Doppler spread distribution

    fd = v / c * f0;

    do
        f = fd * (rand() - 0.5);
        S = sqrt(A) / (pi * fd) / (1 + A * (f / fd)^2);
        S = 10^(S / 20);
        y_max = sqrt(A) / (pi * fd);
        y_max = 10^(y_max / 20);
        y_min = sqrt(A) / (pi * fd) / (1 + A);
        y_min = 10^(y_min / 20);
        y = (y_max - y_min) * rand() + y_min;
    until y <= S

endfunction
