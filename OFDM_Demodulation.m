function RawDataRX_Bin = OFDM_Demodulation(Payload_RX_f, MOD_ORDER)
% Matrix (N_SC, SymbolNum); scalar
% column vector

%% Params
global SC_IND_DATA
global DEBUG

%% OFDM Demod

Demod_Data = Payload_RX_f(SC_IND_DATA, :);

Demod_Data = reshape(Demod_Data, [], 1);

%% BPSK demod
switch MOD_ORDER
    case 2
        RawDataRX = step(comm.BPSKDemodulator, Demod_Data);
    case 4
        RawDataRX = step(comm.QPSKDemodulator, Demod_Data);
    case 16
        RawDataRX = step(comm.RectangularQAMDemodulator, sqrt(10) * Demod_Data);
    case 64
        RawDataRX = step(comm.RectangularQAMDemodulator(64), sqrt(43) * Demod_Data);
    otherwise
        error('Invalid MOD_ORDER!  Must be in [2, 4, 16, 64]\n');
end

RawDataRX_Bin = Dec2BinVector(RawDataRX, log2(MOD_ORDER));