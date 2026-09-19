# 2×2 MIMO-OFDM Baseband Simulation with ZF Equalizer
## Project Introduction
This MATLAB project implements a 2×2 MIMO-OFDM physical-layer communication system with QPSK modulation.
MIMO-OFDM is the core physical layer technology adopted in LTE and 5G NR.
Zero-Forcing (ZF) equalization is applied at the receiver to eliminate inter-stream interference from multiple antennas.

This simulation compares the BER performance between SISO(1×1) and 2×2 MIMO under Rayleigh fading channel.

## Workflow
1. Generate random binary bit stream
2. QPSK modulation
3. OFDM modulation: IFFT transform + Cyclic Prefix (CP)
4. Rayleigh flat-fading MIMO channel
5. Add AWGN Gaussian white noise
6. Receiver: remove CP, FFT transform back to frequency domain
7. ZF equalization to separate multi-antenna data streams
8. QPSK demodulation, calculate BER, plot BER-SNR curve

## Parameters
- Number of OFDM subcarriers: 64
- Cyclic Prefix length: 16
- Modulation: QPSK
- Channel: Rayleigh flat fading + AWGN
- Equalizer: Zero-Forcing(ZF)
- Antenna configuration: SISO(1×1) / MIMO(2×2)

## Simulation Result
![BER curve of SISO and MIMO](figs/ber_curve.png)
> The figure shows BER decreases as SNR increases.
> 2×2 MIMO achieves higher spectral efficiency: it transmits two independent data streams simultaneously in the same bandwidth, doubling the throughput compared with SISO.
> Drawback of ZF equalizer: noise enhancement at low SNR.

## Debug Log
> At first the BER was always near 0.5, which meant the receiver could not demodulate the signal correctly, just like random guessing.
> Root cause: The channel matrix H was randomly generated separately at transmitter and receiver. The receiver used a different channel matrix and could not do correct equalization.
> Solution: Pre-generate fixed channel matrix for each subcarrier, use the same H for both transmitter and receiver. After fixing this bug, the BER curve becomes normal.

## How to Run
1. Environment: MATLAB R2025a
2. Download `mimo_ofdm_siso_compare.m`
3. Run script directly.
4. The output is semi-log BER vs SNR plot.

## Key Concepts
- **MIMO**: Multiple-input multiple-output, use multiple antennas to improve spectral efficiency.
- **OFDM**: Orthogonal Frequency Division Multiplexing. CP mitigates ISI(Inter-Symbol Interference) caused by multipath.
- **ZF Equalizer**: Zero forcing equalizer eliminates cross-antenna interference by matrix inversion. It has simple implementation but suffers from noise amplification.

---
### 中文简述
本项目基于MATLAB搭建2发2收MIMO-OFDM基带通信链路，采用QPSK调制，在瑞利衰落信道下仿真通信性能，对比SISO单天线与MIMO多天线系统的误码率BER。
MIMO-OFDM是4G LTE、5G NR的核心物理层技术。接收端使用ZF迫零均衡，消除多天线之间的串扰。

**调试记录**
项目初期仿真得到的BER一直稳定在0.5附近，解调失效。排查发现：发射端与接收端各自随机生成信道矩阵H，收发信道不一致，接收机无法完成均衡。
解决办法：预先为每个子载波生成固定瑞利信道矩阵，收发两端共用同一套H。修复后得到标准的BER随SNR下降的曲线。
