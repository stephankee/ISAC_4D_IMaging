%% 单场景MUSIC角度估计与位置重建脚本
% 本脚本用于对单个场景的特定SNR结果进行2D MUSIC角度估计
% 流程：
%   1. 加载共享OFDM信号和场景数据
%   2. 重新运行该场景的仿真（生成完整的Velocity_fft）
%   3. 加载已保存的RD_target_index（CFAR检测结果）
%   4. 执行2D MUSIC角度估计
%   5. 重建目标位置并可视化对比

clc;
clear;
close all;

%% ==================== 配置参数（需要手动设置）====================
% 指定要处理的场景和SNR等级
target_scene = 'scene_001';     % 场景名称（如：'scene_001', 'scene_002'等）
target_snr_level = 'SNR_-20dB';   % SNR等级（'SNR_Inf', 'SNR_10dB', 'SNR_0dB', 'SNR_-10dB', 'SNR_-20dB'）

% 结果目录
results_base_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results\';

fprintf('\n========================================\n');
fprintf('单场景MUSIC角度估计与位置重建\n');
fprintf('场景: %s\n', target_scene);
fprintf('SNR等级: %s\n', target_snr_level);
fprintf('========================================\n\n');

%% ==================== 第一部分：加载共享OFDM信号数据 ====================
disp('=== 加载共享OFDM信号数据 ===');

ofdm_signal_file = fullfile(results_base_dir, 'ofdm_signal_data.mat');
if ~exist(ofdm_signal_file, 'file')
    error('未找到OFDM信号数据文件: %s', ofdm_signal_file);
end

load(ofdm_signal_file, 'windowed_Tx_data', 'baseband_out', 'complex_carrier_matrix', ...
     'ofdm_params', 'radar_params', 'music_params', 'base_pos');

fprintf('OFDM信号数据加载成功\n');

% 提取常用参数
IFFT_length = ofdm_params.IFFT_length;
symbols_per_carrier = ofdm_params.symbols_per_carrier;
GI = ofdm_params.GI;
GIP = ofdm_params.GIP;

disp('===========================================');

%% ==================== 第二部分：加载场景信息 ====================
disp('=== 加载场景信息 ===');

scene_dir = fullfile(results_base_dir, target_scene);
scene_info_file = fullfile(scene_dir, 'scene_info.mat');

if ~exist(scene_info_file, 'file')
    error('未找到场景信息文件: %s', scene_info_file);
end

load(scene_info_file, 'scene_name', 'environment_point', 'point_info');

fprintf('场景名称: %s\n', scene_name);
fprintf('目标数量: %d\n', size(point_info, 1));

disp('===========================================');

%% ==================== 第三部分：加载已保存的CFAR检测结果 ====================
disp('=== 加载CFAR检测结果 ===');

result_file = fullfile(scene_dir, target_snr_level, 'results.mat');
if ~exist(result_file, 'file')
    error('未找到结果文件: %s', result_file);
end

load(result_file, 'SNR_TARGET', 'BER', 'RD_target_index', 'RD_detect_matrix_abs');

fprintf('SNR: %.1f dB\n', SNR_TARGET);
fprintf('BER: %.6f\n', BER);
fprintf('CFAR检测到的目标数: %d\n', size(RD_target_index, 1));

disp('===========================================');

%% ==================== 第四部分：重新运行仿真生成完整Velocity_fft ====================
disp('=== 重新运行仿真生成完整Velocity_fft ===');

% 步骤1：添加噪声
fprintf('步骤1: 添加噪声 (SNR = %.1f dB)\n', SNR_TARGET);
Rx_data = func_add_noise(windowed_Tx_data, SNR_TARGET);

% 步骤2：OFDM解调
fprintf('步骤2: OFDM解调\n');
[Rx_complex_carrier_matrix, ~] = func_ofdm_demodulation(Rx_data, baseband_out, IFFT_length, symbols_per_carrier, GI, GIP);

% 步骤3：生成雷达回波信号
fprintf('步骤3: 生成雷达回波信号\n');
multi_Rx_complex_carrier_matrix_radar = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params);

% 步骤4：Range-Doppler处理（不进行CFAR检测，不可视化）
fprintf('步骤4: Range-Doppler处理\n');
do_visualization = false;
[Velocity_fft, ~, ~, ~] = func_range_doppler_processing(multi_Rx_complex_carrier_matrix_radar, complex_carrier_matrix, radar_params, do_visualization);

fprintf('完整的Velocity_fft生成完毕！尺寸: %s\n', mat2str(size(Velocity_fft)));

disp('===========================================');

%% ==================== 第五部分：2D MUSIC角度估计 ====================
disp('=== 开始2D MUSIC角度估计 ===');

if isempty(RD_target_index)
    warning('未检测到任何目标，跳过MUSIC角度估计');
    return;
end

