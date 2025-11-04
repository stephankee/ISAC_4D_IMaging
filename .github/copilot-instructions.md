## 快速目标
本仓库实现基于毫米波 OFDM 的 ISAC 成像（2D/4D FFT + MUSIC 算法）及若干工具脚本。AI 助手的目标是快速定位主要处理管线、对 MATLAB/ Python 文件做小而安全的改进、以及提供可复现的运行/调试说明。

## 关键目录与“为什么”
- `2D_FFT_2D_MUSIC/`：2D FFT + 2D MUSIC 的参考实现与可视化，入口脚本：`ref_ofdm_imaging_2DFFT_2DMUSIC.m`。多数信号处理函数（qam/demoduqam、*_CFAR.m、environment*.m）都在此目录。
- `4D_FFT/`：4D FFT 的参考实现，入口脚本：`ref_ofdm_imaging_4DFFT.m`。结构与 2D 目录对称。
- `Metric/`：Python 实现的评价脚本 `Metric.py`，读取 `Metric/data/*.mat`，用于度量成像结果与真值的差异。

设计动机简述：MATLAB 脚本聚焦“研究/仿真流水线”（生成信号 -> 环境散射器 -> 信号处理 -> CFAR 检测 -> 成像/可视化）。Python 的 Metric 用于离线评估。图像/结果以 `.fig` 或 `.png` 存在于各目录的 `image/` 子目录。

## 运行与调试要点（可复现的最小命令）
- MATLAB (推荐)：打开 MATLAB，将工作目录切换到对应子目录，然后运行入口脚本，例如：
  - 2D: 在 MATLAB 命令行中运行 `run('/absolute/path/ISAC_4D_IMaging/2D_FFT_2D_MUSIC/ref_ofdm_imaging_2DFFT_2DMUSIC.m')` 或在 GUI 中打开并点击 Run。
  - 4D: 同理运行 `ref_ofdm_imaging_4DFFT.m`。
- Octave：部分简单脚本可在 Octave 中运行，但某些 MATLAB 专有函数或 .fig 文件可能不兼容——在改动前先用小脚本验证兼容性。
- 评价（Python）：跳到 `Metric/` 并确保依赖已安装（示例）：
  - pip 安装依赖：`pip install scipy matplotlib numpy opencv-python imageio shapely`
  - 运行：`python Metric.py`（会读取 `Metric/data/pos_all.mat` 与 `Metric/data/pos_all_true.mat`）。

## 项目特有约定与模式（重要，修改前请遵守）
- 文件命名约定：调制/解调相关为 `qam*.m` / `demoduqam*.m`；检测为 `*_CFAR.m`；环境/展示为 `environment*.m` / `environment_disp.m`。
- 入口脚本通常以 `ref_ofdm_imaging_*` 命名并作为“跑通流程”的脚本（不是纯函数库）。对外接口多为脚本级别的变量共享，而非封装良好的函数调用链。
- 结果产物：`.fig`（MATLAB figure）与目录下的 PNG。不要将二进制 `.fig` 文件重写为文本；若需修改可生成新图并保存在 `image/` 子目录。

## 编辑与 PR 指南（对 AI 代理的具体建议）
- 优先级：小而明确的改动（修复明显错误、改进注释、添加可复现的运行示例）> 重构 > 大规模 API 变更。
- 不要移动或删除 `.mat` / `.fig` 数据文件；读写路径通常为相对路径（注意工作目录）。
- 如果要新增依赖（Python 或 MATLAB 工具箱），在 PR 描述中明确说明所需环境及安装命令。
- 测试：仓库没有自动化单元测试框架。任何修改请在本地用 MATLAB/Octave（针对 m 文件）或 Python（针对 Metric.py）运行一次主流程来验证没有语法/运行错误，并把最小复现步骤写入 PR 描述。

## 安全与交互边界
- 避免修改实验结果数据文件（`Metric/data/*.mat`、`*/image/*`）；若需要新数据，新增文件并在 `image/` 或 `Metric/data/` 中存放，注明来源。

## 代码示例（快速定位）
- 运行 2D 主流程：`2D_FFT_2D_MUSIC/ref_ofdm_imaging_2DFFT_2DMUSIC.m`
- 运行 4D 主流程：`4D_FFT/ref_ofdm_imaging_4DFFT.m`
- Metric 评估：`Metric/Metric.py`（依赖 scipy, shapely 等）

## 若信息不明确，请询问用户的优先级
- 是否优先保持 matlab 脚本风格与可交互性？（多数脚本为研究代码）
- 是否接受将入口脚本改为函数式接口以便测试/复用？

—— 结束（如需我把某部分扩展为“为贡献者准备的入门步骤 / 环境配置脚本”，请告诉我你希望包含的细节）
