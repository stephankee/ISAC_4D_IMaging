# 快速操作指南 - 5进程并行处理

## 🎯 目标
同时运行5个MATLAB进程，每个处理一个SNR等级，保存完整的 `Velocity_fft` 数据。

## 📝 操作步骤

### 1️⃣ 复制脚本（5份）

在 `2D_FFT_2D_MUSIC` 目录下，将 `run_single_snr_batch.m` 复制为：

```
run_single_snr_batch_inf.m
run_single_snr_batch_minus20.m
run_single_snr_batch_minus10.m
run_single_snr_batch_0.m
run_single_snr_batch_10.m
```

### 2️⃣ 修改SNR参数

打开每个文件，修改第 **12行** 的 `SNR_TARGET` 值：

| 文件名 | SNR_TARGET 值 | 说明 |
|--------|--------------|------|
| `run_single_snr_batch_inf.m` | `Inf` | 无噪声 |
| `run_single_snr_batch_minus20.m` | `-20` | -20 dB |
| `run_single_snr_batch_minus10.m` | `-10` | -10 dB |
| `run_single_snr_batch_0.m` | `0` | 0 dB |
| `run_single_snr_batch_10.m` | `10` | 10 dB |

**修改示例：**
```matlab
% run_single_snr_batch_inf.m (第12行)
SNR_TARGET = Inf;  % <--- 保持为 Inf

% run_single_snr_batch_minus20.m (第12行)
SNR_TARGET = -20;  % <--- 改为 -20

% run_single_snr_batch_minus10.m (第12行)
SNR_TARGET = -10;  % <--- 改为 -10

% 以此类推...
```

### 3️⃣ 启动5个进程

#### 方法A：使用批处理文件（最简单）✨

双击运行 `run_all_snr_batches.bat`

#### 方法B：手动启动MATLAB窗口

1. 打开5个MATLAB窗口
2. 在每个窗口中分别运行：
   ```matlab
   run run_single_snr_batch_inf.m
   run run_single_snr_batch_minus20.m
   run run_single_snr_batch_minus10.m
   run run_single_snr_batch_0.m
   run run_single_snr_batch_10.m
   ```

#### 方法C：使用PowerShell命令行

```powershell
cd "D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_inf"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_minus20"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_minus10"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_0"
Start-Process matlab -ArgumentList "-batch run_single_snr_batch_10"
```

### 4️⃣ 监控进度

#### 实时监控（推荐）

在PowerShell中运行：
```powershell
cd "D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC"
.\monitor_progress.ps1
```

#### 自动刷新监控（每30秒更新）

```powershell
while ($true) { Clear-Host; .\monitor_progress.ps1; Start-Sleep -Seconds 30 }
```

按 `Ctrl+C` 停止监控

#### 查看完成标记

```powershell
dir snr_simulation_results\completed_*.txt
```

## 📊 输出结果

```
snr_simulation_results/
├── ofdm_signal_data.mat              # OFDM信号数据（所有进程共享）
├── completed_SNR_Inf.txt             # Inf 完成标记
├── completed_SNR_-20dB.txt           # -20dB 完成标记
├── completed_SNR_-10dB.txt           # -10dB 完成标记
├── completed_SNR_0dB.txt             # 0dB 完成标记
├── completed_SNR_10dB.txt            # 10dB 完成标记
└── scene_001/
    ├── scene_info.mat                # 场景元数据
    ├── SNR_Inf/
    │   └── results.mat               # ✅ 包含完整 Velocity_fft
    ├── SNR_-20dB/
    │   └── results.mat
    ├── SNR_-10dB/
    │   └── results.mat
    ├── SNR_0dB/
    │   └── results.mat
    └── SNR_10dB/
        └── results.mat
```

## 🔍 验证数据完整性

运行以下MATLAB代码验证：

```matlab
% 加载一个结果文件
load('snr_simulation_results/scene_001/SNR_Inf/results.mat')

% 检查数据
fprintf('SNR: %s\n', num2str(SNR_TARGET));
fprintf('BER: %.6f\n', BER);
fprintf('Velocity_fft_antenna_1_1 大小: %s\n', mat2str(size(Velocity_fft_antenna_1_1)));
fprintf('期望大小: [IFFT_length × symbols_per_carrier]\n');
fprintf('检测目标数: %d\n', size(RD_target_index, 1));
fprintf('\n💡 提示：只保存了第一个天线的数据，节省约256倍空间\n');
```

预期输出：
```
SNR: Inf
BER: 0.000000
Velocity_fft_antenna_1_1 大小: [64 32]  (或类似维度)
期望大小: [IFFT_length × symbols_per_carrier]
检测目标数: XX

💡 提示：只保存了第一个天线的数据，节省约256倍空间
```

## ⚡ 性能提示

| 项目 | 建议配置 |
|------|----------|
| **内存** | 至少 16GB（每进程约2-4GB） |
| **CPU** | 至少 8核（最好16核） |
| **磁盘** | SSD + 至少20GB可用空间（已优化存储） |
| **时间** | 约 8-10 小时（取决于场景数和硬件） |

## ⚠️ 常见问题

### Q1: 内存不足怎么办？
**A:** 一次只运行2-3个进程，分批完成。

### Q2: 如何暂停和恢复？
**A:** 
- **暂停**：关闭MATLAB窗口
- **恢复**：重新运行对应脚本（会自动跳过已完成的场景）

### Q3: 某个场景出错怎么办？
**A:** 
1. 查看错误日志：`snr_simulation_results/scene_XXX/SNR_Inf/error_log.mat`
2. 脚本会自动跳过错误场景，继续处理其他场景
3. 可以后续单独调试出错的场景

### Q4: 如何只重新处理某个SNR等级？
**A:** 删除对应的 `completed_SNR_XXX.txt` 文件，然后只运行该SNR的脚本。

### Q5: 磁盘空间不足怎么办？
**A:** 
- 每个结果文件约 1-5MB（已优化：只保存第一个天线数据）
- 1000个场景 × 5个SNR = 约 5-25GB
- 相比保存完整4D数据，节省约256倍空间（16×16天线阵列）

## 📞 需要帮助？

参考完整文档：`README_single_snr_batch.md`

---

**祝运行顺利！** 🚀
