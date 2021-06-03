%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   OFDM Encoder, including tail and pad bits, screambler, convelutional
%   encoder, and interleaver.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [InterleavedDataBin, N_sym_pld] = OFDM_Encoder(RawBits, MCS_Index)

global TAIL_LEN SC_DATA_NUM CODE_RATE MCS_MAT;

Mod = MCS_MAT(1, MCS_Index);
CodeRate = MCS_MAT(2, MCS_Index);

%% Add TAIL bits and PAD bits
Ndbs = SC_DATA_NUM * log2(Mod) * CODE_RATE(MCS_Index);    % Number of coded bits per symbol
RawBits = [RawBits; zeros(TAIL_LEN, 1)];

N_PAD = Ndbs - mod(length(RawBits), Ndbs);
RawBits = [RawBits; zeros(N_PAD, 1)];

N_sym_pld = length(RawBits) / Ndbs;

%% Encoding
ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RawBits);

CodedDataBin = OFDM_ConvolutionalCode(ScrambledDataBin, CodeRate, true);

InterleavedDataBin = OFDM_Interleaver(CodedDataBin, log2(Mod), true);

