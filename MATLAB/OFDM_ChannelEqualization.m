function Payload_RX_f = OFDM_ChannelEqualization(Payload_RX_t, CSI)
% Matrix, (N_SC, SymbolNum); vector; 
% Matrix, (SC_DATA_NUM, SymbolNum)


global N_SC GUARD_SC_INDEX
global DEBUG
GlobalVariables;

[~, SymbolNum] = size(Payload_RX_t);

Payload_RX_f = fft(Payload_RX_t, N_SC, 1) ./ repmat(CSI, 1, SymbolNum);

Payload_RX_f(GUARD_SC_INDEX, :) = zeros(length(GUARD_SC_INDEX), SymbolNum);
