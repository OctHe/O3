function [Responses, CSI_mW, SNRs_mW, TracesNums] = ReadTraces(FileName)
% Read traces from a specific H5 file

global N_SC N_CP 
global TONES_INDEX
global DEBUG

GlobalVariables;


%% Read from file

ReCSI = h5read(FileName, '/ReCSI_linear');
ImCSI = h5read(FileName, '/ImCSI_linear');
SNRs_mW = h5read(FileName, '/SNRs_mW');

CSI_mW_nonzeros = ReCSI + 1j * ImCSI; % index: [0: 31, -32: -1]

CSI_mW = zeros(size(CSI_mW_nonzeros));
CSI_mW(TONES_INDEX, :) = CSI_mW_nonzeros(TONES_INDEX, :);

Responses = ifft(CSI_mW, N_SC, 1);

if DEBUG
    figure;
    plot(abs(CSI_mW(:, 1)));
    title('CSI abs, mW');
    figure;
    plot(angle(CSI_mW(:, 1)));
    title('CSI angle');
    figure;
    plot(abs(Responses(:, 1)));
    title('channel responses abs');
end

% truncation the tail > N_CP
% Responses = Responses(1: N_CP, :);

TracesNums = size(Responses, 2);
