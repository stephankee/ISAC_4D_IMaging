# SNR仿真结果目录结构说明

本目录存储多场景多SNR仿真的结果数据。

## 目录结构

```
snr_simulation_results/
├── README.md                          # 本说明文件
├── ofdm_signal_data.mat              # OFDM信号数据（全局，只保存一次）
├── scene_001/                         # 场景1的结果
│   ├── scene_info.mat                # 场景1的环境信息
│   ├── SNR_Inf/                      # 无噪声情况
│   │   └── results.mat               # 检测结果
│   ├── SNR_-20dB/                    # SNR=-20dB
│   │   └── results.mat
│   ├── SNR_-10dB/
│   │   └── results.mat
│   ├── SNR_0dB/
│   │   └── results.mat
│   ├── SNR_10dB/
│   │   └── results.mat
│   └── SNR_20dB/
│       └── results.mat
├── scene_002/                         # 场景2的结果
│   ├── scene_info.mat
│   ├── SNR_Inf/
│   └── ...
└── scene_003/
    └── ...
```

## 文件内容说明

### 1. `ofdm_signal_data.mat` (全局数据)
保存一次仿真中不变的OFDM信号和参数：
- `windowed_Tx_data`: 加窗后的发送数据
- `baseband_out`: 基带输出信号
- `complex_carrier_matrix`: 复数载波矩阵
- `ofdm_params`: OFDM参数结构体
- `radar_params`: 雷达参数结构体
- `music_params`: MUSIC算法参数结构体
- `base_pos`: 基站位置

### 2. `scene_XXX/scene_info.mat` (每场景一份)
保存每个场景的环境信息：
- `scene_name`: 场景文件名
- `environment_point`: 环境散射点位置
- `point_info`: 散射点详细信息 [距离, 速度, 方位角, 俯仰角]

### 3. `scene_XXX/SNR_XXdB/results.mat` (每个场景×SNR组合一份)
保存特定场景在特定SNR下的检测结果：
- `SNR`: 信噪比 (dB)
- `BER`: 比特误码率
- `Velocity_fft_antenna_1_1`: 第一个天线的速度-距离FFT结果 (2D矩阵)
- `RD_threshold_matrix`: CFAR检测门限矩阵
- `RD_target_index`: 检测到的目标索引 [N×2]
- `RD_detect_matrix_abs`: CFAR检测结果矩阵

## 数据量估算

假设有 N 个场景，6 个SNR等级：
- OFDM信号数据: 约 50-100 MB (只保存1份)
- 每个场景信息: 约 1-5 MB × N
- 每个结果文件: 约 8-15 MB × 6 × N

**总大小**: 约 50MB + (8MB × 6 + 5MB) × N ≈ **50MB + 53MB × N**

示例：
- 10个场景: 约 580 MB
- 100个场景: 约 5.3 GB

## 数据读取示例

```matlab
% 1. 加载OFDM信号数据
load('snr_simulation_results/ofdm_signal_data.mat');

% 2. 加载特定场景信息
load('snr_simulation_results/scene_001/scene_info.mat');

% 3. 加载特定场景特定SNR的结果
load('snr_simulation_results/scene_001/SNR_0dB/results.mat');

% 4. 访问变量
fprintf('SNR: %.1f dB, BER: %.6f\n', SNR, BER);
fprintf('检测到 %d 个目标\n', size(RD_target_index, 1));
```

## 注意事项

1. **空间优化**: 只保存第一个天线的FFT结果，如需其他天线数据可从原始信号重新计算
2. **文件覆盖**: 相同场景和SNR的结果会覆盖已有文件
3. **并行安全**: 使用 `parsave_compact` 函数确保 parfor 循环中的保存操作安全
4. **路径依赖**: 使用相对路径，确保在 `2D_FFT_2D_MUSIC/` 目录下运行脚本

## 生成时间

由主脚本 `main_modular_ofdm_isac.m` 自动生成
最后更新: 2025年11月8日
