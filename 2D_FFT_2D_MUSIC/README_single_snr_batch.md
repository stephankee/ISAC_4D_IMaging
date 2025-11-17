# 单SNR批量处理脚本使用说明

## 📋 概述

`run_single_snr_batch.m` 是一个模板脚本，用于处理所有场景在**特定SNR等级**下的仿真。

与原来的 `main_modular_ofdm_isac.m` 使用parfor并行处理不同，这个脚本专注于单个SNR等级，可以通过启动多个MATLAB进程来并行处理不同的SNR等级。

## 🎯 主要优势

1. **完整保存数据**：保存完整的 `Velocity_fft` 数据（4D矩阵），而非仅保存第一个天线的数据
2. **进程级并行**：可以同时运行5个MATLAB进程，每个处理一个SNR等级
3. **断点续传**：如果结果文件已存在，会自动跳过该场景
4. **错误容忍**：单个场景出错不会影响其他场景的处理
5. **独立运行**：每个进程独立，互不干扰

## 🚀 快速开始

### 步骤1：复制脚本

将 `run_single_snr_batch.m` 复制5份，分别命名为：

```
run_single_snr_batch_inf.m
run_single_snr_batch_minus20.m
run_single_snr_batch_minus10.m
run_single_snr_batch_0.m
run_single_snr_batch_10.m
```

### 步骤2：修改SNR参数

打开每个脚本，修改第12行的 `SNR_TARGET` 变量：

#### run_single_snr_batch_inf.m
```matlab
SNR_TARGET = Inf;  % 无噪声情况
```

#### run_single_snr_batch_minus20.m
```matlab
SNR_TARGET = -20;  % -20 dB
```

#### run_single_snr_batch_minus10.m
```matlab
SNR_TARGET = -10;  % -10 dB
```

#### run_single_snr_batch_0.m
```matlab
SNR_TARGET = 0;    % 0 dB
```

#### run_single_snr_batch_10.m
```matlab
SNR_TARGET = 10;   % 10 dB
```

### 步骤3：启动5个MATLAB进程

#### 方法1：使用MATLAB GUI（推荐）

1. 打开5个MATLAB窗口
2. 在每个窗口中运行对应的脚本：
   - 窗口1：`run run_single_snr_batch_inf.m`
   - 窗口2：`run run_single_snr_batch_minus20.m`
   - 窗口3：`run run_single_snr_batch_minus10.m`
   - 窗口4：`run run_single_snr_batch_0.m`
   - 窗口5：`run run_single_snr_batch_10.m`

#### 方法2：使用命令行（Windows PowerShell）

```powershell
# 进入工作目录
cd "D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC"

# 启动5个MATLAB进程（后台运行）
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_inf"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_minus20"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_minus10"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_0"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_10"
```

#### 方法3：使用批处理文件

创建 `run_all_snr_batches.bat` 文件：

```batch
@echo off
cd /d "D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC"

echo Starting MATLAB batch processes...

start "SNR_Inf" matlab -batch "run_single_snr_batch_inf"
timeout /t 5
start "SNR_-20dB" matlab -batch "run_single_snr_batch_minus20"
timeout /t 5
start "SNR_-10dB" matlab -batch "run_single_snr_batch_minus10"
timeout /t 5
start "SNR_0dB" matlab -batch "run_single_snr_batch_0"
timeout /t 5
start "SNR_10dB" matlab -batch "run_single_snr_batch_10"

echo All processes started!
pause
```

然后双击运行 `run_all_snr_batches.bat`

## 📁 输出结构

```
snr_simulation_results/
├── ofdm_signal_data.mat          # OFDM信号数据（共享）
├── completed_SNR_Inf.txt         # 完成标记（Inf）
├── completed_SNR_-20dB.txt       # 完成标记（-20dB）
├── completed_SNR_-10dB.txt       # 完成标记（-10dB）
├── completed_SNR_0dB.txt         # 完成标记（0dB）
├── completed_SNR_10dB.txt        # 完成标记（10dB）
├── scene_001/
│   ├── scene_info.mat            # 场景信息
│   ├── SNR_Inf/
│   │   └── results.mat           # 完整结果（包含完整Velocity_fft）
│   ├── SNR_-20dB/
│   │   └── results.mat
│   ├── SNR_-10dB/
│   │   └── results.mat
│   ├── SNR_0dB/
│   │   └── results.mat
│   └── SNR_10dB/
│       └── results.mat
└── scene_002/
    └── ...
```

