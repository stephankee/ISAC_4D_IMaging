%% 模块化OFDM ISAC成像主脚本
% 本脚本将原v1_test_ofdm_imaging_2DFFT_2DMUSIC.m拆分为多个功能模块
% 便于后续扩展和维护

clc;
clear;
close all;

%% ==================== Section 1: OFDM信号生成 ====================
disp('=== Section 1: OFDM信号生成 ===');

% 调用OFDM信号生成函数
[windowed_Tx_data, baseband_out, complex_carrier_matrix, ofdm_params] = ...
    func_generate_ofdm_signal();

% 从ofdm_params提取常用参数
IFFT_length = ofdm_params.IFFT_length;
symbols_per_carrier = ofdm_params.symbols_per_carrier;
GI = ofdm_params.GI;
GIP = ofdm_params.GIP;
delta_f = ofdm_params.delta_f;
c = ofdm_params.c;
f_c = ofdm_params.f_c;
T_OFDM = ofdm_params.T_OFDM;
PrefixRatio = ofdm_params.PrefixRatio;

%% ==================== 第二部分：参数设置 ====================
disp('=== 设置雷达与MUSIC参数 ===');

% 多信噪比仿真设置
SNR_list = [Inf, -20, -10, 0, 10, 20];

% 基站天线位置
base_pos = [14, 100, 20];

% 雷达参数结构体
radar_params = struct();
radar_params.M = 16;                    % x方向阵元数
radar_params.N = 16;                    % y方向阵元数
radar_params.lambda = c / f_c;          % 波长
radar_params.K_sub = 8;                 % 子阵元数目
radar_params.d = radar_params.lambda/2; % 天线阵元间距
radar_params.c = c;
radar_params.f_c = f_c;
radar_params.delta_f = delta_f;
radar_params.IFFT_length = IFFT_length;
radar_params.symbols_per_carrier = symbols_per_carrier;
radar_params.T_OFDM = 1/delta_f * (1 + PrefixRatio);

% MUSIC算法参数结构体
music_params = struct();
music_params.space = 0.1;               % 搜索粒度
music_params.theta_head_offset = 60;
music_params.theta_back_offset = 60;
music_params.faii_head_offset = 60;
music_params.faii_back_offset = 90;

% 场景文件目录路径
scene_dir = '/home/jaz/code/ISAC_4D_IMaging/2D_FFT_2D_MUSIC/scenario_1/mat_files/';

disp('参数设置完毕！');
disp('===========================================');

%% ==================== 第三部分：加载所有场景文件 ====================
disp('=== 加载场景目录中的所有.mat文件 ===');

% 获取目录中所有的.mat文件
mat_files = dir(fullfile(scene_dir, '*.mat'));
num_scenes = length(mat_files);

fprintf('在目录 %s 中找到 %d 个场景文件\n', scene_dir, num_scenes);

% 预先加载所有场景的数据
scene_data_list = cell(num_scenes, 1);
for scene_idx = 1:num_scenes
    scene_file = fullfile(scene_dir, mat_files(scene_idx).name);
    fprintf('正在加载场景 %d/%d: %s\n', scene_idx, num_scenes, mat_files(scene_idx).name);
    [environment_point, point_info] = func_load_scene_and_compute_params(scene_file, base_pos);
    scene_data_list{scene_idx} = struct('filename', mat_files(scene_idx).name, ...
                                         'environment_point', environment_point, ...
                                         'point_info', point_info);
end

fprintf('所有场景加载完毕！共 %d 个场景\n', num_scenes);
disp('===========================================');

%% ==================== 第四部分：多场景多SNR仿真循环（并行版本）====================
disp('=== 开始多场景多SNR仿真循环（并行） ===');

% 启动并行池（如果尚未启动）
poolobj = gcp('nocreate'); % 检查是否已有并行池
if isempty(poolobj)
    parpool; % 启动并行池，使用默认核心数
    fprintf('已启动并行池，工作进程数: %d\n', gcp().NumWorkers);
else
    fprintf('并行池已存在，工作进程数: %d\n', poolobj.NumWorkers);
end

% 运行时间统计初始化
total_start_time = tic;
scene_times = zeros(num_scenes, 1);
total_simulations = num_scenes * length(SNR_list);

