%% 提取Velocity_fft_antenna_1_1数据集
% 本脚本从scenario3的仿真结果中提取Range-Doppler复数矩阵
% 按照GT/SNR配对方式组织：每个场景的SNR_Inf作为GT，对应4个噪声等级
% 数据集结构：200个场景，每个场景包含1个GT + 4个带噪声的测量

clc;
clear;
close all;

%% ==================== 配置参数 ====================
% 结果目录
results_base_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results_scenario3\';

% 输出数据集目录
dataset_output_dir = fullfile(results_base_dir, 'velocity_fft_dataset');
if ~exist(dataset_output_dir, 'dir')
    mkdir(dataset_output_dir);
end

% SNR等级配置
gt_snr = 'SNR_Inf';  % 真值（Ground Truth）
noise_snr_levels = {'SNR_10dB', 'SNR_0dB', 'SNR_-10dB', 'SNR_-20dB'};  % 噪声等级

fprintf('\n========================================\n');
fprintf('提取Velocity FFT数据集\n');
fprintf('========================================\n\n');

%% ==================== 加载共享参数 ====================
disp('加载OFDM和雷达参数...');
ofdm_signal_file = fullfile(results_base_dir, 'ofdm_signal_data.mat');
if ~exist(ofdm_signal_file, 'file')
    error('未找到OFDM信号数据文件: %s', ofdm_signal_file);
end

load(ofdm_signal_file, 'ofdm_params', 'radar_params');
fprintf('参数加载完成！\n');

%% ==================== 获取所有场景目录 ====================
disp('扫描场景目录...');
scene_dirs = dir(fullfile(results_base_dir, 'scene_*'));
scene_dirs = scene_dirs([scene_dirs.isdir]);
num_scenes = length(scene_dirs);

fprintf('找到 %d 个场景\n', num_scenes);
fprintf('========================================\n\n');

%% ==================== 初始化数据集结构 ====================
dataset = struct();
dataset.metadata = struct();
dataset.metadata.description = 'Range-Doppler Velocity FFT Dataset from Scenario 3';
dataset.metadata.num_scenes = num_scenes;
dataset.metadata.gt_snr = gt_snr;
dataset.metadata.noise_snr_levels = noise_snr_levels;
dataset.metadata.creation_date = datestr(now);
dataset.metadata.ofdm_params = ofdm_params;
dataset.metadata.radar_params = radar_params;

% 数据存储
dataset.data = struct();
dataset.data.scene_names = cell(num_scenes, 1);
dataset.data.gt = cell(num_scenes, 1);  % Ground Truth (SNR_Inf)
dataset.data.noisy = cell(num_scenes, length(noise_snr_levels));  % 噪声数据 [200 x 4]
dataset.data.gt_ber = zeros(num_scenes, 1);  % GT的BER
dataset.data.noisy_ber = zeros(num_scenes, length(noise_snr_levels));  % 噪声数据的BER
dataset.data.gt_detected_targets = zeros(num_scenes, 1);  % GT检测到的目标数
dataset.data.noisy_detected_targets = zeros(num_scenes, length(noise_snr_levels));  % 噪声数据检测目标数

%% ==================== 遍历场景并提取数据 ====================
start_time = tic;
success_count = 0;
failed_scenes = {};

