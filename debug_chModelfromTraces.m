%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Trace-driven simulation for IEEE 802.11ac rate adaptation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% Waveform configuration


%% Simulation parameters
byte2Bits = 8;
numPackets = 100;                       % Number of packets transmitted during the simulation 
snr = 10;
sampRate = wlanSampleRate(cfgVHT);      % Sample rate in Hertz

DEBUG = false;

%% Channel model from collected traces
csi = chModelfromTraces('/home/shiyue_deep/Desktop/csi.mat');

