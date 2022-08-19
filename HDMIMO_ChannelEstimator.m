%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel Estimation for HD-MIMO model
% DLTFrx: column vector
% Ntxs: TX uses
% Ntags: Tag uses
% Nrxs: RX APs
% CSI: column vector
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
function [D_CSI, R_CSI] = HDMIMO_ChannelEstimator(RxHDLTF, Ntxs, Ntags)

global N_CP N_FFT TONE_INDEX

Nsym = (Ntags +1) * Ntxs;
Nrxs = size(RxHDLTF, 2);

D_CSI = zeros(N_FFT, Nrxs, Ntxs);
R_CSI = zeros(N_FFT, Nrxs, Ntxs, Ntags);

%% RX Preambles
RxHDLTF_f = zeros(N_FFT, Nrxs, Nsym);
for irx = 1: Nrxs
for isym = 1: Nsym
    RxHDLTF_f(:, irx, isym) = ...
        RxHDLTF((isym -1) * (N_CP + N_FFT) + N_CP +1: isym * (N_CP + N_FFT), irx);
    RxHDLTF_f(:, irx, isym) = ...
        fftshift(1 / sqrt(N_FFT) * fft(RxHDLTF_f(:, irx, isym)));
end
end

%% TX Preambles
[~,  ~, TxHDLTF, BTF] = HDMIMO_PreambleGenerator(Ntxs, Ntags); 

TxHDLTF_f = zeros(N_FFT, Ntxs, Nsym);
for itx = 1: Ntxs
for isym = 1: Nsym
    TxHDLTF_f(:, itx, isym) = ...
        TxHDLTF((isym -1) * (N_CP + N_FFT) + N_CP +1: isym * (N_CP + N_FFT), itx);
    TxHDLTF_f(:, itx, isym) = ...
        fftshift(1 / sqrt(N_FFT) * fft(TxHDLTF_f(:, itx, isym)));
end
end

TxDLTF_f = TxHDLTF_f(:, :, 1: Ntxs);
ReflectBTF = BTF(Ntxs +1: Ntxs: end, :);

%% Direct Channel Estimation
RxDirectHDLTF_f = RxHDLTF_f(:, :, 1: Ntxs *2);
for fft_index = TONE_INDEX
    D_CSI(fft_index, :, :) = ( ...
        reshape( ...
        reshape(RxDirectHDLTF_f(fft_index, :, 1: Ntxs), Nrxs, Ntxs) / ...
        reshape(TxDLTF_f(fft_index, :, :), Ntxs, Ntxs), ...
        1, Nrxs, Ntxs) + ...
        reshape( ...
        reshape(RxDirectHDLTF_f(fft_index, :, Ntxs +1: Ntxs *2), Nrxs, Ntxs) / ...
        reshape(TxDLTF_f(fft_index, :, :), Ntxs, Ntxs), ...
        1, Nrxs, Ntxs)) / 2;
end

%% Cascade Channel Estimation
RxReflectHDLTF_f = RxHDLTF_f(:, :, Ntxs +1: end);   % (N_FFT x Nrxs x (Ntags x Ntxs))

for fft_index = TONE_INDEX
    
    HbXHf = zeros(Nrxs * Ntxs, Ntags);
    for itag = 1: Ntags
        HbXHf(:, itag) = reshape( ...
        reshape(RxReflectHDLTF_f(fft_index, :, (itag -1) * Ntxs +1: itag * Ntxs), Nrxs, Ntxs) / ...
        reshape(TxDLTF_f(fft_index, :, :), Ntxs, Ntxs) - ...
        reshape(D_CSI(fft_index, :, :), Nrxs, Ntxs), ...
        Nrxs * Ntxs, 1);
    end
    R_CSI(fft_index, :, :, :) = reshape(HbXHf / ReflectBTF, Nrxs, Ntxs, Ntags);
end
