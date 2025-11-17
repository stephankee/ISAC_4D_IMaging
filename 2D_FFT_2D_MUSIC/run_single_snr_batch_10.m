%% 单SNR等级批量处理脚本模板
% 本脚本用于处理所有场景在特定SNR等级下的仿真
% 使用方法：复制此脚本5份，分别修改SNR_TARGET变量为不同的SNR值
% 例如：run_single_snr_batch_inf.m, run_single_snr_batch_minus20.m 等

clc;
clear;
close all;

%% ==================== 配置区域（需要修改的部分）====================
% !!!!! 重要：复制脚本后，请修改下面这个SNR值 !!!!!
% 可选值：Inf, -20, -10, 0, 10
SNR_TARGET = 10;  % <--- 修改这里！每个脚本使用不同的SNR值

% 生成文件夹名称
if isinf(SNR_TARGET)
    SNR_FOLDER_NAME = 'SNR_Inf';
    SNR_DISPLAY = 'Inf';
else
    SNR_FOLDER_NAME = sprintf('SNR_%ddB', SNR_TARGET);
    SNR_DISPLAY = sprintf('%d', SNR_TARGET);
end

fprintf('\n========================================\n');
fprintf('单SNR批量处理脚本\n');
fprintf('目标SNR等级: %s dB\n', SNR_DISPLAY);
fprintf('输出文件夹标识: %s\n', SNR_FOLDER_NAME);
fprintf('========================================\n\n');

%% ==================== Section 1: OFDM信号生成/加载 ====================
disp('=== Section 1: OFDM信号生成/加载 ===');

% 定义OFDM信号数据文件路径
output_base_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results_scenario3\';
ofdm_signal_file = fullfile(output_base_dir, 'ofdm_signal_data.mat');

% 检查OFDM信号数据是否已存在
if exist(ofdm_signal_file, 'file')
    % 数据已存在，直接加载
    fprintf('检测到已存在的OFDM信号数据，正在加载...\n');
    fprintf('文件路径: %s\n', ofdm_signal_file);
    load(ofdm_signal_file, 'windowed_Tx_data', 'baseband_out', 'complex_carrier_matrix', 'ofdm_params');
    fprintf('OFDM信号数据加载成功！\n');
else
    % 数据不存在，生成新的OFDM信号
    fprintf('未检测到OFDM信号数据，正在生成新的信号...\n');
    [windowed_Tx_data, baseband_out, complex_carrier_matrix, ofdm_params] = ...
        func_generate_ofdm_signal();
    
    % 创建输出目录（如果不存在）
    if ~exist(output_base_dir, 'dir')
        mkdir(output_base_dir);
    end
    
    % 暂时保存OFDM信号数据（稍后会补充radar_params等参数）
    fprintf('保存OFDM信号数据到: %s\n', ofdm_signal_file);
    fprintf('注意: radar_params, music_params, base_pos 将在参数设置后补充保存\n');
    save(ofdm_signal_file, 'windowed_Tx_data', 'baseband_out', 'complex_carrier_matrix', 'ofdm_params', '-v7.3');
    fprintf('OFDM信号数据已保存！\n');
end

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

fprintf('OFDM参数: IFFT_length=%d, symbols_per_carrier=%d, delta_f=%.2f Hz\n', ...
        IFFT_length, symbols_per_carrier, delta_f);

%% ==================== 第二部分：参数设置 ====================
disp('=== 设置雷达与MUSIC参数 ===');

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
scene_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\scenario_3\mat_files\';

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

%% ==================== 第四部分：保存共享参数 ====================
disp('=== 保存共享参数 ===');

% 如果OFDM信号数据是新生成的，需要补充保存radar_params, music_params, base_pos
if exist(ofdm_signal_file, 'file')
    % 检查文件中是否包含radar_params
    file_info = whos('-file', ofdm_signal_file);
    var_names = {file_info.name};
    
    if ~ismember('radar_params', var_names) || ~ismember('music_params', var_names) || ~ismember('base_pos', var_names)
        fprintf('补充保存 radar_params, music_params, base_pos 到共享文件...\n');
        save(ofdm_signal_file, 'radar_params', 'music_params', 'base_pos', '-append');
        fprintf('参数补充完成！\n');
    else
        fprintf('共享参数文件已完整，无需补充\n');
    end
end

disp('===========================================');

%% ==================== 第五部分：遍历所有场景进行处理 ====================
disp('=== 开始处理所有场景 ===');

% 运行时间统计初始化
total_start_time = tic;
scene_times = zeros(num_scenes, 1);

fprintf('\n当前SNR等级: %s dB\n', SNR_DISPLAY);
fprintf('总场景数: %d\n\n', num_scenes);

