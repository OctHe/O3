function Payload_t = OFDM_Modulation(BinData, MOD_ORDER)
% column vector; scalar
% column vector

global SC_IND_PILOTS SC_IND_DATA N_SC PILOTS SC_DATA_NUM
global DEBUG
GlobalVariables;
%% Params
DataNum = length(BinData) / log2(MOD_ORDER);
SymbolNum = DataNum / SC_DATA_NUM;

%% BPSK, QPSK, 16QAM, 64QAM modulator
switch MOD_ORDER
    case 2
        ModDataTX = step(comm.BPSKModulator, BinData);
    case 4
        ModDataTX = step(comm.QPSKModulator('BitInput', true), BinData);
    case 16
        ModDataTX = (1/sqrt(10)) * step(comm.RectangularQAMModulator('BitInput', true), BinData);
    case 64
        ModDataTX = (1/sqrt(43)) * step(comm.RectangularQAMModulator('ModulationOrder', 64, 'BitInput', true) , BinData);
    otherwise
        error('Invalid MOD_ORDER!  Must be in [2, 4, 16, 64]\n');
end

%% OFDM Modulator
ModDataTX = reshape(ModDataTX, SC_DATA_NUM, SymbolNum);
Payload_f = zeros(N_SC, SymbolNum);

Payload_f(SC_IND_PILOTS, :) = repmat(PILOTS, 1, SymbolNum);
Payload_f(SC_IND_DATA, :) = ModDataTX;
if DEBUG
    figure();
    plot(abs(Payload_f));
    title('Payload Tx');
end
Payload_t = ifft(Payload_f, N_SC, 1);
Payload_t = reshape(ifft(Payload_f, N_SC, 1), [], 1);