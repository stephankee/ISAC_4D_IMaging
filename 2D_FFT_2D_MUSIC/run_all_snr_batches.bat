@echo off
REM 批量启动5个MATLAB进程，分别处理不同SNR等级的仿真
REM 每个进程会处理所有场景，但只针对一个特定的SNR等级

echo ========================================
echo 批量启动SNR仿真任务
echo ========================================
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"
echo 当前工作目录: %CD%
echo.

REM 检查必要的脚本文件是否存在
echo 检查脚本文件...

if not exist "run_single_snr_batch_inf.m" (
    echo [错误] 未找到 run_single_snr_batch_inf.m
    echo 请先复制并修改 run_single_snr_batch.m 脚本
    pause
    exit /b 1
)

if not exist "run_single_snr_batch_minus20.m" (
    echo [错误] 未找到 run_single_snr_batch_minus20.m
    echo 请先复制并修改 run_single_snr_batch.m 脚本
    pause
    exit /b 1
)

if not exist "run_single_snr_batch_minus10.m" (
    echo [错误] 未找到 run_single_snr_batch_minus10.m
    echo 请先复制并修改 run_single_snr_batch.m 脚本
    pause
    exit /b 1
)

if not exist "run_single_snr_batch_0.m" (
    echo [错误] 未找到 run_single_snr_batch_0.m
    echo 请先复制并修改 run_single_snr_batch.m 脚本
    pause
    exit /b 1
)

if not exist "run_single_snr_batch_10.m" (
    echo [错误] 未找到 run_single_snr_batch_10.m
    echo 请先复制并修改 run_single_snr_batch.m 脚本
    pause
    exit /b 1
)

echo 所有脚本文件检查完毕！
echo.

echo ========================================
echo 准备启动5个MATLAB进程
echo ========================================
echo.
echo 这将占用较多系统资源，请确保：
echo 1. 有足够的内存（建议至少32GB）
echo 2. CPU性能足够（建议至少8核）
echo 3. 磁盘空间充足（每个场景约数百MB）
echo.
echo 按任意键继续，或关闭窗口取消...
pause > nul

echo.
echo 正在启动MATLAB进程...
echo.

REM 启动第1个进程 - SNR = Inf
echo [1/5] 启动 SNR = Inf 处理进程...
start "MATLAB-SNR_Inf" matlab -batch "run_single_snr_batch_inf"
timeout /t 3 > nul

REM 启动第2个进程 - SNR = -20 dB
echo [2/5] 启动 SNR = -20 dB 处理进程...
start "MATLAB-SNR_-20dB" matlab -batch "run_single_snr_batch_minus20"
timeout /t 3 > nul

REM 启动第3个进程 - SNR = -10 dB
echo [3/5] 启动 SNR = -10 dB 处理进程...
start "MATLAB-SNR_-10dB" matlab -batch "run_single_snr_batch_minus10"
timeout /t 3 > nul

REM 启动第4个进程 - SNR = 0 dB
echo [4/5] 启动 SNR = 0 dB 处理进程...
start "MATLAB-SNR_0dB" matlab -batch "run_single_snr_batch_0"
timeout /t 3 > nul

REM 启动第5个进程 - SNR = 10 dB
echo [5/5] 启动 SNR = 10 dB 处理进程...
start "MATLAB-SNR_10dB" matlab -batch "run_single_snr_batch_10"

echo.
echo ========================================
echo 所有MATLAB进程已启动！
echo ========================================
echo.
echo 5个MATLAB窗口应该已经打开，分别处理不同的SNR等级。
echo.
echo 监控提示：
echo - 每个MATLAB窗口会显示实时处理进度
echo - 完成后会在 snr_simulation_results 目录生成 completed_*.txt 标记文件
echo - 可以随时关闭本窗口，不影响MATLAB进程运行
echo.
echo 按任意键关闭本窗口...
pause > nul
