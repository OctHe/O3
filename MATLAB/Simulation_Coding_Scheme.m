clear; close all;

%% Global params
global N_SC
GlobalVariables;

%% Local Params
MOD_ORDER               = 4;            % Modulation order (2/4/16/64 = BSPK/QPSK/16-QAM/64-QAM)
DATA_NUM                = 48 * 6;       % the minimum data number is 48 * 6 to compatible with the rate 2/3 and 3/4
Code_Rate               = 2;            % 2(1/2); 3(2/3); 4(3/4)

MOD_ORDER_Map = [2, 2, 4, 4, 16, 16, 64, 64];
Code_Rate_Map = [2, 4, 2, 4, 2, 4, 3, 4];

%% Transmitter pipeline
TX_RawData = randi([0, MOD_ORDER - 1], DATA_NUM, 1); % randam raw datas
TX_RawDataBin = Dec2BinVector(TX_RawData, log2(MOD_ORDER));

TX_ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2,'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), TX_RawDataBin);

TX_CodedDataBin = OFDM_ConvolutionalCoder(TX_ScrambledDataBin, Code_Rate, true);

TX_InterleavedDataBin = OFDM_Interleaver(TX_CodedDataBin, log2(MOD_ORDER), true);

TX_OFDM_Symbol_t = OFDM_Modulation(TX_InterleavedDataBin, MOD_ORDER);

%% The phase shift at the time domain

RX_OFDM_Symbol_t = TX_OFDM_Symbol_t * exp(1j * pi);

%% Receiver pipeline
RX_OFDM_Symbol_f = fft(reshape(RX_OFDM_Symbol_t, N_SC, []), N_SC, 1);

RX_InterleavedDataBin = OFDM_Demodulation(RX_OFDM_Symbol_f, MOD_ORDER);

RX_CodedDataBin = OFDM_Interleaver(RX_InterleavedDataBin, log2(MOD_ORDER), false);

RX_ScrambledDataBin = OFDM_ConvolutionalCoder(RX_CodedDataBin, Code_Rate, false);

RX_RawDataBin = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RX_ScrambledDataBin);

%% Transmission Result
BinDataNums = length(TX_RawDataBin);
UncodedDataNums = length(TX_InterleavedDataBin);
UncodedErrorBitsNums = sum(abs(RX_CodedDataBin - TX_CodedDataBin));
CodedErrorBitsNums = sum(abs(RX_RawDataBin - TX_RawDataBin));
UncodedBER = UncodedErrorBitsNums / UncodedDataNums;
CodedBER = CodedErrorBitsNums / BinDataNums;

disp(['transmit bits: ' num2str(BinDataNums)])
disp(['BER without convolutional code: ' num2str(UncodedBER)])
% disp(['Error nums after covolutional decoder ' num2str(CodedErrorBitsNums)])
disp(['BER after covolutional decoder ' num2str(CodedBER)])

