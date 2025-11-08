# OFDM ISAC 成像代码模块化说明

## 概述
将原始的 `v1_test_ofdm_imaging_2DFFT_2DMUSIC.m` 拆分为多个功能模块，便于扩展、维护和复用。

## 目录结构

```
2D_FFT_2D_MUSIC/
├── v1_test_ofdm_imaging_2DFFT_2DMUSIC.m          # 原始完整脚本（保留）
├── main_modular_ofdm_isac.m                       # 新的模块化主脚本
├── func_generate_ofdm_signal.m                    # 模块0：OFDM信号生成
├── func_add_noise.m                               # 模块1：噪声添加
├── func_ofdm_demodulation.m                       # 模块2：OFDM解调
├── func_load_scene_and_compute_params.m           # 模块3：场景加载
├── func_generate_radar_echo.m                     # 模块4：雷达回波生成
├── func_range_doppler_processing.m                # 模块5：Range-Doppler处理
├── func_2d_music_angle_estimation.m               # 模块6：2D MUSIC角度估计
├── func_reconstruct_target_positions.m            # 模块7：位置重建
└── func_visualize_results.m                       # 模块8：结果可视化
```

---

## 模块功能划分

### 原始脚本分析（v1版本，654行）

| 行数范围 | 功能描述 | 拆分后的模块 |
|---------|---------|------------|
| 1-203 | OFDM信号生成（参数设置、调制、IFFT、加窗） | `func_generate_ofdm_signal.m` |
| 205-220 | 多SNR循环开始 + 噪声添加 | `func_add_noise.m` |
| 222-257 | OFDM解调（串并转换、FFT、4QAM解调、BER） | `func_ofdm_demodulation.m` |
| 260-289 | 场景加载与散射点参数计算 | `func_load_scene_and_compute_params.m` |
| 291-388 | 多天线雷达回波信号生成（距离、速度、角度） | `func_generate_radar_echo.m` |
| 390-447 | Range-Doppler 2D FFT + OSCA-CFAR检测 + 可视化 | `func_range_doppler_processing.m` |
| 448-455 | 角度测量矩阵构建（从Velocity_fft提取） | **整合到 `func_2d_music_angle_estimation.m`** |
| 457-594 | 2D MUSIC算法 + CA-CFAR检测 | `func_2d_music_angle_estimation.m` |
| 598-617 | 目标位置重建（极坐标→笛卡尔坐标） | `func_reconstruct_target_positions.m` |
| 619-654 | 结果可视化（估计值 vs 真值） | `func_visualize_results.m` |

---

## 各模块详细说明

### 模块0: `func_generate_ofdm_signal.m`
**功能**：生成完整的OFDM信号（通信信息+PRS参考信号）

**输入**：无（所有参数内部定义）

**输出**：
- `windowed_Tx_data`: 加窗后的串行发送信号 `[1×N]`
- `baseband_out`: 基带比特序列 `[1×baseband_out_length]`
- `complex_carrier_matrix`: 4QAM调制后的复数符号矩阵 `[224×2048]`
- `ofdm_params`: 结构体，包含所有OFDM参数（IFFT_length, GI, GIP, delta_f, f_c等）

**核心算法**：
1. 构建通信信息和PRS参考信号的时频索引
2. 使用m序列填充通信信息比特
3. 使用gold序列填充PRS参考信号比特
4. 4QAM调制
5. IFFT变换生成时域OFDM符号
6. 添加循环前后缀（CP/CIP）
7. 升余弦窗加窗，并串转换（符号重叠传输）

**使用示例**：
```matlab
[windowed_Tx_data, baseband_out, complex_carrier_matrix, ofdm_params] = ...
    func_generate_ofdm_signal();
IFFT_length = ofdm_params.IFFT_length;
symbols_per_carrier = ofdm_params.symbols_per_carrier;
```

**注意**：
- 执行时间较长（约10-30秒），主要耗时在m序列生成
- 参数固定（70 GHz, 4QAM, 2048子载波），如需修改需编辑函数内部

---

### 模块1: `func_add_noise.m`
**功能**：根据指定SNR为发送信号添加高斯白噪声

**输入**：
- `windowed_Tx_data`: 加窗后的发送信号
- `SNR`: 信噪比（dB），`Inf`表示无噪声

**输出**：
- `Rx_data`: 添加噪声后的接收信号

**使用示例**：
```matlab
Rx_data = func_add_noise(windowed_Tx_data, 10); % 10 dB SNR
```

---

### 2. `func_ofdm_demodulation.m`
**功能**：OFDM信号解调（串并转换、去CP/CPI、FFT、4QAM解调）并计算BER

**输入**：
- `Rx_data`: 接收信号
- `baseband_out`: 原始发送比特（用于BER计算）
- `IFFT_length`, `symbols_per_carrier`, `GI`, `GIP`: OFDM参数

**输出**：
- `Rx_complex_carrier_matrix`: 频域复信号矩阵 `[symbols_per_carrier × IFFT_length]`
- `BER`: 误比特率

**使用示例**：
```matlab
[Rx_complex_carrier_matrix, BER] = func_ofdm_demodulation(Rx_data, baseband_out, 2048, 224, 512, 80);
```

