%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BLE modulator with Gaussian frequency shift keying (FSK)
% This function uses minimum shift keying (MSK) MSK to introduce the theory
% Bits: Input bits
% SamplesPerSymbol: Samples in one symbol
% Sensitivity: sensitivity = deviation / fs
% ModData: Modulated data
%
% Copyright (C) 2022  Shiyue He (hsy1995313@gmail.com)
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
function ModData = BLE_Modulator(Bits, SamplesPerSymbol, Sensitivity)

Nbits = size(Bits, 1);

NRZ = Bits * 2 -1;

Samples = reshape(repmat(NRZ, 1, SamplesPerSymbol).', [], 1);

Phase = zeros(Nbits * SamplesPerSymbol, 1);
% Phase(1) == 0, so we start at the 2nd index
for index = 2: Nbits * SamplesPerSymbol
    Phase(index) = Phase(index -1) + Sensitivity * Samples(index -1);
end

ModData = exp(1j * (Phase));
