# SNR仿真结果文件夹结构说明

## 目录结构

```
snr_simulation_results/
├── scene_001/                    # 场景1
│   ├── SNR_Inf/                  # 无噪声（SNR = ∞）
│   │   ├── ofdm_data.mat         # OFDM通信数据
│   │   └── radar_data.mat        # 雷达处理数据
│   ├── SNR_-20dB/                # SNR = -20 dB
│   │   ├── ofdm_data.mat
│   │   └── radar_data.mat
│   ├── SNR_-10dB/                # SNR = -10 dB
│   │   ├── ofdm_data.mat
│   │   └── radar_data.mat
│   ├── SNR_0dB/                  # SNR = 0 dB
│   │   ├── ofdm_data.mat
│   │   └── radar_data.mat
│   ├── SNR_10dB/                 # SNR = 10 dB
│   │   ├── ofdm_data.mat
│   │   └── radar_data.mat
│   └── SNR_20dB/                 # SNR = 20 dB
│       ├── ofdm_data.mat
│       └── radar_data.mat
├── scene_002/                    # 场景2
│   ├── SNR_Inf/
│   │   ├── ofdm_data.mat
│   │   └── radar_data.mat
│   └── ...
└── scene_003/                    # 场景3
    └── ...
```

## 文件内容说明

### ofdm_data.mat（OFDM通信数据）

包含变量：
- `Rx_complex_carrier_matrix`: 接收端解调后的复数载波矩阵
  - 维度: [symbols_per_carrier × IFFT_length]
  - 用途: OFDM接收信号，可用于重建多天线雷达数据
- `BER`: 误码率 (Bit Error Rate)
  - 类型: 标量 (0~1)
  - 用途: 评估OFDM通信质量
- `SNR`: 信噪比
  - 类型: 标量 (单位: dB)
  - 用途: 记录仿真时的SNR设置

**典型文件大小**: 约 4-8 MB

### radar_data.mat（雷达处理数据）

包含变量：
- `Velocity_fft_antenna_1_1`: 第一个天线的速度-距离FFT结果
  - 维度: [symbols_per_carrier × IFFT_length]
  - 用途: Range-Doppler二维谱，用于目标检测
  - 注意: 仅保存天线(1,1)的结果以节省空间（减少256倍）
- `RD_threshold_matrix`: CFAR检测门限矩阵
  - 维度: [symbols_per_carrier × IFFT_length]
  - 用途: OSCA-CFAR算法的自适应门限
- `RD_target_index`: 检测到的目标索引
  - 维度: [N × 2]，N为检测到的目标数量
  - 格式: 每行 [velocity_idx, range_idx]
  - 用途: 记录CFAR检测到的目标位置
- `RD_detect_matrix_abs`: CFAR检测后的结果矩阵
  - 维度: [symbols_per_carrier × IFFT_length]
  - 用途: 经过门限判决后的检测结果

**典型文件大小**: 约 8-16 MB

## 数据读取示例

### 读取OFDM数据
```matlab
% 读取场景1，SNR=0dB的OFDM数据
data = load('snr_simulation_results/scene_001/SNR_0dB/ofdm_data.mat');
Rx_matrix = data.Rx_complex_carrier_matrix;
BER = data.BER;
SNR = data.SNR;
fprintf('BER = %.6f, SNR = %d dB\n', BER, SNR);
```

### 读取雷达数据
```matlab
% 读取场景1，SNR=0dB的雷达处理结果
data = load('snr_simulation_results/scene_001/SNR_0dB/radar_data.mat');
RD_spectrum = data.Velocity_fft_antenna_1_1;
target_idx = data.RD_target_index;
fprintf('检测到 %d 个目标\n', size(target_idx, 1));

% 可视化Range-Doppler谱
figure;
imagesc(abs(RD_spectrum));
colorbar;
title('Range-Doppler Spectrum');
hold on;
plot(target_idx(:,2), target_idx(:,1), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
hold off;
```

### 批量分析多个SNR
```matlab
SNR_list = [Inf, -20, -10, 0, 10, 20];
BER_results = zeros(length(SNR_list), 1);
target_counts = zeros(length(SNR_list), 1);

for i = 1:length(SNR_list)
    if isinf(SNR_list(i))
        snr_folder = 'SNR_Inf';
    else
        snr_folder = sprintf('SNR_%ddB', SNR_list(i));
    end
    
    % 读取OFDM数据
    ofdm_file = fullfile('snr_simulation_results/scene_001', snr_folder, 'ofdm_data.mat');
    ofdm_data = load(ofdm_file);
    BER_results(i) = ofdm_data.BER;
    
    % 读取雷达数据
    radar_file = fullfile('snr_simulation_results/scene_001', snr_folder, 'radar_data.mat');
    radar_data = load(radar_file);
    target_counts(i) = size(radar_data.RD_target_index, 1);
end

% 绘制BER vs SNR曲线
figure;
semilogy(SNR_list, BER_results, 'o-', 'LineWidth', 2);
xlabel('SNR (dB)');
ylabel('BER');
title('BER vs SNR');
grid on;
```

## 空间优化说明

通过将雷达数据只保存第一个天线的FFT结果，实现了显著的空间节省：
- **原始方案**: 保存所有256个天线 (16×16) 的4D数组 → 约2GB/文件
- **优化方案**: 只保存1个天线的2D数组 → 约8MB/文件
- **空间节省**: **256倍** 减少

如需使用完整的多天线数据进行MUSIC算法，可以从 `ofdm_data.mat` 中的 `Rx_complex_carrier_matrix` 重新计算。

## 注意事项

1. 所有 `.mat` 文件使用 `-v7.3` 格式保存，支持大文件（>2GB）
2. 并行仿真时，每个SNR独立保存，避免竞争条件
3. 场景名称从原始 `.mat` 文件名提取（去除扩展名）
4. 建议定期备份仿真结果，特别是大规模场景数据
