%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% input: vector, scalar; output: vector
% 
% Copyright (C) 2017  Shiyue He (hsy1995313@gmail.com)
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DecData = BinVector2Dec(BinData, BinLen)

[~, n] = size(BinData);
if n ~= 1
    error('The first paramter must be a column vector!')
end

BinData = reshape(BinData, BinLen, []).';

DecData = zeros(size(BinData, 1), 1);

for BinIndex = BinLen: -1: 1
    DecData = DecData + BinData(:, BinIndex) * 2 ^ (BinLen - BinIndex);
end