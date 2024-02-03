%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot channel model
%
% Copyright (C) 2024  Shiyue He (hsy1995313@gmail.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

N = 100;
BW = 20; % MHz
fc = 2.4e9; % Hz
d = 100; % m
Ntx = 1;
Nrx = 1;
v = 1; % m/s
Ltx = 12; % cm
Lrx = 12; % cm

tic;
H = ChannelModel('B', BW, fc, d, Ntx, Ltx, Nrx, Lrx, v);

x =  zeros(Ntx, N);
x(:, 1) = 1 / sqrt(Ntx) * ones(Ntx, 1);
y = H.channel(x);
t = toc;
t
figure;
plot((1: N) / BW, 20 * log10(abs(y.')));
xlabel('Time (us)')
ylabel('Power (dB)')

