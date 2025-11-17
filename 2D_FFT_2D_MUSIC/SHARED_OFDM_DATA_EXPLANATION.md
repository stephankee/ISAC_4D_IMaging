# OFDM信号数据共享机制说明

## 📌 修改目的

确保5个并行运行的脚本使用**完全相同的OFDM信号数据**，以保证实验的一致性和可比性。

## 🔄 工作流程

### 第一个启动的脚本（无论是哪个SNR等级）

```
1. 检查 snr_simulation_results/ofdm_signal_data.mat 是否存在
   ↓ 不存在
2. 调用 func_generate_ofdm_signal() 生成新的OFDM信号
   ↓
3. 保存到 ofdm_signal_data.mat
   - windowed_Tx_data
   - baseband_out
   - complex_carrier_matrix
   - ofdm_params
   ↓
4. 继续设置 radar_params, music_params, base_pos
   ↓
5. 将这些参数追加保存到 ofdm_signal_data.mat
   ↓
6. 处理所有场景
```

### 后续启动的脚本（其他4个SNR等级）

```
1. 检查 snr_simulation_results/ofdm_signal_data.mat 是否存在
   ↓ 存在！
2. 直接加载已存在的OFDM信号数据
   ↓
3. 继续设置 radar_params, music_params, base_pos
   ↓
4. 检查 ofdm_signal_data.mat 中是否已包含这些参数
   ↓ 已包含，跳过
5. 处理所有场景
```

## 📦 共享数据文件内容

`snr_simulation_results/ofdm_signal_data.mat` 包含：

| 变量名 | 描述 | 用途 |
|--------|------|------|
| `windowed_Tx_data` | 加窗后的发送数据 | 原始OFDM发送信号 |
| `baseband_out` | 基带输出 | OFDM解调参考 |
| `complex_carrier_matrix` | 复载波矩阵 | 雷达处理参考 |
| `ofdm_params` | OFDM参数结构体 | 包含所有OFDM配置参数 |
| `radar_params` | 雷达参数结构体 | 天线阵列、频率等参数 |
| `music_params` | MUSIC算法参数 | 角度估计搜索参数 |
| `base_pos` | 基站位置 | `[x, y, z]` 坐标 |

## 💾 结果文件存储优化

每个场景的 `results.mat` 文件包含：

| 变量名 | 描述 | 大小 |
|--------|------|------|
| `SNR_TARGET` | 当前SNR值 | 1个数值 |
| `BER` | 误码率 | 1个数值 |
| `Velocity_fft_antenna_1_1` | **第一个天线的FFT结果** | IFFT_length × symbols_per_carrier |
| `RD_threshold_matrix` | Range-Doppler阈值矩阵 | 2D矩阵 |
| `RD_target_index` | 检测到的目标索引 | N × 2 |
| `RD_detect_matrix_abs` | Range-Doppler检测矩阵 | 2D矩阵 |

### 🎯 空间优化说明

**为什么只保存第一个天线的数据？**

- **原始大小**：完整的 `Velocity_fft` 是 4D 矩阵 (IFFT_length × symbols_per_carrier × M × N)
  - 例如：64 × 32 × 16 × 16 = 524,288 个复数
  - 每个复数 16 bytes → 约 8.4 MB

- **优化后大小**：只保存 `Velocity_fft_antenna_1_1` (IFFT_length × symbols_per_carrier)
  - 例如：64 × 32 = 2,048 个复数
  - 每个复数 16 bytes → 约 32 KB
  - **节省 256 倍空间**（16 × 16 = 256）

- **为什么可以这样做？**
  - 后续MUSIC角度估计时，其他天线的数据可以从原始信号重新计算
  - Range-Doppler检测结果已经保存，不会丢失
  - 大幅减少磁盘I/O和存储需求

## ✅ 数据一致性保证

### 1. 文件级锁定
- MATLAB的 `save` 函数会自动处理文件写入的原子性
- 第一个脚本写入完成后，文件才对其他进程可见

### 2. 只生成一次
```matlab
if exist(ofdm_signal_file, 'file')
    % 文件存在 → 加载
    load(ofdm_signal_file, ...);
else
    % 文件不存在 → 生成并保存
    [windowed_Tx_data, ...] = func_generate_ofdm_signal();
    save(ofdm_signal_file, ...);
end
```

### 3. 参数补充机制
```matlab
% 检查文件中是否包含所有必要参数
file_info = whos('-file', ofdm_signal_file);
var_names = {file_info.name};

if ~ismember('radar_params', var_names) || ...
    % 缺少参数 → 补充保存
    save(ofdm_signal_file, 'radar_params', 'music_params', 'base_pos', '-append');
end
```

## 🔍 验证一致性

运行以下MATLAB代码验证5个脚本使用了相同的OFDM数据：

