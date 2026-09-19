%% SISO vs 2×2 MIMO-OFDM QPSK ZF均衡 对比仿真
clear; clc; close all;

% 参数设置
nSub = 64;        % OFDM子载波数
nCp = 16;         % 循环前缀
nSym = 500;       % OFDM符号数目
snr_dB_list = 0:2:20;
ber_mimo = zeros(size(snr_dB_list));
ber_siso = zeros(size(snr_dB_list));

%% ========== 2×2 MIMO仿真 ==========
ntx=2;nrx=2;
for i_snr = 1:length(snr_dB_list)
    snr_dB = snr_dB_list(i_snr);
    bit_per_ant = nSub * nSym * 2;
    bits_tx = zeros(bit_per_ant, ntx);
    for ant = 1:ntx
        bits_tx(:,ant) = randi([0,1], bit_per_ant, 1);
    end

    qpsk_ant = zeros(nSub, nSym, ntx);
    for ant = 1:ntx
        bits_reshape = reshape(bits_tx(:,ant),2,[]).';
        qpsk_sym = (1-2*bits_reshape(:,1)) + 1j*(1-2*bits_reshape(:,2));
        qpsk_ant(:,:,ant) = reshape(qpsk_sym, nSub, nSym);
    end

    % 每个子载波生成瑞利信道
    H_all = zeros(nrx, ntx, nSub);
    for sc = 1:nSub
        H_all(:,:,sc) = (randn(nrx,ntx) + 1j*randn(nrx,ntx))/sqrt(2);
    end

    rx_freq = zeros(nSub, nSym, nrx);
    for sym_idx = 1:nSym
        for sc = 1:nSub
            H_sc = H_all(:,:,sc);
            tx_vec = squeeze(qpsk_ant(sc, sym_idx, :));
            rx_freq(sc, sym_idx, :) = H_sc * tx_vec;
        end
    end

    rx_time = zeros(nSub+nCp, nSym, nrx);
    for rx_ant = 1:nrx
        time_data = ifft(rx_freq(:,:,rx_ant), nSub);
        rx_time(:,:,rx_ant) = [time_data(end-nCp+1:end,:); time_data];
    end
    rx_signal = reshape(rx_time, [], nrx);
    rx_signal = awgn(rx_signal, snr_dB, 'measured');

    rx_time_back = reshape(rx_signal, nSub+nCp, nSym, nrx);
    rx_nocp = rx_time_back(nCp+1:end,:,:);
    rx_freq_rx = zeros(nSub, nSym, nrx);
    for rx_ant = 1:nrx
        rx_freq_rx(:,:,rx_ant) = fft(rx_nocp(:,:,rx_ant), nSub);
    end

    bits_rx = zeros(bit_per_ant, ntx);
    for sc = 1:nSub
        for sym_idx = 1:nSym
            H_sc = H_all(:,:,sc);
            rx_vec = squeeze(rx_freq_rx(sc,sym_idx,:));
            W_zf = inv(H_sc'*H_sc)*H_sc';
            est_sym = W_zf * rx_vec;
            for ant = 1:ntx
                b1 = real(est_sym(ant)) < 0;
                b2 = imag(est_sym(ant)) < 0;
                pos = ((sym_idx-1)*nSub + (sc-1))*2 + 1;
                bits_rx(pos, ant) = b1;
                bits_rx(pos+1, ant) = b2;
            end
        end
    end
    ber = 0;
    for ant = 1:ntx
        ber = ber + sum(bits_tx(:,ant) ~= bits_rx(:,ant))/bit_per_ant;
    end
    ber_mimo(i_snr) = ber / ntx;
end

%% ========== SISO 1×1仿真 ==========
ntx=1;nrx=1;
for i_snr = 1:length(snr_dB_list)
    snr_dB = snr_dB_list(i_snr);
    bit_total = nSub * nSym *2;
    bits_tx = randi([0,1],bit_total,1);
    bits_reshape = reshape(bits_tx,2,[]).';
    qpsk_sym = (1-2*bits_reshape(:,1)) +1j*(1-2*bits_reshape(:,2));
    qpsk_sym = reshape(qpsk_sym,nSub,nSym);

    H_all = zeros(nrx,ntx,nSub);
    for sc=1:nSub
        H_all(:,:,sc) = (randn(nrx,ntx)+1j*randn(nrx,ntx))/sqrt(2);
    end
    rx_freq = zeros(nSub,nSym,nrx);
    for sym_idx=1:nSym
        for sc=1:nSub
            H_sc = H_all(:,:,sc);
            rx_freq(sc,sym_idx,:) = H_sc * qpsk_sym(sc,sym_idx);
        end
    end
    rx_time = zeros(nSub+nCp,nSym,nrx);
    for rx_ant=1:nrx
        time_data = ifft(rx_freq(:,:,rx_ant),nSub);
        rx_time(:,:,rx_ant) = [time_data(end-nCp+1:end,:); time_data];
    end
    rx_signal = reshape(rx_time,[],nrx);
    rx_signal = awgn(rx_signal, snr_dB, 'measured');

    rx_time_back = reshape(rx_signal,nSub+nCp,nSym,nrx);
    rx_nocp = rx_time_back(nCp+1:end,:,:);
    rx_freq_rx = zeros(nSub,nSym,nrx);
    for rx_ant=1:nrx
        rx_freq_rx(:,:,rx_ant) = fft(rx_nocp(:,:,rx_ant),nSub);
    end

    bits_rx = zeros(bit_total,1);
    for sc=1:nSub
        for sym_idx=1:nSym
            H_sc = H_all(:,:,sc);
            rx_vec = squeeze(rx_freq_rx(sc,sym_idx,:));
            est_sym = H_sc\rx_vec;
            b1 = real(est_sym)<0;
            b2 = imag(est_sym)<0;
            pos = ((sym_idx-1)*nSub + (sc-1))*2 + 1;
            bits_rx(pos) = b1;
            bits_rx(pos+1) = b2;
        end
    end
    ber_siso(i_snr) = sum(bits_tx ~= bits_rx)/bit_total;
end

%% 绘图，两条曲线对比
figure;
semilogy(snr_dB_list, ber_mimo, 'o-','LineWidth',1.5,DisplayName="2×2 MIMO-OFDM ZF");
hold on;
semilogy(snr_dB_list, ber_siso, 's-','LineWidth',1.5,DisplayName="SISO OFDM");
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('SISO vs 2×2 MIMO-OFDM QPSK');
legend;
hold off;