fprintf('\n总仿真任务数: %d 个场景 × %d 个SNR等级 = %d 个任务\n', ...
        num_scenes, length(SNR_list), total_simulations);

% 创建输出目录结构
% 新结构：
% snr_simulation_results/
%   ├── ofdm_signal_data.mat (OFDM信号数据，只保存一份)
%   ├── scene_001/
%   │   ├── scene_info.mat (场景信息)
%   │   ├── SNR_Inf/
%   │   │   └── results.mat
%   │   └── SNR_-20dB/
%   │       └── results.mat
%   └── scene_002/
%       └── ...

output_base_dir = './snr_simulation_results';
if ~exist(output_base_dir, 'dir')
    mkdir(output_base_dir);
end

% 保存OFDM信号数据（只保存一次）
ofdm_signal_file = fullfile(output_base_dir, 'ofdm_signal_data.mat');
if ~exist(ofdm_signal_file, 'file')
    fprintf('保存OFDM信号数据到: %s\n', ofdm_signal_file);
    save(ofdm_signal_file, 'windowed_Tx_data', 'baseband_out', 'complex_carrier_matrix', 'ofdm_params', ...
         'radar_params', 'music_params', 'base_pos');
    fprintf('OFDM信号数据已保存\n');
else
    fprintf('OFDM信号数据已存在，跳过保存\n');
end

