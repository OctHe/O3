a = repmat([0; 1], 32, 1); 
a = exp(1j * pi * a);

X = [zeros(6, 1); ones(52, 1); zeros(6, 1)];
x = fft(fftshift(X));

Y = a .* X;
y = fft(fftshift(Y));
alpha = y ./ x;

x1 = x .* abs(alpha);
x1(33) = 0;
x1(17) = 0;
x1(49) = 0;

X1 = fftshift(fft(x1));