## � 保存的数据内容

每个 `results.mat` 文件包含：

- `SNR_TARGET`: 当前SNR值
- `BER`: 误码率
- `Velocity_fft_antenna_1_1`: **第一个天线的速度FFT结果** (IFFT_length × symbols_per_carrier)
- `RD_threshold_matrix`: Range-Doppler阈值矩阵
- `RD_target_index`: 检测到的目标索引
- `RD_detect_matrix_abs`: Range-Doppler检测矩阵幅值

💡 **空间优化**：只保存第一个天线(1,1)的FFT结果，而非完整的4D矩阵 (IFFT_length × symbols_per_carrier × M × N)。其他天线的数据在后续MUSIC角度估计时可以重新计算。这样每个文件约减小256倍（16×16）的空间。

## 🔍 监控进度

### 查看完成标记文件

```powershell
Get-ChildItem "D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results\completed_*.txt"
```

### 查看某个SNR的处理进度

在MATLAB命令窗口中查看实时输出，或检查结果文件数量：

```matlab
% 统计SNR_Inf的完成场景数
snr_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results\';
scene_dirs = dir(fullfile(snr_dir, 'scene_*'));
completed_count = 0;
for i = 1:length(scene_dirs)
    result_file = fullfile(snr_dir, scene_dirs(i).name, 'SNR_Inf', 'results.mat');
    if exist(result_file, 'file')
        completed_count = completed_count + 1;
    end
end
fprintf('SNR_Inf 已完成: %d/%d\n', completed_count, length(scene_dirs));
```

## ⚠️ 注意事项

1. **内存需求**：确保每个MATLAB进程有足够内存（建议至少8GB可用内存）
2. **CPU负载**：同时运行5个进程会占用较多CPU资源，建议在高性能工作站上运行
3. **断点续传**：如果某个进程中断，重新运行脚本会自动跳过已完成的场景
4. **错误处理**：如果某个场景处理失败，错误信息会保存在对应的 `error_log.mat` 文件中

## 🛠️ 故障排除

### 问题：内存不足

**解决方案**：
- 减少同时运行的进程数（例如一次只运行2-3个）
- 增加虚拟内存
- 在更高配置的机器上运行

### 问题：某个场景持续出错

**解决方案**：
1. 查看错误日志：`load('snr_simulation_results/scene_XXX/SNR_Inf/error_log.mat')`
2. 单独调试该场景
3. 如果是数据问题，可以跳过该场景

### 问题：进程意外终止

**解决方案**：
- 重新运行脚本，它会自动从断点继续
- 检查磁盘空间是否充足
- 检查MATLAB许可证是否正常

## 📈 性能估算

假设：
- 场景总数：1000个
- 每场景平均处理时间：30秒
- SNR等级数：5个

**串行处理（原方案）**：
- 总时间 = 1000 × 5 × 30秒 = 41.7小时

**并行处理（本方案）**：
- 总时间 = 1000 × 30秒 = 8.3小时

**提速比**：约5倍（理论值）

## 📝 后续处理

处理完成后，可以使用以下脚本加载和分析数据：

```matlab
% 加载某个场景的某个SNR结果
scene_name = 'scene_001';
snr_level = 'SNR_Inf';
result_file = fullfile('snr_simulation_results', scene_name, snr_level, 'results.mat');
load(result_file);

% 现在可以使用完整的Velocity_fft进行后续的MUSIC角度估计等处理
fprintf('SNR: %s\n', num2str(SNR_TARGET));
fprintf('BER: %.6f\n', BER);
fprintf('检测到的目标数: %d\n', size(RD_target_index, 1));
fprintf('Velocity_fft大小: %s\n', mat2str(size(Velocity_fft)));
```

## 🔗 相关文档

- `README_modular_functions.md` - 模块化函数说明
- `README_simulation_results_structure.md` - 结果结构说明
- `README_matlab_scene_loading.md` - 场景加载说明
