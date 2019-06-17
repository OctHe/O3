clear; close all;

%% Global params
global N_SC
GlobalVariables;

%% Local Params
MOD_ORDER               = 16;            % Modulation order (2/4/16/64 = BSPK/QPSK/16-QAM/64-QAM)
DATA_NUM                = 48;       % the minimum data number is 48 * 6 to compatible with the rate 2/3 and 3/4
Code_Rate               = 2;            % 2(1/2); 3(2/3); 4(3/4)

MOD_ORDER_Map = [2, 2, 4, 4, 16, 16, 64, 64];
Code_Rate_Map = [2, 4, 2, 4, 2, 4, 3, 4];

%% Transmitter pipeline
% rng(10); % generate fixed random numbers
TX_RawData = randi([0, MOD_ORDER - 1], DATA_NUM, 1); % randam raw datas
TX_RawBits = Dec2BinVector(TX_RawData, log2(MOD_ORDER));

% TX_ScrambledBit = step(comm.Scrambler('CalculationBase', 2,'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), TX_RawBits);

TX_CodedBits = OFDM_ConvolutionalCoder(TX_RawBits, Code_Rate, true);

% TX_InterleavedBits = OFDM_Interleaver(TX_CodedBits, log2(MOD_ORDER), true);

TX_OFDM_Symbol_t = OFDM_Modulation(TX_CodedBits, MOD_ORDER);

%% The phase shift at the time domain

RX_OFDM_Symbol_t = TX_OFDM_Symbol_t * exp(1j * pi / 2);

%% Receiver pipeline
RX_OFDM_Symbol_f = fft(reshape(RX_OFDM_Symbol_t, N_SC, []), N_SC, 1);

RX_CodedBits = OFDM_Demodulation(RX_OFDM_Symbol_f, MOD_ORDER);

% RX_CodedBits = OFDM_Interleaver(RX_InterleavedBits, log2(MOD_ORDER), false);

RX_RawBits = OFDM_ConvolutionalCoder(RX_CodedBits, Code_Rate, false);

% RX_RawBits = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RX_ScrambledBits);

%% Regenerate coded bits

ReRX_CodedBits = OFDM_ConvolutionalCoder(RX_RawBits, Code_Rate, true);

%% Transmission Result
% Bits number
RawBitsNum = length(TX_RawBits);
CodedBitsNum = length(TX_CodedBits);

% Error bits
% InterleavedErrorBits = xor(TX_InterleavedBits, RX_InterleavedBits); % before the deinterleaver
UncodedErrorBits = xor(TX_CodedBits, RX_CodedBits);     % after the deinterleaver and before the convolutional decoder
ReUncodedErrorBits = xor(TX_CodedBits, ReRX_CodedBits);
% ScrambledErrorBits = xor(TX_ScrambledBits, RX_ScrambledBits);   % after the convolutional decoder and before the descreambler
CodedErrorBits = xor(TX_RawBits, RX_RawBits);           % after descreambler

% bit to symbol
SourceSymbol = BinVector2Dec(TX_CodedBits, log2(MOD_ORDER));
ReflectSymbol = BinVector2Dec(RX_CodedBits, log2(MOD_ORDER));

DecodedTagBits = [SourceSymbol, ReflectSymbol];

RegeneratedSymbol = BinVector2Dec(ReRX_CodedBits, log2(MOD_ORDER));

% Extract Phase shift
CodedErrorBits_reshape = reshape(CodedErrorBits, 4, []);
CodedErrorBits_reshape = CodedErrorBits_reshape(1: 2: 4, :);

% BER
UncodedBER = sum(UncodedErrorBits) / CodedBitsNum;
ReUncodedBER = sum(ReUncodedErrorBits) / CodedBitsNum;
CodedBER = sum(CodedErrorBits) / RawBitsNum;

disp(['transmit bits: ' num2str(RawBitsNum)])
disp(['BER without convolutional decode: ' num2str(UncodedBER)])
% disp(['Error nums after covolutional decoder ' num2str(CodedErrorBitsNums)])
disp(['BER with covolutional decode ' num2str(ReUncodedBER)])
disp(['BER after covolutional decoder ' num2str(CodedBER)])
disp(['Difference of two parts ' num2str(sum(xor(UncodedErrorBits, ReUncodedErrorBits)) / CodedBitsNum)])
