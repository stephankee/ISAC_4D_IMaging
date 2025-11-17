%% 批量可视化所有场景和SNR等级的Range-Doppler结果
% 本脚本读取snr_simulation_results目录下所有场景的结果
% 并为每个场景的每个SNR等级生成Range-Doppler热力图

clc;
clear;
close all;

%% ==================== 配置参数 ====================
% 结果目录
results_base_dir = 'D:\Junzhe\ISAC_4D_IMaging\2D_FFT_2D_MUSIC\snr_simulation_results_scenario3\';

% SNR等级列表
snr_levels = {'SNR_Inf', 'SNR_10dB', 'SNR_0dB', 'SNR_-10dB', 'SNR_-20dB'};

% 可视化设置
save_figures = true;  % 是否保存图片
show_figures = false;  % 是否显示图形窗口（批量处理时建议false）
image_format = 'png';  % 图片格式: 'png', 'jpg', 'fig'

fprintf('\n========================================\n');
fprintf('批量可视化Range-Doppler结果\n');
fprintf('========================================\n\n');

%% ==================== 加载共享参数 ====================
disp('加载共享参数...');
ofdm_signal_file = fullfile(results_base_dir, 'ofdm_signal_data.mat');
if ~exist(ofdm_signal_file, 'file')
    error('未找到OFDM信号数据文件: %s', ofdm_signal_file);
end

load(ofdm_signal_file, 'ofdm_params', 'radar_params');

% 提取参数
c = radar_params.c;
delta_f = radar_params.delta_f;
f_c = radar_params.f_c;
T_OFDM = radar_params.T_OFDM;
IFFT_length = radar_params.IFFT_length;
symbols_per_carrier = radar_params.symbols_per_carrier;

fprintf('参数加载完成！\n');
disp('===========================================');

%% ==================== 获取所有场景目录 ====================
disp('扫描场景目录...');
scene_dirs = dir(fullfile(results_base_dir, 'scene_*'));
scene_dirs = scene_dirs([scene_dirs.isdir]);
num_scenes = length(scene_dirs);

fprintf('找到 %d 个场景\n', num_scenes);
disp('===========================================');

%% ==================== 遍历所有场景和SNR等级 ====================
total_start_time = tic;
visualization_count = 0;
skipped_count = 0;