% 外层循环：遍历每个场景
for scene_idx = 1:num_scenes
    scene_start_time = tic; % 记录当前场景开始时间
    
    scene_data = scene_data_list{scene_idx};
    scene_name = scene_data.filename;
    point_info = scene_data.point_info;
    
    % 移除.mat后缀作为场景名称
    [~, scene_basename, ~] = fileparts(scene_name);
    
    fprintf('\n========================================\n');
    fprintf('正在处理场景 %d/%d: %s\n', scene_idx, num_scenes, scene_name);
    fprintf('========================================\n');
    
    % 为当前场景创建输出目录
    scene_output_dir = fullfile(output_base_dir, scene_basename);
    if ~exist(scene_output_dir, 'dir')
        mkdir(scene_output_dir);
    end
    
    % 保存场景信息（只保存一次）
    scene_info_file = fullfile(scene_output_dir, 'scene_info.mat');
    if ~exist(scene_info_file, 'file')
        environment_point = scene_data.environment_point;
        save(scene_info_file, 'scene_name', 'environment_point', 'point_info');
        fprintf('场景信息已保存: %s\n', scene_info_file);
    end
    
    % 为每个SNR等级创建子文件夹
    for snr_idx = 1:length(SNR_list)
        SNR_val = SNR_list(snr_idx);
        if isinf(SNR_val)
            folder_name = sprintf('SNR_Inf');
        else
            folder_name = sprintf('SNR_%ddB', SNR_val);
        end
        snr_folder = fullfile(scene_output_dir, folder_name);
        if ~exist(snr_folder, 'dir')
            mkdir(snr_folder);
        end
    end
    
    % 内层循环：使用parfor并行处理当前场景的多个SNR
    parfor snr_idx = 1:length(SNR_list)
        SNR = SNR_list(snr_idx);
        fprintf('\n--- 场景 %s | SNR = %s dB ---\n', scene_basename, num2str(SNR));
        
        % 步骤1：添加噪声
        Rx_data = func_add_noise(windowed_Tx_data, SNR);
        
        % 步骤2：OFDM解调与BER计算
        [Rx_complex_carrier_matrix, BER] = func_ofdm_demodulation(Rx_data, baseband_out, IFFT_length, symbols_per_carrier, GI, GIP);
        
        % 步骤3：生成雷达回波信号
        multi_Rx_complex_carrier_matrix_radar = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params);
        
        % 步骤4：Range-Doppler处理与CFAR检测（禁用可视化）
        do_visualization = false; % 并行模式下不绘图
        [Velocity_fft, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = ...
            func_range_doppler_processing(multi_Rx_complex_carrier_matrix_radar, complex_carrier_matrix, radar_params, do_visualization);
        
        fprintf('场景 %s | SNR %s dB 检测到 %d 个Range-Doppler目标\n', scene_basename, num2str(SNR), size(RD_target_index, 1));
        
        % 保存当前场景和SNR的结果到对应文件夹（只保存关键数据）
        if isinf(SNR)
            folder_name = sprintf('SNR_Inf');
        else
            folder_name = sprintf('SNR_%ddB', SNR);
        end
        snr_folder = fullfile(scene_output_dir, folder_name);
        save_file = fullfile(snr_folder, 'results.mat');
        
        % 只保存第一个天线的FFT结果以节省空间（其他天线在后续MUSIC处理时重新计算）
        Velocity_fft_antenna_1_1 = Velocity_fft(:, :, 1, 1);
        parsave_compact(save_file, SNR, BER, Velocity_fft_antenna_1_1, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs);
        fprintf('结果已保存至: %s\n', save_file);
    end
    
    % 记录当前场景的运行时间
    scene_times(scene_idx) = toc(scene_start_time);
    
    % 计算时间统计
    avg_time_per_scene = mean(scene_times(1:scene_idx));
    remaining_scenes = num_scenes - scene_idx;
    estimated_remaining_time = avg_time_per_scene * remaining_scenes;
    
    fprintf('\n场景 %s 完成！耗时: %.2f 秒\n', scene_name, scene_times(scene_idx));
    fprintf('平均每场景耗时: %.2f 秒\n', avg_time_per_scene);
    
    if remaining_scenes > 0
        fprintf('剩余场景数: %d\n', remaining_scenes);
        fprintf('预计剩余时间: %.2f 秒 (约 %.1f 分钟)\n', ...
                estimated_remaining_time, estimated_remaining_time/60);
    end
    fprintf('========================================\n');
end

% 总体时间统计
total_elapsed_time = toc(total_start_time);

disp('===========================================');
disp('所有场景的多SNR仿真循环完毕！');
fprintf('\n========== 运行时间统计 ==========\n');
fprintf('总运行时间: %.2f 秒 (约 %.2f 分钟)\n', total_elapsed_time, total_elapsed_time/60);
fprintf('总任务数: %d 个 (场景数 %d × SNR等级 %d)\n', total_simulations, num_scenes, length(SNR_list));
fprintf('平均每场景耗时: %.2f 秒\n', mean(scene_times));
fprintf('平均每个SNR任务耗时: %.2f 秒\n', total_elapsed_time / total_simulations);
fprintf('最快场景耗时: %.2f 秒\n', min(scene_times));
fprintf('最慢场景耗时: %.2f 秒\n', max(scene_times));
fprintf('====================================\n');

%% ==================== 第五部分：2D MUSIC角度估计 ====================
% % 注意：这里使用最后一次SNR循环的结果进行角度估计
% disp('=== 开始2D MUSIC角度估计 ===');
% 
% [Angle_music_matrix, Angle_music_threshold_matrix, Angle_music_abs_matrix, A2_Angle_target_cell] = ...
%     func_2d_music_angle_estimation(Velocity_fft, RD_target_index, radar_params, music_params);
% 
% disp('===========================================');
% 
% %% ==================== 第六部分：目标位置重建 ====================
% disp('=== 重建目标位置 ===');
% 
% [pos_all, angle_all] = func_reconstruct_target_positions(RD_target_index, A2_Angle_target_cell, base_pos, radar_params, music_params);
% 
% fprintf('重建了 %d 个目标的位置信息\n', size(pos_all, 1));
% disp('===========================================');
% 
% %% ==================== 第七部分：计算真实位置（用于对比）====================
% disp('=== 计算真实目标位置 ===');
% 
% pos_all_true = [];
% for i = 1:size(point_info, 1)
%     theta_true = point_info(i, 3);
%     faii_true = point_info(i, 4);
%     R_true = point_info(i, 1);
%     v_true = point_info(i, 2);
%     
%     % 恢复笛卡尔坐标系信息
%     pos_z_true = base_pos(3) - R_true * cos(faii_true);
%     pos_x_true = base_pos(1) + R_true * sin(faii_true) * cos(theta_true);
%     pos_y_true = base_pos(2) - R_true * sin(faii_true) * sin(theta_true);
%     
%     pos_all_true = [pos_all_true; pos_x_true pos_y_true pos_z_true v_true];
% end
% 
% disp('===========================================');
% 
% %% ==================== 第八部分：结果可视化 ====================
% disp('=== 可视化结果 ===');
% 
% func_visualize_results(pos_all, pos_all_true);
% 
% disp('===========================================');
% disp('所有处理完毕！');
