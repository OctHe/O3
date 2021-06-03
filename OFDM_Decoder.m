%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   OFDM Decoder, including tail and pad bits, screambler, convelutional
%   encoder, and interleaver.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RawDataBin_Rx = OFDM_Decoder(InterleavedDataBin_Rx, Nbits, MCS_Index)

global MCS_MAT;

Mod = MCS_MAT(1, MCS_Index);
CodeRate = MCS_MAT(2, MCS_Index);

%% Decoding
CodedDataBin_Rx = OFDM_Interleaver(InterleavedDataBin_Rx, log2(Mod), false);

ScrambledDataBin_Rx = OFDM_ConvolutionalCode(CodedDataBin_Rx, CodeRate, false);

RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), ScrambledDataBin_Rx);

%% Remove tail and pad bits
RawDataBin_Rx = RawDataBin_Rx(1: Nbits);


