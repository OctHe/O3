%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Modulation process
% Data: (N_FFT * Nsym) x Ntxs matrix in frequency domain
% Payload_t: column vector
%
% Copyright (C) 2022-2023  Shiyue He (hsy1995313@gmail.com)
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
function Payload_t = OFDM_Modulator(ModDataTX)

global N_CP N_FFT N_DATA
global PILOTS
global PILOT_INDEX DATA_INDEX

Nsym = size(ModDataTX, 1) / N_DATA;
Ntxs = size(ModDataTX, 2);

%% OFDM modulator
Payload_t = zeros((N_CP + N_FFT) * Nsym, Ntxs);
Payload_f_itx = zeros(N_FFT, Nsym);
for itx = 1: Ntxs

    % Pilot insertion
    Payload_f_itx(PILOT_INDEX, :) = repmat(PILOTS{Ntxs}(:, itx), 1, Nsym);

    % Data insertion
    Payload_f_itx(DATA_INDEX, :) = reshape(ModDataTX(:, itx), N_DATA, Nsym);

    % IFFT
    Payload_t_itx = sqrt(N_FFT) * ifft(fftshift(Payload_f_itx, 1), N_FFT, 1);

    % CP addition
    Payload_t(:, itx) = reshape([Payload_t_itx(end-N_CP+1: end, :); Payload_t_itx], [], 1);
end

