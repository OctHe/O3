function [CSIs_linear, SNRs_mW] = RawCSI2CSI(RawCSIs, SNRs_dBm)
% the CSIs measured from a device are usually don't unit
% this function change the unit of the CSI and the SNR to mW. 
% RawCSI: N_SC * Nums, no unit; SNR_dBm: Nums * 1, unit is dBm;
% CSI_linear, SNR_mW

global N_SC N_CP
global DEBUG

SNR_Nums = size(SNRs_dBm, 1);

SNRs_mW = 10 .^ (SNRs_dBm / 10); % formula of the dBm to mW

CSIPhases = angle(RawCSIs);

CSIs_mW = zeros(N_SC, SNR_Nums);
for index = 1: SNR_Nums
    CSIs_mW(:, index) = sqrt(N_SC) * abs(RawCSIs(:, index)) / norm(RawCSIs(:, index), 2) * SNRs_mW(index);
end

CSIs_linear = sqrt(CSIs_mW) .* exp(1j * CSIPhases);