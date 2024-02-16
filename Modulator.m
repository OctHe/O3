%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Symbol-level QAM and OFDM modulation
% Input: [N_DATA + N_PILOT, Nss]
% Output: [N_FFT, Nss]
%
% Copyright (C) 2024  Oct He
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Symbol_t = Modulator(data, sym_type)

global N_FFT N_CP N_LLTF N_DATA
global PILOTS
global PILOT_INDEX DATA_INDEX NONZERO_INDEX

Nss = size(data, 2);
Stream = zeros(N_FFT, Nss);

for iss = 1: Nss

    switch (sym_type)
        case 'training'
            Stream(NONZERO_INDEX, iss) = data(:, iss);

            Symbol_t = zeros(N_LLTF, Nss);

            % IFFT
            Symbol_t(end - N_FFT +1: end, :) = sqrt(N_FFT) * ifft(ifftshift(Stream, 1), N_FFT, 1);

            % LSTF and LLTF
            Symbol_t(end - N_FFT*2 +1: end - N_FFT, :) = Symbol_t(end - N_FFT +1: end, :);
            Symbol_t(1: N_CP *2, :) = Symbol_t(end - 2 * N_CP +1: end, :);

        case 'data'

            % Pilot
            Stream(PILOT_INDEX, iss) = PILOTS{Nss}(:, iss);

            % Data
            Stream(DATA_INDEX, iss) = data(:, iss);

            % IFFT
            Stream = sqrt(N_FFT) * ifft(ifftshift(Stream, 1), N_FFT, 1);

    endswitch


end

