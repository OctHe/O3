function DecData = BinVector2Dec(BinData, BinLen)
% vector; scalar
% vector

[~, n] = size(BinData);
if n ~= 1
    error('The first paramter must be a column vector!')
end

BinData = reshape(BinData, BinLen, []).';

DecData = zeros(size(BinData, 1), 1);

for BinIndex = BinLen: -1: 1
    DecData = DecData + BinData(:, BinIndex) * 2 ^ (BinLen - BinIndex);
end