---

### 3. `func_load_scene_and_compute_params.m`
**功能**：从.mat文件加载蒙特卡洛场景，计算散射点的距离、速度、方位角、俯仰角

**输入**：
- `scene_file`: 场景文件路径（.mat）
- `base_pos`: 基站天线位置 `[x, y, z]`

**输出**：
- `environment_point`: 散射点矩阵 `[N×4]`: (x, y, z, velocity)
- `point_info`: 散射点信息 `[N×4]`: (距离R, 速度V, 方位角θ, 俯仰角φ)

**使用示例**：
```matlab
scene_file = 'scenario_1/mat_files/scene_003.mat';
base_pos = [14, 100, 20];
[environment_point, point_info] = func_load_scene_and_compute_params(scene_file, base_pos);
```

---

### 4. `func_generate_radar_echo.m`
**功能**：为所有天线生成雷达回波信号，叠加距离（kr）、速度（kd）、角度（ka）信息

**输入**：
- `Rx_complex_carrier_matrix`: 频域接收信号
- `point_info`: 散射点信息 `[N×4]`
- `radar_params`: 雷达参数结构体（包含M, N, lambda, d, c, f_c, delta_f等）

**输出**：
- `multi_Rx_complex_carrier_matrix_radar`: 多天线回波矩阵 `[symbols_per_carrier × IFFT_length × M × N]`

**雷达参数结构体示例**：
```matlab
radar_params.M = 16;
radar_params.N = 16;
radar_params.lambda = c / f_c;
radar_params.d = radar_params.lambda / 2;
radar_params.c = 3e8;
radar_params.f_c = 70e9;
radar_params.delta_f = 240e3;
radar_params.IFFT_length = 2048;
radar_params.symbols_per_carrier = 224;
radar_params.T_OFDM = 1/delta_f * (1 + PrefixRatio);
```

**使用示例**：
```matlab
multi_Rx = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params);
```

---

### 5. `func_range_doppler_processing.m`
**功能**：对所有天线进行Range-Doppler 2D FFT，使用OSCA-CFAR检测目标，并可视化

**输入**：
- `multi_Rx_complex_carrier_matrix_radar`: 多天线回波矩阵
- `complex_carrier_matrix`: 原始调制符号
- `radar_params`: 雷达参数
- `do_visualization`: 是否绘图（布尔值，默认true）

**输出**：
- `Velocity_fft`: 所有天线的速度-距离FFT结果 `[symbols_per_carrier × IFFT_length × M × N]`
- `RD_threshold_matrix`: OSCA-CFAR门限矩阵
- `RD_target_index`: 检测到的目标索引 `[N×2]` (velocity_bin, range_bin)
- `RD_detect_matrix_abs`: CFAR检测结果矩阵

**使用示例**：
```matlab
[Velocity_fft, RD_threshold, RD_targets, RD_detect] = ...
    func_range_doppler_processing(multi_Rx, complex_carrier_matrix, radar_params, true);
```

---

### 6. `func_2d_music_angle_estimation.m`
**功能**：使用2D MUSIC算法估计方位角和俯仰角，并进行CA-CFAR检测

**输入**：
- `Velocity_fft`: 所有天线的FFT结果
- `RD_target_index`: Range-Doppler域检测到的目标索引
- `radar_params`: 雷达参数（包含M, N, lambda, d, K_sub）
- `music_params`: MUSIC算法参数结构体

**输出**：
- `Angle_music_matrix`: MUSIC谱矩阵 `[theta_bins × faii_bins × Angel_page_num]`
- `Angle_music_threshold_matrix`: CA-CFAR门限矩阵
- `Angle_music_abs_matrix`: CA-CFAR检测结果
- `A2_Angle_target_cell`: 每个RE检测到的角度目标索引（cell数组）

**MUSIC参数结构体示例**：
```matlab
music_params.space = 0.1;               % 搜索粒度（度）
music_params.theta_head_offset = 60;
music_params.theta_back_offset = 60;
music_params.faii_head_offset = 60;
music_params.faii_back_offset = 90;
```

**使用示例**：
```matlab
[Angle_music, ~, ~, A2_targets] = ...
    func_2d_music_angle_estimation(Velocity_fft, RD_target_index, radar_params, music_params);
```

---

### 7. `func_reconstruct_target_positions.m`
**功能**：根据Range-Doppler和角度估计结果，将极坐标转换为笛卡尔坐标

**输入**：
- `RD_target_index`: Range-Doppler目标索引
- `A2_Angle_target_cell`: 角度目标索引（cell数组）
- `base_pos`: 基站位置
- `radar_params`: 雷达参数
- `music_params`: MUSIC参数

**输出**：
- `pos_all`: 目标位置 `[N×4]`: (x, y, z, velocity)
- `angle_all`: 目标角度 `[N×2]`: (theta, faii)

**使用示例**：
```matlab
[pos_all, angle_all] = func_reconstruct_target_positions(...
    RD_target_index, A2_targets, base_pos, radar_params, music_params);
```

---