for scene_idx = 1:num_scenes
    scene_name = scene_dirs(scene_idx).name;
    scene_dir = fullfile(results_base_dir, scene_name);
    
    fprintf('[%3d/%3d] 处理场景: %s\n', scene_idx, num_scenes, scene_name);
    
    try
        % 提取Ground Truth (SNR_Inf)
        gt_file = fullfile(scene_dir, gt_snr, 'results.mat');
        if ~exist(gt_file, 'file')
            error('GT文件不存在: %s', gt_file);
        end
        
        gt_data = load(gt_file, 'Velocity_fft_antenna_1_1', 'BER', 'RD_target_index');
        dataset.data.scene_names{scene_idx} = scene_name;
        dataset.data.gt{scene_idx} = gt_data.Velocity_fft_antenna_1_1;
        dataset.data.gt_ber(scene_idx) = gt_data.BER;
        dataset.data.gt_detected_targets(scene_idx) = size(gt_data.RD_target_index, 1);
        
        % 提取噪声数据
        for snr_idx = 1:length(noise_snr_levels)
            snr_level = noise_snr_levels{snr_idx};
            noisy_file = fullfile(scene_dir, snr_level, 'results.mat');
            
            if ~exist(noisy_file, 'file')
                warning('  噪声文件不存在: %s/%s', scene_name, snr_level);
                dataset.data.noisy{scene_idx, snr_idx} = [];
                dataset.data.noisy_ber(scene_idx, snr_idx) = NaN;
                dataset.data.noisy_detected_targets(scene_idx, snr_idx) = 0;
                continue;
            end
            
            noisy_data = load(noisy_file, 'Velocity_fft_antenna_1_1', 'BER', 'RD_target_index');
            dataset.data.noisy{scene_idx, snr_idx} = noisy_data.Velocity_fft_antenna_1_1;
            dataset.data.noisy_ber(scene_idx, snr_idx) = noisy_data.BER;
            dataset.data.noisy_detected_targets(scene_idx, snr_idx) = size(noisy_data.RD_target_index, 1);
        end
        
        success_count = success_count + 1;
        
        % 每50个场景显示一次进度
        if mod(scene_idx, 50) == 0
            fprintf('  >> 已处理 %d/%d 场景 (成功: %d)\n', scene_idx, num_scenes, success_count);
        end
        
    catch ME
        warning('场景 %s 处理失败: %s', scene_name, ME.message);
        failed_scenes{end+1} = scene_name;
    end
end

elapsed_time = toc(start_time);

%% ==================== 保存数据集 ====================
fprintf('\n========================================\n');
fprintf('保存数据集...\n');

% 保存完整数据集
dataset_file = fullfile(dataset_output_dir, 'velocity_fft_dataset_full.mat');
fprintf('保存完整数据集: %s\n', dataset_file);
save(dataset_file, 'dataset', '-v7.3');  % 使用v7.3格式支持大文件

% 保存元数据和统计信息（便于快速查看）
metadata_file = fullfile(dataset_output_dir, 'dataset_metadata.mat');
fprintf('保存元数据: %s\n', metadata_file);
save(metadata_file, '-struct', 'dataset', 'metadata');

% 创建数据集说明文档
readme_file = fullfile(dataset_output_dir, 'README.txt');
fid = fopen(readme_file, 'w');
fprintf(fid, '========================================\n');
fprintf(fid, 'Velocity FFT Dataset - Scenario 3\n');
fprintf(fid, '========================================\n\n');
fprintf(fid, '创建时间: %s\n', dataset.metadata.creation_date);
fprintf(fid, '数据来源: %s\n\n', results_base_dir);
fprintf(fid, '数据集结构:\n');
fprintf(fid, '- 场景数量: %d\n', num_scenes);
fprintf(fid, '- 成功提取: %d\n', success_count);
fprintf(fid, '- Ground Truth SNR: %s\n', gt_snr);
fprintf(fid, '- 噪声等级: %s\n', strjoin(noise_snr_levels, ', '));
fprintf(fid, '\n数据维度:\n');
if success_count > 0 && ~isempty(dataset.data.gt{1})
    [rows, cols] = size(dataset.data.gt{1});
    fprintf(fid, '- Velocity_fft_antenna_1_1 矩阵大小: %d x %d (复数)\n', rows, cols);
    fprintf(fid, '- 数据类型: complex double\n');
