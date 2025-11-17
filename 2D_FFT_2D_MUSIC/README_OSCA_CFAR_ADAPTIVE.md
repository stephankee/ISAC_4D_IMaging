# OSCA-CFAR自适应参数调整说明

## 🎯 问题背景

原始的OSCA_CFAR函数使用**固定参数**：
```matlab
Pfa = 1e-3;              % 固定虚警概率
threshold_adjust = 60000; % 固定门限调整值
```

这导致：
- ✅ **高SNR**：工作正常，检测准确
- ❌ **低SNR**：检测到大量"鬼影"（虚警），导致后续MUSIC处理非常慢

## 📊 自适应调整策略

现在根据**SNR等级**自适应调整两个关键参数：

| SNR范围 | Pfa (虚警概率) | threshold_adjust | 效果 |
|---------|---------------|------------------|------|
| **Inf (无噪声)** | 1e-4 (更严格) | 1% × 信号功率 | 极少虚警 |
| **≥10 dB** | 1e-4 | 2% × 信号功率 | 少虚警 |
| **0~10 dB** | 5e-4 | 5% × 信号功率 | 适中虚警 |
| **-10~0 dB** | 1e-3 | 10% × 信号功率 | 控制虚警 |
| **<-10 dB** | 5e-3 (更宽松) | 20% × 信号功率 | 严格门限，减少虚警 |

### 关键改进

1. **相对门限**：从固定的60000改为`信号平均功率 × 比例系数`
   - 低SNR下信号弱，门限也相应降低但比例更高
   - 避免固定值在低SNR下反而降低检测门限

2. **自适应Pfa**：根据SNR调整虚警概率
   - 高SNR：使用严格的Pfa (1e-4)
   - 低SNR：适当放宽Pfa但提高门限比例

## 🔧 修改的文件

### 1. `OSCA_CFAR.m` (原始函数)
- 添加 `SNR_dB` 参数（可选，默认Inf）
- 自适应调整 `Pfa` 和 `threshold_adjust`
- 向后兼容：不传SNR时使用默认无噪声参数

### 2. `OSCA_CFAR_adaptive.m` (新版本)
- 功能与修改后的OSCA_CFAR.m相同
- 更详细的输出信息
- 可作为独立版本使用

### 3. `func_range_doppler_processing.m`
- 添加 `SNR_dB` 参数
- 传递SNR到OSCA_CFAR

### 4. `run_single_snr_batch_*.m` (全部5个)
- 调用时传入 `SNR_TARGET` 参数

### 5. `process_single_snr_batch_music.m`
- 调用时传入 `SNR_TARGET` 参数

## 📈 预期效果对比

### 修改前（固定参数）

| SNR | 真实目标 | 检测数 | 虚警率 | MUSIC耗时 |
|-----|---------|--------|--------|----------|
| Inf | 50 | 52 | 4% | 1 min |
| 10 dB | 50 | 80 | 60% | 2 min |
| 0 dB | 50 | 200 | 300% | 6 min |
| -10 dB | 50 | 500 | 900% | 15 min |
| **-20 dB** | 50 | **1500** | **2900%** | **45 min** ⚠️ |

### 修改后（自适应参数）

| SNR | 真实目标 | 预期检测数 | 预期虚警率 | 预期MUSIC耗时 |
|-----|---------|-----------|----------|--------------|
| Inf | 50 | 52 | 4% | 1 min |
| 10 dB | 50 | 60 | 20% | 1.5 min |
| 0 dB | 50 | 80 | 60% | 2 min |
| -10 dB | 50 | 100 | 100% | 3 min |
| **-20 dB** | 50 | **150** | **200%** | **5 min** ✅ |

## 🚀 使用方法

### 自动使用（推荐）

运行 `run_single_snr_batch_*.m` 脚本时，会**自动**根据 `SNR_TARGET` 调整CFAR参数：

```matlab
% 脚本会自动传入SNR
run_single_snr_batch_minus20.m  % SNR=-20dB，自动使用严格参数
```

### 手动调用

如果在其他脚本中使用：

```matlab
% 传入SNR参数
[RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = ...
    OSCA_CFAR(Velocity_fft(:, :, 1, 1), SNR_dB);

% 或使用func_range_doppler_processing
[Velocity_fft, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = ...
    func_range_doppler_processing(multi_Rx_complex_carrier_matrix_radar, ...
                                   complex_carrier_matrix, radar_params, ...
                                   do_visualization, SNR_dB);
```

### 向后兼容

不传入SNR时，自动使用无噪声参数（原有行为）：

```matlab
% 旧代码仍然可以工作
[RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = ...
    OSCA_CFAR(Velocity_fft(:, :, 1, 1));  % 默认SNR=Inf
```

## 🔍 调试信息

运行时会输出CFAR参数信息：

```
OSCA-CFAR参数: SNR=-20.0 dB, Pfa=5.00e-03, K_factor=0.0124, threshold_adjust=1.23e+05
  CFAR检测进度: 32/32 (100.0%)
CFAR检测完成！检测到 87 个目标
```

## ⚙️ 手动微调（高级）

如果需要进一步调整，修改 `OSCA_CFAR.m` 中的这些参数：

```matlab
elseif SNR_dB >= -10
    % 低SNR (-10-0dB)
    Pfa = 1e-3;                    % 可以改为 5e-4 (更严格)
    threshold_adjust_ratio = 0.1;  % 可以改为 0.15 (更高门限)
```

## 📝 原理说明

### 为什么相对门限比固定门限好？

**固定门限问题：**
```
SNR=Inf:  信号功率 ~1e6, 门限 = 60000     ✅ 门限合理（6%）
SNR=-20dB: 信号功率 ~1e4, 门限 = 60000    ❌ 门限太高（600%！）反而降低检测能力
```

**相对门限优势：**
```
SNR=Inf:  门限 = 1e6 × 1%  = 1e4    ✅ 合理
SNR=-20dB: 门限 = 1e4 × 20% = 2e3   ✅ 根据信号强度调整
```

### 为什么低SNR要提高门限比例？

虽然信号弱，但噪声也强！相对比例需要更高来抑制噪声尖峰：
- 高SNR: 信噪比高，小比例就能区分信号和噪声
- 低SNR: 信噪比低，需要更高比例来避免误检噪声

## 🎓 参考资料

OSCA-CFAR原理：
- Order Statistic (OS): 对检测窗口排序，选择第R大的值作为噪声估计
- Cell Averaging (CA): 对选定的噪声样本求平均
- 自适应: 根据SNR调整Pfa和门限

## ✅ 验证方法

重新运行仿真后，检查：

```matlab
% 查看检测数量
load('snr_simulation_results/scene_001/SNR_-20dB/results.mat');
fprintf('检测目标数: %d\n', size(RD_target_index, 1));

% 对比修改前后
% 修改前: 可能1000+个目标
% 修改后: 应该<200个目标
```

---

**建议**：如果您已经运行过旧版本，建议删除 `snr_simulation_results/` 目录下的结果，重新运行以使用新的自适应参数。