```matlab
% 加载共享数据
load('snr_simulation_results/ofdm_signal_data.mat');

% 显示关键参数
fprintf('=== OFDM信号参数 ===\n');
fprintf('IFFT_length: %d\n', ofdm_params.IFFT_length);
fprintf('symbols_per_carrier: %d\n', ofdm_params.symbols_per_carrier);
fprintf('delta_f: %.2f Hz\n', ofdm_params.delta_f);
fprintf('f_c: %.2e Hz\n', ofdm_params.f_c);
fprintf('\n');

fprintf('=== 雷达参数 ===\n');
fprintf('天线阵列: %d × %d\n', radar_params.M, radar_params.N);
fprintf('天线间距: %.6f m (%.2f × lambda)\n', radar_params.d, radar_params.d/radar_params.lambda);
fprintf('\n');

fprintf('=== 数据尺寸 ===\n');
fprintf('windowed_Tx_data: %s\n', mat2str(size(windowed_Tx_data)));
fprintf('complex_carrier_matrix: %s\n', mat2str(size(complex_carrier_matrix)));
fprintf('\n');

% 计算数据的MD5哈希值（需要 Communications Toolbox）
% 或者简单地检查数据统计量
fprintf('=== 数据统计量（用于验证一致性）===\n');
fprintf('windowed_Tx_data 均值: %.6e + %.6ei\n', mean(windowed_Tx_data(:), 'omitnan'));
fprintf('windowed_Tx_data 能量: %.6e\n', sum(abs(windowed_Tx_data(:)).^2));
```

## 🚨 注意事项

### ⚠️ 不要手动删除共享文件

如果在运行过程中删除 `ofdm_signal_data.mat`，后续脚本会重新生成**新的OFDM信号**，导致数据不一致！

### ⚠️ 确保所有脚本使用相同的参数

以下参数在所有5个脚本中必须保持一致：
- `base_pos = [14, 100, 20]`
- `radar_params.*`（所有字段）
- `music_params.*`（所有字段）

### ⚠️ 启动顺序无关

无论哪个脚本先启动，都能保证使用相同的OFDM数据：
- 先启动的脚本会生成并保存数据
- 后启动的脚本会加载已有数据

## 📊 推荐运行顺序

虽然启动顺序不影响数据一致性，但为了便于监控和调试，推荐：

### 方案A：串行启动（间隔5-10秒）
```batch
start matlab -batch "run_single_snr_batch_inf"
timeout /t 10
start matlab -batch "run_single_snr_batch_10"
timeout /t 10
start matlab -batch "run_single_snr_batch_0"
timeout /t 10
start matlab -batch "run_single_snr_batch_minus10"
timeout /t 10
start matlab -batch "run_single_snr_batch_minus20"
```

**优点**：
- 第一个脚本有时间生成和保存OFDM数据
- 避免多个脚本同时尝试生成数据
- 便于查看日志输出

### 方案B：同时启动（批处理文件）
```batch
start matlab -batch "run_single_snr_batch_inf"
start matlab -batch "run_single_snr_batch_10"
start matlab -batch "run_single_snr_batch_0"
start matlab -batch "run_single_snr_batch_minus10"
start matlab -batch "run_single_snr_batch_minus20"
```

**注意**：即使同时启动，MATLAB的文件I/O也是线程安全的，不会产生冲突。

## 🔧 故障排除

### 问题1：多个脚本都在生成OFDM信号

**可能原因**：脚本启动太快，第一个脚本还没保存完成

**解决方案**：
1. 等待第一个脚本完成OFDM信号保存（约10-30秒）
2. 检查是否生成了 `ofdm_signal_data.mat` 文件
3. 如果已生成，停止其他脚本并重新启动

### 问题2：提示参数不匹配

**可能原因**：不同脚本中的 `radar_params` 或 `music_params` 设置不一致

**解决方案**：
1. 对比所有5个脚本的参数设置部分（Section 2）
2. 确保所有参数完全一致
3. 删除 `ofdm_signal_data.mat` 并重新运行

### 问题3：加载文件失败

**可能原因**：文件损坏或不完整

**解决方案**：
```matlab
% 尝试加载并检查
try
    load('snr_simulation_results/ofdm_signal_data.mat');
    fprintf('文件加载成功！\n');
catch ME
    fprintf('文件损坏，需要重新生成\n');
    delete('snr_simulation_results/ofdm_signal_data.mat');
end
```

## 📝 修改记录

| 日期 | 修改内容 | 影响的文件 |
|------|----------|-----------|
| 2025-11-08 | 添加OFDM数据共享机制 | 所有 `run_single_snr_batch_*.m` |
| 2025-11-08 | 添加参数完整性检查 | 所有 `run_single_snr_batch_*.m` |
| 2025-11-08 | 移除重复保存逻辑 | 所有 `run_single_snr_batch_*.m` |

## 🎯 总结

通过这次修改：
- ✅ 所有5个进程使用**完全相同**的OFDM信号
- ✅ 避免重复生成OFDM信号，节省时间
- ✅ 确保实验结果的一致性和可比性
- ✅ 支持任意启动顺序
- ✅ 自动处理参数补充和完整性检查

---

如有疑问，请参考 `README_single_snr_batch.md` 或 `QUICKSTART_5_PROCESSES.md`