### 8. `func_visualize_results.m`
**功能**：绘制估计的目标位置与真实位置对比图

**输入**：
- `pos_all`: 估计的目标位置 `[N×4]`
- `pos_all_true`: 真实目标位置 `[N×4]`（可选）

**使用示例**：
```matlab
func_visualize_results(pos_all, pos_all_true);  % 绘制估计值和真值
func_visualize_results(pos_all);                % 仅绘制估计值
```

---

## 使用流程

### 方式1：使用模块化主脚本（推荐）
```matlab
% 直接运行模块化主脚本
run('main_modular_ofdm_isac.m');
```

### 方式2：自定义流程
```matlab
% 步骤1：生成OFDM信号（运行原脚本第1-203行，或调用单独的生成函数）
% ... 生成 windowed_Tx_data, baseband_out, complex_carrier_matrix

% 步骤2：设置参数
SNR = 10;
base_pos = [14, 100, 20];
scene_file = 'scenario_1/mat_files/scene_003.mat';
% ... 设置 radar_params, music_params

% 步骤3：加载场景
[environment_point, point_info] = func_load_scene_and_compute_params(scene_file, base_pos);

% 步骤4：添加噪声
Rx_data = func_add_noise(windowed_Tx_data, SNR);

% 步骤5：OFDM解调
[Rx_complex_carrier_matrix, BER] = func_ofdm_demodulation(Rx_data, baseband_out, IFFT_length, symbols_per_carrier, GI, GIP);

% 步骤6：生成雷达回波
multi_Rx = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params);

% 步骤7：Range-Doppler处理
[Velocity_fft, ~, RD_target_index, ~] = func_range_doppler_processing(multi_Rx, complex_carrier_matrix, radar_params);

% 步骤8：2D MUSIC角度估计
[~, ~, ~, A2_targets] = func_2d_music_angle_estimation(Velocity_fft, RD_target_index, radar_params, music_params);

% 步骤9：位置重建
[pos_all, angle_all] = func_reconstruct_target_positions(RD_target_index, A2_targets, base_pos, radar_params, music_params);

% 步骤10：可视化
func_visualize_results(pos_all);
```

---

## 扩展建议

### 1. 参数扫描实验
可以轻松实现不同参数的批量测试：
```matlab
% 扫描不同的子阵元数K_sub
K_sub_list = [4, 8, 16, 32];
for k = K_sub_list
    radar_params.K_sub = k;
    % ... 运行处理流程并保存结果
end
```

### 2. 批量场景处理
```matlab
scene_files = dir('scenario_1/mat_files/*.mat');
for i = 1:length(scene_files)
    scene_file = fullfile(scene_files(i).folder, scene_files(i).name);
    [environment_point, point_info] = func_load_scene_and_compute_params(scene_file, base_pos);
    % ... 运行处理流程
end
```

### 3. 性能评估指标
```matlab
% 计算定位误差
pos_error = sqrt(sum((pos_all(:,1:3) - pos_all_true(:,1:3)).^2, 2));
mean_error = mean(pos_error);
rmse = sqrt(mean(pos_error.^2));
fprintf('平均定位误差：%.2f m\n', mean_error);
fprintf('RMSE：%.2f m\n', rmse);
```

### 4. 进一步模块化建议
- 将第1-203行的OFDM信号生成部分封装为 `func_generate_ofdm_signal.m`
- 创建 `func_compute_true_positions.m` 计算真实位置（目前在主脚本中）
- 创建 `func_save_results.m` 保存结果到文件

---

## 注意事项

1. **依赖函数**：所有模块依赖原有的辅助函数（如 `qam4.m`, `demoduqam4.m`, `OSCA_CFAR.m`, `CA_CFAR.m`, `smooth_covariance.m`, `WCA_CFAR_1D.m`），确保它们在MATLAB路径中。

2. **内存优化**：`func_generate_radar_echo.m` 和 `func_2d_music_angle_estimation.m` 是计算密集型函数，处理大场景时注意内存占用。

3. **可视化控制**：在多SNR循环中，建议只在第一次或最后一次循环时开启可视化（`do_visualization=true`），避免产生过多图窗。

4. **OFDM生成部分**：`main_modular_ofdm_isac.m` 中第一部分（OFDM信号生成）需要补充完整代码，或者单独运行原脚本生成后加载变量。

---

## 与原脚本对比

| 特性 | 原脚本（v1版本） | 模块化版本 |
|-----|----------------|----------|
| 代码行数 | 654行 | 主脚本~150行 + 8个函数（各50-120行） |
| 可维护性 | 低（单一大文件） | 高（功能分离） |
| 可复用性 | 低 | 高（独立函数可单独调用） |
| 可扩展性 | 中 | 高（易于添加新功能） |
| 调试难度 | 高 | 低（模块独立测试） |
| 参数扫描 | 需修改主脚本 | 直接调用函数循环 |

---

## 贡献者
- **原始代码**：v1_test_ofdm_imaging_2DFFT_2DMUSIC.m
- **模块化重构**：2025年11月（基于仓库 copilot-instructions.md 指导原则）

---

## License
遵循项目根目录的LICENSE文件
