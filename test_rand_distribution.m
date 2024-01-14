%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the randam distributions
%
% Copyright (C) 2024  Shiyue He (hsy1995313@gmail.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 1000;
v = 10; % m/s
f0 = 5e9; % Hz

fd = zeros(N, 1);
for n = 1: N
  fd(n) = rand_Doppler(v, f0);
endfor
space_angle = rand_space_angle(20, 20, N);

figure;
plot(fd);

