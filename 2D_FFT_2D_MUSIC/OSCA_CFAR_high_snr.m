function [threshold_matrix, target_index, detect_matrix_abs] = OSCA_CFAR_high_snr(detect_matrix)
%% OSCA-CFAR检测器 - 高SNR优化版本 (SNR >= 10 dB, 包括Inf)
% 针对高信噪比环境优化：可以使用较小的窗口和适中的门限
% 适用场景：SNR = Inf, 10 dB

threshold_matrix = zeros(size(detect_matrix));
target_index = [];

%% 高SNR参数配置
window_size = 9;           % 标准窗口
N = window_size - 1;
k_ratio = 0.75;            % 标准排序比例
R = round(k_ratio * N);    % OS_CFAR的噪声功率选取索引
Pfa = 1e-4;                % 虚警概率 (更严格)
K_factor = Pfa^(-1 / window_size) - 1; % 检测阈值因子
threshold_adjust = 60000;  % 适中的门限调整

fprintf('[高SNR-CFAR] 窗口=%d, k=%.2f, Pfa=%.0e, 门限调整=%d\n', ...
        window_size, k_ratio, Pfa, threshold_adjust);

%% 执行检测
detect_matrix_abs = abs(detect_matrix) .* abs(detect_matrix);

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
        
        % OS_CFAR排序
        sorted_window = sort(detect_window, 2);
        noise_power = sum(sorted_window(:, R)) / length(sorted_window(:, R));
        
        % 检测门限
        threshold_matrix(i, j) = noise_power * K_factor + threshold_adjust;
        
        if CUT > threshold_matrix(i, j)
            target_index = [target_index; i j];
        end
    end
    
    if mod(i, 10) == 0 || i == size(detect_matrix, 1)
        fprintf('  进度: %d/%d\n', i, size(detect_matrix, 1));
    end
end

fprintf('[高SNR-CFAR] 检测完成，共 %d 个目标\n', size(target_index, 1));

end
