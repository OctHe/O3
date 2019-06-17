clear; close all;

GlobalVariables;

%% local params

TRACEBACK = 4;
CONV_TRELLIS = poly2trellis(7, [133 171]);
CODE_RATE = 2;

%% convolutional code

% rng(1); % generate fixed random numbers
InputData = randi([0, 1], 1000, 1);

handle_conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS);
OutputData = step(handle_conv, InputData);

%% modulation

%% channel

%% demodulation

%% convolutional decoder
OutputData_Rx_Pad = [OutputData; zeros(TRACEBACK * CODE_RATE, 1)]; % OutputData is deconvolutional bits

handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard');
ReceivedData = step(handle_viterbi, OutputData_Rx_Pad);
ReceivedData = ReceivedData(TRACEBACK + 1: end);

Error = sum(xor(OutputData, OutputData).')

Error = sum(xor(ReceivedData, InputData).')
