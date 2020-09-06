function OutputData = OFDM_Interleaver(InputData, Nbpsc, sign)
% column vector; 
% Nbpsc: number of coded bits per subcarrier;
% sign = true means add cp, sign = false means remove cp;
% column vector with cp;

global SC_DATA_NUM

%%
Ncbps = SC_DATA_NUM * Nbpsc;
SymbolNum = length(InputData) / Ncbps;
InputData = reshape(InputData, Ncbps, SymbolNum);

OutputData = zeros(size(InputData));

%%
InputIndex = (0: Ncbps - 1).';
s = max(Nbpsc / 2, 1);

if sign == true
    MiddleIndex = floor(Ncbps / 16) * mod(InputIndex, 16) + floor(InputIndex / 16);
    OutputIndex = s * floor(MiddleIndex / s) + mod(MiddleIndex + Ncbps - floor(16 * MiddleIndex / Ncbps), s);
elseif sign == false
    MiddleIndex = s * floor(InputIndex / s) + mod(InputIndex + floor(16 * InputIndex / Ncbps), s);
    OutputIndex = 16 * MiddleIndex - (Ncbps - 1) * floor(16 * MiddleIndex / Ncbps);
else
    error('ERROR: sign must be true or false!');
end
for index = 1: Ncbps
    OutputData(OutputIndex(index) + 1, :) = InputData(InputIndex(index) + 1, :);
end
OutputData = reshape(OutputData, [], 1);