for scene_idx = 1:num_scenes
    scene_name = scene_dirs(scene_idx).name;
    scene_dir = fullfile(results_base_dir, scene_name);
    
    fprintf('\n========================================\n');
    fprintf('处理场景 %d/%d: %s\n', scene_idx, num_scenes, scene_name);
    fprintf('========================================\n');
    
    % 为当前场景创建图像输出目录
    if save_figures
        image_output_dir = fullfile(scene_dir, 'visualizations');
        if ~exist(image_output_dir, 'dir')
            mkdir(image_output_dir);
        end
    end
    
    % 遍历所有SNR等级
    for snr_idx = 1:length(snr_levels)
        snr_level = snr_levels{snr_idx};
        result_file = fullfile(scene_dir, snr_level, 'results.mat');
        
        % 检查结果文件是否存在
        if ~exist(result_file, 'file')
            fprintf('  [跳过] %s - 结果文件不存在\n', snr_level);
            skipped_count = skipped_count + 1;
            continue;
        end
        
        try
            % 加载结果数据
            load(result_file, 'SNR_TARGET', 'BER', 'Velocity_fft_antenna_1_1', ...
                 'RD_threshold_matrix', 'RD_target_index', 'RD_detect_matrix_abs');
            
            fprintf('  [可视化] %s (SNR=%.1f dB, BER=%.6f, 检测目标数=%d)\n', ...
                    snr_level, SNR_TARGET, BER, size(RD_target_index, 1));
            
            %% 可视化1: Range-Doppler 热力图（带目标标记）
            if ~show_figures
                fig1 = figure('Visible', 'off');
            else
                fig1 = figure;
            end
            
            Velocity_fft_abs = abs(Velocity_fft_antenna_1_1);
            
            % 计算物理坐标轴
            % 距离轴 (m)
            a = 1:1:IFFT_length;
            range_axis = a.*(c / 2 / delta_f)/IFFT_length;
            
            % 速度轴 (m/s)
            b = -symbols_per_carrier/2:1:symbols_per_carrier/2-1;
            velocity_axis = b.*(c / 2 / f_c/T_OFDM)/symbols_per_carrier;
            
            % 使用imagesc绘制热力图，并指定x、y轴的物理范围
            imagesc(range_axis, velocity_axis, Velocity_fft_abs);
            colorbar;
            title(sprintf('%s - Range-Doppler Heatmap\nSNR=%.1f dB, BER=%.6f, Targets=%d', ...
                         scene_name, SNR_TARGET, BER, size(RD_target_index, 1)), ...
                         'Interpreter', 'none');
            xlabel('Range (m)');
            ylabel('Velocity (m/s)');
            
            % 设置坐标轴范围
            xlim([75 110]);   % 距离范围: 50-150m
            ylim([-50 50]);   % 速度范围: -50 to 50 m/s
            
            % 标记检测到的目标（将bin索引转换为物理坐标）
            hold on;
            if ~isempty(RD_target_index)
                % 将bin索引转换为物理坐标
                target_ranges = range_axis(RD_target_index(:,2));
                target_velocities = velocity_axis(RD_target_index(:,1));
                plot(target_ranges, target_velocities, 'ro', ...
                     'MarkerSize', 2, 'LineWidth', 1);
            end
            hold off;
            
            % 保存图片
            if save_figures
                filename = sprintf('%s_heatmap_%s.%s', scene_name, snr_level, image_format);
                saveas(fig1, fullfile(image_output_dir, filename));
            end
            
            if ~show_figures
                close(fig1);
            end
            
            %% 可视化2: Range-Doppler 3D网格图（CFAR检测结果）
            if ~show_figures
                fig2 = figure('Visible', 'off');
            else
                fig2 = figure;
            end
            
            b = -symbols_per_carrier/2:1:symbols_per_carrier/2-1;
            a = 1:1:IFFT_length;
            [A, B] = meshgrid(a.*(c / 2 / delta_f)/IFFT_length, ...
                             b.*(c / 2 / f_c/T_OFDM)/symbols_per_carrier);
            
            mesh(A, B, RD_detect_matrix_abs);
            axis([50 150 -50 50 0 5e6]);
            xlabel('Range (m)'); 
            ylabel('Velocity (m/s)'); 
            zlabel('Signal Amplitude');
            title(sprintf('%s - CFAR Detection Result\nSNR=%.1f dB, Targets=%d', ...
                         scene_name, SNR_TARGET, size(RD_target_index, 1)), ...
                         'Interpreter', 'none');
            grid on;
            view(45, 30);
            
            % 保存图片
            if save_figures
                filename = sprintf('%s_3d_detection_%s.%s', scene_name, snr_level, image_format);
                saveas(fig2, fullfile(image_output_dir, filename));
            end
            
            if ~show_figures
                close(fig2);
            end
            
            %% 可视化3: CFAR门限3D图
            if ~show_figures
                fig3 = figure('Visible', 'off');
            else
                fig3 = figure;
            end
            
            mesh(A, B, RD_threshold_matrix);
            axis([50 150 -50 50 0 5e6]);
            xlabel('Range (m)'); 
            ylabel('Velocity (m/s)'); 
            zlabel('Threshold');
            title(sprintf('%s - CFAR Threshold\nSNR=%.1f dB', scene_name, SNR_TARGET), ...
                         'Interpreter', 'none');
            grid on;
            view(45, 30);
            
            % 保存图片
            if save_figures
                filename = sprintf('%s_3d_threshold_%s.%s', scene_name, snr_level, image_format);
                saveas(fig3, fullfile(image_output_dir, filename));
            end
            
            if ~show_figures
                close(fig3);
            end
            
            visualization_count = visualization_count + 1;
            
        catch ME
            fprintf('  [错误] %s - 可视化失败: %s\n', snr_level, ME.message);
            skipped_count = skipped_count + 1;
        end
    end
    
    fprintf('场景 %s 可视化完成\n', scene_name);
end

%% ==================== 总结统计 ====================
total_elapsed_time = toc(total_start_time);

fprintf('\n\n');
fprintf('========================================\n');
fprintf('批量可视化完成！\n');
fprintf('========================================\n');
fprintf('总场景数: %d\n', num_scenes);
fprintf('总SNR等级数: %d\n', length(snr_levels));
fprintf('成功可视化: %d 个\n', visualization_count);
fprintf('跳过/失败: %d 个\n', skipped_count);
fprintf('总运行时间: %.2f 秒 (约 %.1f 分钟)\n', total_elapsed_time, total_elapsed_time/60);
fprintf('平均每个可视化: %.2f 秒\n', total_elapsed_time / max(1, visualization_count));

if save_figures
    fprintf('\n图片已保存至各场景的 visualizations/ 子目录\n');
    fprintf('图片格式: %s\n', image_format);
end

fprintf('========================================\n');
disp('脚本执行完毕！');
