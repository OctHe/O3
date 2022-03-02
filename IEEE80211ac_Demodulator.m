%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Demodulation process
% Data: (N_FFT * Nsym) x Ntxs matrix in time domain
% MCS_Index: scalar, refer to IEEE 802.11ac
% Payload_t: column vector
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
function ModDataRX = IEEE80211ac_Demodulator(Payload_t)

global N_FFT N_DATA
global DATA_INDEX

Nsym = size(Payload_t, 1) / N_FFT;
Nrxs = size(Payload_t, 2);

%% OFDM demodulator
ModDataRX = zeros(N_DATA * Nsym, Nrxs);
for itx = 1: Nrxs
    
    Payload_t_i = reshape(Payload_t(:, itx), N_FFT, Nsym);
    
    Payload_f_i = fftshift(fft(Payload_t_i, N_FFT, 1), 1);
    ModDataRX(:, itx) = reshape(Payload_f_i(DATA_INDEX, :), [], 1);

end

