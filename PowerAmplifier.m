function SignalAir = PowerAmplifier(Signal, Power_dBm)
% signal: vector; Power: scalar (dBm);
% powered signal

SignalPower = sum(abs(Signal).^2)/length(Signal); 

Power = 10^(Power_dBm / 10);

SignalAir = Signal * sqrt(Power / SignalPower);