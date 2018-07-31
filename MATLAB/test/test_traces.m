%% test traces
clear; close all;

%% read traces

CSIre = h5read('./RawData/new_data2.h5', '/CSI_Re');
CSIim = h5read('./RawData/new_data2.h5', '/CSI_Im');
SNR = h5read('./RawData/new_data2.h5', '/SNR');

CSITraces = CSIre + 1j * CSIim; % index: [0: 31, -32: -1]
RawCSITrace = CSITraces(:, 1);

RawResponse = ifft(RawCSITrace, 64, 1);

offset = 6;
Response = zeros(64, 1);
Response(1: offset) = RawResponse(64 - offset + 1: 64);
Response(offset+1: 64) = RawResponse(1: 64 - offset);

Response = Response(1: 16);

figure;
plot(abs(Response(:, 1)));

CSITrace = fft(Response, 64, 1);

% figure; hold on;
% plot(abs(CSITrace));
% plot(abs(RawCSITrace));
% 
% figure; hold on;
% plot(angle(CSITrace));
% plot(angle(RawCSITrace));

%% the OFDM symbol with CP
FFTLen = 64;
N_CP = 16;

Nums = 10;

% TxBits = ones(FFTLen, Nums);
TxBits = randi([0, 1], FFTLen, Nums) * 2 - 1;


ModBits = ifft(TxBits, FFTLen, 1);

CPModBits = [ModBits(FFTLen - N_CP + 1: FFTLen, :); ModBits];

CPModBits = reshape(CPModBits, [], 1);


CPDemodBits = conv(CPModBits, Response);
CPDemodBits = CPDemodBits(1: end - length(Response) + 1);

CPDemodBits = reshape(CPDemodBits, FFTLen + N_CP, Nums);

CPDemodBits = CPDemodBits(N_CP + 1: FFTLen + N_CP, :);

RxBits = fft(CPDemodBits, FFTLen, 1);

RxChannel = RxBits ./ TxBits;

%% figures
figure; hold on;
% plot(abs(CSITrace));
plot(abs(RxChannel));
figure; hold on;
% plot(angle(CSITrace));
plot(angle(RxChannel));


