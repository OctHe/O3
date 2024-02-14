%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot channel model
%
% Copyright (C) 2024 OctHe
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

N = 1000;
BW = 20; % MHz
fc = 2.4e9; % Hz
d = 100; % m
Ntx = 1;
Nrx = 1;
v = 1; % m/s
Ltx = 12; % cm
Lrx = 12; % cm

% Fix the rand seed
rng(10);
Config('legacy');

H = ChannelModel('F', BW, fc, d, Ntx, Ltx, Nrx, Lrx, v);

% tic;
% delta =  zeros(Ntx, N);
% delta(:, 1) = 1 / sqrt(Ntx) * ones(Ntx, 1);
% y = H.channel(delta);
% figure;
% plot((1: N) / BW, 20 * log10(abs(y.')));
% xlabel('Time (us)')
% ylabel('Power (dB)')
% toc;

tic;
u = 1 / sqrt(Ntx) * ones(Ntx, N);
y = H.channel(u);
figure;
plot((1: N) / BW, 10 * log10(abs(y.')));
xlabel('Time (us)')
ylabel('Amplitude (dB)')
toc;
