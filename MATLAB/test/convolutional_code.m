clear; close all;

GlobalVariables;
%%
CodeRate = 3;
InputData = randi([0, 1], 180, 1);

TRACEBACK = 32;
CONV_TRELLIS = poly2trellis(7, [133 171]);
CODE_RATE = 2;

%% convolutional code
% handle_conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS);
% OutputData2 = step(handle_conv, InputData); % MiddleData is convolutional bits

handle_conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS, 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
OutputData = step(handle_conv, InputData); % MiddleData is convolutional bits

%% modulation



%% channel
% OutputData_Rx = awgn(OutputData, 10, 'measured');
OutputData_Rx = OutputData;

%% demodulation

%% convolutional decoder
OutputData_Rx_Pad = [OutputData_Rx; zeros(TRACEBACK * CODE_RATE, 1)]; % OutputData is deconvolutional bits
handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard', 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
ReceivedData = step(handle_viterbi, OutputData_Rx_Pad);
ReceivedData = ReceivedData(TRACEBACK + 1: end - TRACEBACK/2);
% InputData = InputData.'
% ReceivedData = ReceivedData.'

% MiddleError = abs(MiddleData2 - MiddleData1).'
Error = sum(abs(OutputData_Rx - OutputData).')

Error = sum(abs(ReceivedData - InputData).')
