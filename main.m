%%
clc
clear 
close

% Load sound
[y, fs] = audioread("airplane_1s.wav");
%sound(y, fs);
ts = 1:length(y);
ts = ts ./ fs;
plot(ts, y);
xlabel('Time(s)');
%saveas(gcf, sprintf("Figs/plane_5s.png"));

fft_N = 8192;
freqz_N = fft_N/2;

%%Fourier Transform of the short audio
X = fft(y, fft_N);
X = X(1:fft_N/2);
fft_N = fft_N/2;

f_axis = 0: 1/freqz_N: 1-1/freqz_N;
f_axis = (f_axis*fs)/2;
%% Velvet noise
[velvet] = getVelvet(10.0, fs);
%plot(velvet);
%% Method 3, the lovely FFT and iFFT.
% zero-pad to 10s
sec = 10.0;
y = reshape(y, [1, length(y)]);
zz = zeros([1, sec*fs-length(y)]);
y_pad = cat(2, y, zz);
y_pad_length = length(y_pad);
Y_pad = fft(y_pad);
%plot(abs(Y_pad));

r = pi*2*(rand([1, y_pad_length/2-1])-0.5);
r_tilt = -1.0*flip(r);
phase = cat(2, 0, r, 0, r_tilt);
% Mag + random phase
nY_pad = abs(Y_pad).*exp(1j*phase);

ny_pad = ifft(nY_pad);
ny_pad = ny_pad / max(ny_pad);

filename = sprintf("audios/fft_%ds.wav", sec);
%audiowrite(filename, ny_pad, fs);

% Plot the synth audio
NY_pad = fft(ny_pad, 8192);
NY_pad = NY_pad(1:8192/2);
figure;
plot(f_axis,mag2db(abs(NY_pad)))

set(gca,'XScale','log')
xlim([min(f_axis), max(f_axis)]);
ylim([-40, 80]);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on
%saveas(gcf, sprintf("Figs/fft_mag.png"));

% cat to 60sec
ny_cat = cat(2, ny_pad, ny_pad, ny_pad, ny_pad, ny_pad, ny_pad);
filename = sprintf("audios/fft_%ds.wav", sec*6);
audiowrite(filename, ny_cat, fs);

startP = length(ny_pad) - 20;
endP = length(ny_pad) + 20;
trim = ny_cat(startP:endP);
figure;
stem(startP:endP, trim);
hold on;
stem(length(ny_pad), ny_cat(length(ny_pad)), 'r');
xlabel("Samples");
%saveas(gcf, sprintf("Figs/fft_circ.png"));

disp("stop");
return

%% Method 1, LPC filter
for order = [100, 1000, 10000]
    b = [1.0];
    [as, gs] = lpc(y, order);
    [h, w] = freqz(b, as, freqz_N);
    
    figure;
    [h_ir, t] = impz(b, as, fs/3);
    plot(t/fs, h_ir);
    xlabel('Time(s)');
    ylim([-1.5, 3.0]);
    %saveas(gcf, sprintf("Figs/lpc_%d_IR.png", order));

    figure;
    % Convert pi*rad/sample to Hz
    f_axis = 0: 1/freqz_N: 1-1/freqz_N;
    f_axis = (f_axis*fs)/2;

    p_original = plot(f_axis,mag2db(abs(X)));
    p_original.Color(4) = 0.5;
    hold on;
    p_lp = plot(f_axis, mag2db(abs(h)), 'LineWidth',1.0);
    p_lp.Color(4) = 1.0;
    legend('Original',sprintf("P=%d", order));

    set(gca,'XScale','log')
    xlim([min(f_axis), max(f_axis)]);
    ylim([-40, 80]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    %title(sprintf('Magnitude Response, order=%d', order));
    grid on
    %saveas(gcf, sprintf("Figs/lpc_%d_mag.png", order));
    
    % White noise
    sec = 10.0;
    wn = 2*(rand([1, fs*sec])-0.5);
    tic;
    y_out = filter(b, as, wn);
    elapsed = toc;
    fprintf("max:%f", max(y_out));
    return;
    fprintf("wn elapsed:%f\n", elapsed);
    y_out = y_out / max(y_out);
    filename = sprintf("audios/lpc_p_%d.wav", order);
    
    figure;
    y_plot = y_out(1:fs*5.0);
    ts = 1:length(y_plot);
    ts = ts ./ fs;
    plot(ts, y_plot);
    xlabel('Time(s)');
    %saveas(gcf, sprintf("Figs/lpc_%d_filtered.png", order));
    audiowrite(filename, y_out, fs);
    
    % Mag of the white noise
    Y_out = fft(y_out, 8192);
    Y_out = Y_out(1:8192/2);
    plot(f_axis,mag2db(abs(Y_out)))
    
    set(gca,'XScale','log')
    xlim([min(f_axis), max(f_axis)]);
    ylim([-40, 80]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    grid on
    %saveas(gcf, sprintf("Figs/lpc_%d_filtered_mag.png", order));
    
    % Velvet noise
    %[velvet] = getVelvet(sec, fs);
    tic;
    y_vel = filter(b, as, velvet);
    elapsed = toc;
    fprintf("velvet elapsed:%f\n", elapsed);
    y_vel = y_vel / max(y_vel);
    filename = sprintf("audios/lpc_p_%d_velvet.wav", order);
    
    figure;
    y_plot = y_vel(1:fs*5.0);
    ts = 1:length(y_plot);
    ts = ts ./ fs;
    plot(ts, y_plot);
    xlabel('Time(s)');
    saveas(gcf, sprintf("Figs/lpc_%d_filtered_velvet.png", order));
    audiowrite(filename, y_out, fs);
    
    % Mag of the velvet noise
    Y_out = fft(y_vel, 8192);
    Y_out = Y_out(1:8192/2);
    plot(f_axis,mag2db(abs(Y_out)))
    
    set(gca,'XScale','log')
    xlim([min(f_axis), max(f_axis)]);
    ylim([-40, 80]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    grid on
    saveas(gcf, sprintf("Figs/lpc_%d_filtered_velvet_mag.png", order));
end
%%
function [v_out] = getVelvet(sec, fs)
    % Number of impulse/sec
    Nd = fs*0.1;
    Td = fs/Nd;
    
    M = floor(fs/Td)*sec;
    % m = np.arange(M) # imfs/Pulse counter
    m = 1:M;
    %r1 = np.random.uniform(size=M)
    r1 = rand(1,M);
    %k = np.round(m*Td+r1*(Td-1)).astype(np.int)
    k = m .* Td + r1 .* (Td-1);
    k = round(k);

    v_out = zeros(1, sec*fs);
    for i=1:sec*fs
        for j = 1:length(k)
            if i==k(j)
                dice = rand(1, 1);
                tmp = -1.0;
                if dice > 0.5
                    tmp = 1.0;
                end
                v_out(i) = tmp;
            end
        end
    end
end