[Angle_music_matrix, Angle_music_threshold_matrix, Angle_music_abs_matrix, A2_Angle_target_cell] = ...
    func_2d_music_angle_estimation(Velocity_fft, RD_target_index, radar_params, music_params);

fprintf('MUSIC角度估计完成！估计了 %d 个目标的角度\n', length(A2_Angle_target_cell));

disp('===========================================');

%% ==================== 第六部分：目标位置重建 ====================
disp('=== 重建目标位置 ===');

[pos_all, angle_all] = func_reconstruct_target_positions(RD_target_index, A2_Angle_target_cell, base_pos, radar_params, music_params);

fprintf('成功重建 %d 个目标的位置信息\n', size(pos_all, 1));

disp('===========================================');

%% ==================== 第七部分：计算真实目标位置 ====================
disp('=== 计算真实目标位置 ===');

pos_all_true = [];
for i = 1:size(point_info, 1)
    theta_true = point_info(i, 3);
    faii_true = point_info(i, 4);
    R_true = point_info(i, 1);
    v_true = point_info(i, 2);
    
    % 恢复笛卡尔坐标系信息
    pos_z_true = base_pos(3) - R_true * cos(faii_true);
    pos_x_true = base_pos(1) + R_true * sin(faii_true) * cos(theta_true);
    pos_y_true = base_pos(2) - R_true * sin(faii_true) * sin(theta_true);
    
    pos_all_true = [pos_all_true; pos_x_true pos_y_true pos_z_true v_true];
end

fprintf('真实目标数量: %d\n', size(pos_all_true, 1));

disp('===========================================');

%% ==================== 第八部分：结果可视化 ====================
disp('=== 可视化结果 ===');

func_visualize_results(pos_all, pos_all_true);

% 在标题中添加场景和SNR信息
figure(gcf);
sgtitle(sprintf('场景: %s | SNR: %.1f dB | BER: %.6f\n检测目标: %d | 真实目标: %d', ...
                target_scene, SNR_TARGET, BER, size(pos_all, 1), size(pos_all_true, 1)), ...
                'Interpreter', 'none', 'FontSize', 12, 'FontWeight', 'bold');

disp('===========================================');

%% ==================== 第九部分：保存结果 ====================
disp('=== 保存角度估计结果 ===');

% 保存结果到对应的SNR文件夹
output_file = fullfile(scene_dir, target_snr_level, 'music_results.mat');
save(output_file, 'pos_all', 'angle_all', 'pos_all_true', ...
     'Angle_music_matrix', 'Angle_music_threshold_matrix', 'Angle_music_abs_matrix', ...
     'A2_Angle_target_cell', 'SNR_TARGET', 'BER');

fprintf('结果已保存至: %s\n', output_file);

% 保存可视化图像
if ~exist(fullfile(scene_dir, 'visualizations'), 'dir')
    mkdir(fullfile(scene_dir, 'visualizations'));
end

fig_file = fullfile(scene_dir, 'visualizations', sprintf('%s_position_comparison_%s.png', target_scene, target_snr_level));
saveas(gcf, fig_file);
fprintf('可视化图像已保存至: %s\n', fig_file);

disp('===========================================');

%% ==================== 第十部分：统计分析 ====================
disp('=== 统计分析 ===');

fprintf('\n--- 场景统计 ---\n');
fprintf('场景名称: %s\n', target_scene);
fprintf('SNR等级: %s (%.1f dB)\n', target_snr_level, SNR_TARGET);
fprintf('误码率: %.6f\n', BER);
fprintf('真实目标数: %d\n', size(pos_all_true, 1));
fprintf('检测目标数: %d\n', size(pos_all, 1));
fprintf('检测率: %.2f%%\n', 100 * size(pos_all, 1) / size(pos_all_true, 1));

% 计算位置误差（如果检测数量与真实数量相同）
if size(pos_all, 1) == size(pos_all_true, 1) && ~isempty(pos_all)
    fprintf('\n--- 位置误差分析 ---\n');
    
    % 简单的最近邻匹配
    pos_errors = zeros(size(pos_all, 1), 1);
    for i = 1:size(pos_all, 1)
        % 计算与所有真实目标的距离
        distances = sqrt(sum((pos_all_true(:, 1:3) - pos_all(i, 1:3)).^2, 2));
        [min_dist, ~] = min(distances);
        pos_errors(i) = min_dist;
    end
    
    fprintf('平均位置误差: %.3f m\n', mean(pos_errors));
    fprintf('最大位置误差: %.3f m\n', max(pos_errors));
    fprintf('最小位置误差: %.3f m\n', min(pos_errors));
    fprintf('位置误差标准差: %.3f m\n', std(pos_errors));
else
    fprintf('\n检测数量与真实数量不匹配，跳过误差分析\n');
end

disp('===========================================');
disp('所有处理完毕！');
