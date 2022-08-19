%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Received power estimation from CSI for OFDM system
% CSI: N_FFT x Nrxs x Ntxs
% SNR: Ntxs x 1
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
function RxPower = OFDM_RxPowerEstimation(CSI)

global PILOT_INDEX N_PILOT

Nrxs = size(CSI, 2);
Ntxs = size(CSI, 3);

RxPower = zeros(Ntxs, 1);

for itx = 1: Ntxs
    for irx = 1: Nrxs
        RxPower = RxPower + CSI(PILOT_INDEX, irx, itx)' * CSI(PILOT_INDEX, irx, itx);
    end
    RxPower(itx) = 10 * log10(RxPower / N_PILOT);
end