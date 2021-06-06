function [STF_t, LTF_t] = PreambleGenerator
% no input
% STF_t, (N_CP + N_CP + N_SC + N_SC, 1);
% LTF_t, (N_CP + N_CP + N_SC + N_SC, 1);


global N_SC ShortTrainingSymbol LongTrainingSymbol TONES_INDEX

ShortPreamble_f = zeros(N_SC, 1);
LongPreamble_f = zeros(N_SC, 1);

ShortPreamble_f(TONES_INDEX) = ShortTrainingSymbol;
LongPreamble_f(TONES_INDEX) = LongTrainingSymbol;

ShortPreamble_t = ifft(ShortPreamble_f);
LongPreamble_t = ifft(LongPreamble_f);

STF_t = [ShortPreamble_t(N_SC/2+1: N_SC); ShortPreamble_t; ShortPreamble_t];
LTF_t = [LongPreamble_t(N_SC/2+1: N_SC); LongPreamble_t; LongPreamble_t];