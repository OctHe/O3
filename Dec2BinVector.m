function BinData = Dec2BinVector(DecData, BinLen)
% vector; scalar
% vector

[~, n] = size(DecData);
if n ~= 1
    error('The first paramter must be a column vector!')
end

BinData = zeros(BinLen, size(DecData, 1));
for k = 1: BinLen
    BinData(BinLen + 1 - k, :) = mod(DecData, 2);
    DecData = floor(DecData / 2);
end
BinData = reshape(BinData, [], 1);