% 循环处理每个场景
for scene_idx = 1:num_scenes
    scene_start_time = tic; % 记录当前场景开始时间
    
    scene_data = scene_data_list{scene_idx};
    scene_name = scene_data.filename;
    environment_point = scene_data.environment_point;
    point_info = scene_data.point_info;
    
    % 移除.mat后缀作为场景名称
    [~, scene_basename, ~] = fileparts(scene_name);
    
    fprintf('\n========================================\n');
    fprintf('正在处理场景 %d/%d: %s\n', scene_idx, num_scenes, scene_name);
    fprintf('SNR: %s dB\n', SNR_DISPLAY);
    fprintf('========================================\n');
    
    % 为当前场景创建输出目录
    scene_output_dir = fullfile(output_base_dir, scene_basename);
    if ~exist(scene_output_dir, 'dir')
        mkdir(scene_output_dir);
    end
    
    % 保存场景信息（如果不存在）
    scene_info_file = fullfile(scene_output_dir, 'scene_info.mat');
    if ~exist(scene_info_file, 'file')
        save(scene_info_file, 'scene_name', 'environment_point', 'point_info');
        fprintf('场景信息已保存: %s\n', scene_info_file);
    end
    
    % 为当前SNR等级创建子文件夹
    snr_folder = fullfile(scene_output_dir, SNR_FOLDER_NAME);
    if ~exist(snr_folder, 'dir')
        mkdir(snr_folder);
    end
    
    % 检查结果文件是否已存在（支持断点续传）
    result_file = fullfile(snr_folder, 'results.mat');
    if exist(result_file, 'file')
        fprintf('警告：结果文件已存在，跳过此场景: %s\n', result_file);
        scene_times(scene_idx) = toc(scene_start_time);
        continue;
    end
    
    try
        % 步骤1：添加噪声
        fprintf('步骤1: 添加噪声 (SNR = %s dB)\n', SNR_DISPLAY);
        Rx_data = func_add_noise(windowed_Tx_data, SNR_TARGET);
        
        % 步骤2：OFDM解调与BER计算
        fprintf('步骤2: OFDM解调与BER计算\n');
        [Rx_complex_carrier_matrix, BER] = func_ofdm_demodulation(Rx_data, baseband_out, IFFT_length, symbols_per_carrier, GI, GIP);
        fprintf('BER = %.6f\n', BER);
        
        % 步骤3：生成雷达回波信号
        fprintf('步骤3: 生成雷达回波信号\n');
        multi_Rx_complex_carrier_matrix_radar = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params);
        
        % 步骤4：Range-Doppler处理与CFAR检测（禁用可视化）
        fprintf('步骤4: Range-Doppler处理与CFAR检测 (SNR=10dB, 使用高SNR优化CFAR)\n');
        do_visualization = false; % 批量处理模式下不绘图
        [Velocity_fft, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = ...
            func_range_doppler_processing(multi_Rx_complex_carrier_matrix_radar, complex_carrier_matrix, radar_params, do_visualization, SNR_TARGET);
        
        fprintf('检测到 %d 个Range-Doppler目标\n', size(RD_target_index, 1));
        
        % 步骤5：保存结果（只保存第一个天线的FFT结果以节省空间）
        fprintf('步骤5: 保存结果到 %s\n', result_file);
        % 只保存第一个天线的FFT结果（其他天线在后续MUSIC处理时重新计算）
        Velocity_fft_antenna_1_1 = Velocity_fft(:, :, 1, 1);
        save(result_file, 'SNR_TARGET', 'BER', 'Velocity_fft_antenna_1_1', 'RD_threshold_matrix', ...
             'RD_target_index', 'RD_detect_matrix_abs', '-v7.3');
        fprintf('结果已成功保存（已优化：只保存第一个天线数据，节省空间）\n');
        
    catch ME
        % 错误处理：记录错误信息但继续处理下一个场景
        fprintf('\n!!! 错误：处理场景 %s 时发生异常 !!!\n', scene_name);
        fprintf('错误信息: %s\n', ME.message);
        fprintf('错误位置: %s (Line %d)\n', ME.stack(1).name, ME.stack(1).line);
        fprintf('跳过此场景，继续处理下一个...\n\n');
        
        % 保存错误信息到文件
        error_file = fullfile(snr_folder, 'error_log.mat');
        error_message = ME.message;
        error_stack = ME.stack;
        save(error_file, 'error_message', 'error_stack');
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

%% ==================== 第六部分：总结统计 ====================
total_elapsed_time = toc(total_start_time);

fprintf('\n\n');
fprintf('========================================\n');
fprintf('所有场景处理完毕！\n');
fprintf('========================================\n');
fprintf('SNR等级: %s dB\n', SNR_DISPLAY);
fprintf('总场景数: %d\n', num_scenes);
fprintf('总运行时间: %.2f 秒 (约 %.2f 分钟)\n', total_elapsed_time, total_elapsed_time/60);
fprintf('平均每场景耗时: %.2f 秒\n', mean(scene_times));
fprintf('最快场景耗时: %.2f 秒\n', min(scene_times));
fprintf('最慢场景耗时: %.2f 秒\n', max(scene_times));
fprintf('========================================\n');

% 生成完成标记文件
completion_marker = fullfile(output_base_dir, sprintf('completed_%s.txt', SNR_FOLDER_NAME));
fid = fopen(completion_marker, 'w');
fprintf(fid, '处理完成时间: %s\n', datestr(now));
fprintf(fid, 'SNR等级: %s dB\n', SNR_DISPLAY);
fprintf(fid, '总场景数: %d\n', num_scenes);
fprintf(fid, '总运行时间: %.2f 秒\n', total_elapsed_time);
fclose(fid);

fprintf('\n完成标记已保存至: %s\n', completion_marker);
disp('脚本执行完毕！');
