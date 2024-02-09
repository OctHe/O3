%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Symbol-level frequency domain processing
% Input: [N_DATA + N_PILOT, Nss]
% Output: [N_FFT, Nss]
%
% Copyright (C) 2024  Oct He
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Stream = FreqProcessing(data, sym_type)

global N_FFT N_DATA
global PILOTS
global PILOT_INDEX DATA_INDEX NONZERO_INDEX

Nss = size(data, 2);
Stream = zeros(N_FFT, Nss);

for iss = 1: Nss

    switch (sym_type)
        case 'training'
            Stream(NONZERO_INDEX, iss) = data(:, iss);

        case 'data'
            % Pilot insertion
            Stream(PILOT_INDEX, iss) = PILOTS{Nss}(:, iss);

            % Data insertion
            Stream(DATA_INDEX, iss) = data(:, iss);
    endswitch

    % IFFT
    Stream = sqrt(N_FFT) * ifft(ifftshift(Stream, 1), N_FFT, 1);

end

