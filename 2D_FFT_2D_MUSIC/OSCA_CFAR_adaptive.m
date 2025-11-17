function [threshold_matrix, target_index, detect_matrix_abs] = OSCA_CFAR_adaptive(detect_matrix, snr_db)
%% 自适应OSCA-CFAR检测器（根据SNR自动选择参数）
% 本函数用于针对RD域进行恒虚警检测，根据SNR等级自动调整参数
% 输入：
%   detect_matrix - 输入检测矩阵（Range-Doppler域）
%   snr_db - 信噪比（dB），用于选择参数配置
% 输出：
%   threshold_matrix - 检测门限矩阵
%   target_index - 检测到的目标索引 [N×2]
%   detect_matrix_abs - 检测矩阵的平方律输出

%% 根据SNR选择参数配置
if nargin < 2
    snr_db = Inf; % 默认无噪声
    warning('未指定SNR，使用默认配置（Inf dB）');
end

% 参数配置表（经过优化的参数）
if isinf(snr_db)
    % SNR = Inf (无噪声)
    config.window_size = 9;
    config.k_ratio = 0.75;
    config.Pfa = 1e-4;              % 更严格的虚警率
    config.threshold_adjust = 50000;
    config.description = 'SNR=Inf (无噪声)';
    
elseif snr_db >= 10
    % SNR >= 10 dB (高SNR)
    config.window_size = 9;
    config.k_ratio = 0.75;
    config.Pfa = 1e-4;              % 严格的虚警率
    config.threshold_adjust = 60000;
    config.description = sprintf('SNR=%.1f dB (高SNR)', snr_db);
    
elseif snr_db >= 0
    % 0 <= SNR < 10 dB (中等SNR)
    config.window_size = 11;        % 更大的窗口
    config.k_ratio = 0.80;          % 更高的排序比例
    config.Pfa = 5e-5;              % 更严格的虚警率
    config.threshold_adjust = 80000; % 更高的门限调整
    config.description = sprintf('SNR=%.1f dB (中等SNR)', snr_db);
    
elseif snr_db >= -10
    % -10 <= SNR < 0 dB (低SNR)
    config.window_size = 13;        % 大窗口
    config.k_ratio = 0.85;          % 高排序比例
    config.Pfa = 1e-5;              % 非常严格的虚警率
    config.threshold_adjust = 120000; % 很高的门限调整
    config.description = sprintf('SNR=%.1f dB (低SNR)', snr_db);
    
else
    % SNR < -10 dB (极低SNR)
    config.window_size = 15;        % 最大窗口
    config.k_ratio = 0.90;          % 最高排序比例
    config.Pfa = 5e-6;              % 极严格的虚警率
    config.threshold_adjust = 200000; % 极高的门限调整
    config.description = sprintf('SNR=%.1f dB (极低SNR)', snr_db);
end

fprintf('使用配置: %s\n', config.description);
fprintf('  - 窗口大小: %d×%d\n', config.window_size, config.window_size);
fprintf('  - k比例: %.2f\n', config.k_ratio);
fprintf('  - 虚警概率: %.2e\n', config.Pfa);
fprintf('  - 门限调整: %d\n', config.threshold_adjust);

%% 执行OSCA-CFAR检测
threshold_matrix = zeros(size(detect_matrix));
target_index = [];

% 从配置中提取参数
window_size = config.window_size;
N = window_size - 1;
R = round(config.k_ratio * N); % OS_CFAR的噪声功率选取索引
Pfa = config.Pfa;
K_factor = Pfa^(-1 / window_size) - 1; % 检测阈值因子
threshold_adjust = config.threshold_adjust;

detect_matrix_abs = abs(detect_matrix) .* abs(detect_matrix); % 平方律检测器

fprintf('开始OSCA-CFAR检测...\n');
for i = 1:size(detect_matrix, 1)
    for j = 1:size(detect_matrix, 2)
        CUT = detect_matrix_abs(i, j);
        detect_window = zeros(window_size, window_size);
        
        % 检测窗口行索引
        if i < (N/2 + 1)
            row_index = 1:window_size;
        elseif (size(detect_matrix, 1) - i) < N/2
            row_index = size(detect_matrix, 1) - window_size + 1 : size(detect_matrix, 1);
        else
            row_index = i - N/2 : i + N/2;
        end
        
        % 检测窗口列索引
        if j < (N/2 + 1)
            col_index = 1:window_size;
        elseif (size(detect_matrix, 2) - j) < N/2
            col_index = size(detect_matrix, 2) - window_size + 1 : size(detect_matrix, 2);
        else
            col_index = j - N/2 : j + N/2;
        end
        
        % 检测窗口赋值
        for m = 1:length(row_index)
            for n = 1:length(col_index)
                detect_window(m, n) = detect_matrix_abs(row_index(m), col_index(n));
            end
        end
        
        % R维度逐行进行OS_CFAR
        sorted_window = sort(detect_window, 2);
        
        % D维度进行CA_CFAR
        noise_power = sum(sorted_window(:, R)) / length(sorted_window(:, R));
        
        % 检测门限
        threshold_matrix(i, j) = noise_power * K_factor + threshold_adjust;
        
        if CUT > threshold_matrix(i, j)
            target_index = [target_index; i j];
        end
    end
    
    % 每10行输出一次进度（减少输出）
    if mod(i, 10) == 0 || i == size(detect_matrix, 1)
        fprintf('  检测进度: %d/%d (%.1f%%)\n', i, size(detect_matrix, 1), 100*i/size(detect_matrix, 1));
    end
end

fprintf('OSCA-CFAR检测完成！检测到 %d 个目标\n', size(target_index, 1));

end
