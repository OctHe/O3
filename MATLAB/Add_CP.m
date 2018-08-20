function OutputData = Add_CP(InputData, sign)
% column vector; sign = true means add cp, sign = false means remove cp
% column vector with cp


global N_SC N_CP
% GlobalVariables;

if sign == true
    SymbolNum = length(InputData) / N_SC;

    InputData = reshape(InputData, N_SC, SymbolNum);

    OutputData = [InputData(N_SC - N_CP +1: N_SC, :); InputData];
    
    OutputData = reshape(OutputData, [], 1);
elseif sign == false
    SymbolNum = length(InputData) / (N_CP + N_SC);

    InputData = reshape(InputData, N_CP + N_SC, SymbolNum);

    OutputData = InputData(N_CP + 1: end, :);
    
else
    error('ERROR: sign must be true or false!');
end