end
fprintf(fid, '\n文件说明:\n');
fprintf(fid, '- velocity_fft_dataset_full.mat: 完整数据集（包含所有矩阵）\n');
fprintf(fid, '- dataset_metadata.mat: 元数据和参数信息\n');
fprintf(fid, '- README.txt: 本说明文件\n');
fprintf(fid, '\n数据访问示例:\n');
fprintf(fid, '  load(''velocity_fft_dataset_full.mat'');\n');
fprintf(fid, '  gt_matrix = dataset.data.gt{1};           %% 第1个场景的GT\n');
fprintf(fid, '  noisy_10db = dataset.data.noisy{1, 1};    %% 第1个场景的10dB噪声数据\n');
fprintf(fid, '  noisy_0db = dataset.data.noisy{1, 2};     %% 第1个场景的0dB噪声数据\n');
fprintf(fid, '  noisy_m10db = dataset.data.noisy{1, 3};   %% 第1个场景的-10dB噪声数据\n');
fprintf(fid, '  noisy_m20db = dataset.data.noisy{1, 4};   %% 第1个场景的-20dB噪声数据\n');
fprintf(fid, '\n数据集配对关系:\n');
fprintf(fid, '  每个场景i (1 <= i <= %d):\n', num_scenes);
fprintf(fid, '    GT: dataset.data.gt{i}\n');
fprintf(fid, '    Noisy samples: dataset.data.noisy{i, :} (1x4 cell array)\n');
fprintf(fid, '\n处理统计:\n');
fprintf(fid, '- 处理时间: %.2f 秒 (%.1f 分钟)\n', elapsed_time, elapsed_time/60);
fprintf(fid, '- 平均每场景: %.3f 秒\n', elapsed_time/num_scenes);
if ~isempty(failed_scenes)
    fprintf(fid, '\n失败场景列表:\n');
    for i = 1:length(failed_scenes)
        fprintf(fid, '  - %s\n', failed_scenes{i});
    end
end
fprintf(fid, '\n========================================\n');
fclose(fid);

%% ==================== 生成统计报告 ====================
fprintf('\n========================================\n');
fprintf('数据集统计\n');
fprintf('========================================\n');
fprintf('总场景数: %d\n', num_scenes);
fprintf('成功提取: %d\n', success_count);
fprintf('失败场景: %d\n', length(failed_scenes));
fprintf('\nGT统计:\n');
fprintf('  平均BER: %.6f\n', mean(dataset.data.gt_ber(1:success_count)));
fprintf('  平均检测目标数: %.1f\n', mean(dataset.data.gt_detected_targets(1:success_count)));

fprintf('\n噪声数据统计:\n');
for snr_idx = 1:length(noise_snr_levels)
    valid_ber = dataset.data.noisy_ber(1:success_count, snr_idx);
    valid_ber = valid_ber(~isnan(valid_ber));
    valid_targets = dataset.data.noisy_detected_targets(1:success_count, snr_idx);
    
    fprintf('  %s:\n', noise_snr_levels{snr_idx});
    fprintf('    平均BER: %.6f\n', mean(valid_ber));
    fprintf('    平均检测目标数: %.1f\n', mean(valid_targets));
end

fprintf('\n数据集文件:\n');
fprintf('  完整数据集: %s\n', dataset_file);
fprintf('  元数据: %s\n', metadata_file);
fprintf('  说明文档: %s\n', readme_file);

fprintf('\n总处理时间: %.2f 秒 (%.1f 分钟)\n', elapsed_time, elapsed_time/60);
fprintf('========================================\n');

%% ==================== 可选：创建分割数据集 ====================
% 如果需要训练/验证/测试集划分，取消以下注释
% fprintf('\n是否创建训练/验证/测试集划分？(y/n): ');
% user_input = input('', 's');
% if strcmpi(user_input, 'y')
%     fprintf('创建数据集划分...\n');
%     
%     % 划分比例：70% 训练, 15% 验证, 15% 测试
%     train_ratio = 0.7;
%     val_ratio = 0.15;
%     test_ratio = 0.15;
%     
%     % 随机打乱索引
%     rng(42);  % 设置随机种子以保证可复现
%     indices = randperm(success_count);
%     
%     train_end = floor(success_count * train_ratio);
%     val_end = train_end + floor(success_count * val_ratio);
%     
%     train_indices = indices(1:train_end);
%     val_indices = indices(train_end+1:val_end);
%     test_indices = indices(val_end+1:end);
%     
%     % 保存划分索引
%     split_info = struct();
%     split_info.train_indices = train_indices;
%     split_info.val_indices = val_indices;
%     split_info.test_indices = test_indices;
%     split_info.train_size = length(train_indices);
%     split_info.val_size = length(val_indices);
%     split_info.test_size = length(test_indices);
%     
%     split_file = fullfile(dataset_output_dir, 'dataset_split.mat');
%     save(split_file, 'split_info');
%     fprintf('数据集划分已保存: %s\n', split_file);
%     fprintf('  训练集: %d 样本\n', split_info.train_size);
%     fprintf('  验证集: %d 样本\n', split_info.val_size);
%     fprintf('  测试集: %d 样本\n', split_info.test_size);
% end

fprintf('\n脚本执行完毕！\n');
