function SignalAir = PowerAmplitude(Signal, Power)
% signal: vector; Power: scalar, unit is uW;
% powered signal

SignalPower = sum(abs(Signal).^2)/length(Signal); 

SignalAir = Signal * sqrt(Power / SignalPower);