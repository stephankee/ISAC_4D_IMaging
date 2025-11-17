# Range-Doppler结果可视化脚本使用说明

## 📊 脚本功能

`visualize_all_results.m` 用于批量生成所有场景在不同SNR等级下的Range-Doppler可视化图像。

## 🎯 生成的可视化内容

对每个场景的每个SNR等级，生成3种图像：

1. **热力图（Heatmap）** - Range-Doppler二维热力图，标记检测到的目标
2. **3D检测结果图** - CFAR检测后的3D网格图
3. **3D门限图** - CFAR检测门限的3D网格图

## 📁 输出结构

```
snr_simulation_results/
├── scene_001/
│   ├── visualizations/              ← 新建的可视化目录
│   │   ├── scene_001_heatmap_SNR_Inf.png
│   │   ├── scene_001_3d_detection_SNR_Inf.png
│   │   ├── scene_001_3d_threshold_SNR_Inf.png
│   │   ├── scene_001_heatmap_SNR_10dB.png
│   │   ├── scene_001_3d_detection_SNR_10dB.png
│   │   ├── scene_001_3d_threshold_SNR_10dB.png
│   │   └── ... (其他SNR等级)
│   ├── SNR_Inf/
│   ├── SNR_10dB/
│   └── ...
└── scene_002/
    └── visualizations/
        └── ...
```

## 🚀 使用方法

### 基本运行

在MATLAB中运行：
```matlab
run visualize_all_results.m
```

### 配置选项

脚本顶部有3个可配置参数：

```matlab
save_figures = true;   % 是否保存图片（true/false）
show_figures = false;  % 是否显示图形窗口（true/false）
image_format = 'png';  % 图片格式（'png'/'jpg'/'fig'）
```

#### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `save_figures` | `true` | 是否保存图片到文件 |
| `show_figures` | `false` | 是否显示图形窗口（批量处理建议关闭） |
| `image_format` | `'png'` | 图片格式：`'png'`（推荐）、`'jpg'`、`'fig'`（MATLAB格式） |

### 使用场景

#### 场景1：批量生成图片（推荐）
```matlab
save_figures = true;
show_figures = false;  % 不显示窗口，加快速度
image_format = 'png';
```
- ✅ 快速批量生成
- ✅ 节省时间
- ✅ 后台运行

#### 场景2：交互式查看
```matlab
save_figures = false;
show_figures = true;   % 显示窗口，可以交互查看
image_format = 'png';
```
- ✅ 实时查看每个图像
- ✅ 可以手动调整图形
- ⚠️ 速度较慢

#### 场景3：保存为MATLAB格式
```matlab
save_figures = true;
show_figures = false;
image_format = 'fig';  % 保存为.fig格式，可在MATLAB中重新编辑
```
- ✅ 可重新编辑
- ✅ 保留完整数据
- ⚠️ 文件较大

## 📊 输出示例

### 控制台输出

```
========================================
批量可视化Range-Doppler结果
========================================

加载共享参数...
参数加载完成！
===========================================
扫描场景目录...
找到 10 个场景
===========================================

========================================
处理场景 1/10: scene_001
========================================
  [可视化] SNR_Inf (SNR=Inf dB, BER=0.000000, 检测目标数=15)
  [可视化] SNR_10dB (SNR=10.0 dB, BER=0.001234, 检测目标数=14)
  [可视化] SNR_0dB (SNR=0.0 dB, BER=0.005678, 检测目标数=13)
  [可视化] SNR_-10dB (SNR=-10.0 dB, BER=0.023456, 检测目标数=11)
  [可视化] SNR_-20dB (SNR=-20.0 dB, BER=0.089012, 检测目标数=8)
场景 scene_001 可视化完成

...

========================================
批量可视化完成！
========================================
总场景数: 10
总SNR等级数: 5
成功可视化: 50 个
跳过/失败: 0 个
总运行时间: 123.45 秒 (约 2.1 分钟)
平均每个可视化: 2.47 秒

图片已保存至各场景的 visualizations/ 子目录
图片格式: png
========================================
```

## 🎨 图像说明

### 1. 热力图（Heatmap）

- **X轴**：Range Bin（距离单元）
- **Y轴**：Velocity Bin（速度单元）
- **颜色**：信号强度
- **红圈**：CFAR检测到的目标位置

### 2. 3D检测结果图

- **X轴**：距离 (m)
- **Y轴**：速度 (m/s)
- **Z轴**：信号幅值
- **显示范围**：距离50-150m，速度-50到50 m/s

### 3. 3D门限图

- 显示OSCA-CFAR算法计算的自适应检测门限
- 坐标轴与检测结果图相同

## 📈 性能估算

| 场景数 | SNR等级 | 预计时间 |
|--------|---------|----------|
| 10 | 5 | ~2-3 分钟 |
| 100 | 5 | ~20-30 分钟 |
| 1000 | 5 | ~3-5 小时 |

*时间取决于硬件性能和图片格式*

## 💡 使用技巧

### 技巧1：先小批量测试
```matlab
% 修改脚本，只处理前2个场景
num_scenes = min(2, length(scene_dirs));
```

### 技巧2：只处理特定SNR等级
```matlab
% 只可视化无噪声和最低SNR的结果
snr_levels = {'SNR_Inf', 'SNR_-20dB'};
```

### 技巧3：并行处理
如果场景很多，可以修改脚本使用 `parfor` 并行生成图像。

### 技巧4：检查特定场景
```matlab
% 在脚本开头添加场景过滤
target_scenes = {'scene_001', 'scene_005', 'scene_010'};
% 在循环中添加：
if ~ismember(scene_name, target_scenes)
    continue;
end
```

## 🔍 故障排除

### 问题1：内存不足

**症状**：MATLAB提示内存错误

**解决方案**：
- 设置 `show_figures = false`
- 使用 `'jpg'` 格式代替 `'png'`
- 每处理几个场景后添加 `close all; drawnow;`

### 问题2：图片不清晰

**解决方案**：
```matlab
% 在保存图片前添加分辨率设置
set(gcf, 'Position', [100, 100, 1200, 800]);
saveas(fig1, filename, 'png');
% 或使用
print(fig1, filename, '-dpng', '-r300');  % 300 DPI
```

### 问题3：某些场景跳过

**原因**：对应的 `results.mat` 文件不存在或损坏

**解决方案**：
- 检查脚本输出的跳过信息
- 重新运行对应场景的仿真脚本

## 📝 后续分析

生成图片后，可以：

1. **制作对比图**：使用图像处理软件（如Photoshop、GIMP）将不同SNR的结果拼接对比
2. **制作动画**：使用MATLAB的 `VideoWriter` 将多个场景制作成视频
3. **统计分析**：提取 `RD_target_index` 数据，分析检测性能随SNR的变化

## 🔗 相关脚本

- `run_single_snr_batch_*.m` - 生成原始结果数据
- `monitor_progress.ps1` - 监控仿真进度
- `func_range_doppler_processing.m` - Range-Doppler处理函数

---

**提示**：如果需要自定义可视化效果，可以直接修改 `visualize_all_results.m` 脚本中的绘图参数。
