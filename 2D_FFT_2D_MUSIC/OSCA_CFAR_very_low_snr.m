function [threshold_matrix, target_index, detect_matrix_abs] = OSCA_CFAR_very_low_snr(detect_matrix)
%% OSCA-CFAR检测器 - 极低SNR优化版本 (-20 dB)
% 针对极低信噪比环境优化：使用最大窗口和极高门限
% 适用场景：SNR = -20 dB
% 注意：在极低SNR下，检测性能会显著下降，需要权衡检测率和虚警率

threshold_matrix = zeros(size(detect_matrix));
target_index = [];

%% 极低SNR参数配置（加强版）
window_size = 17;          % 超大窗口（15->17）
N = window_size - 1;
k_ratio = 0.92;            % 极高排序比例（0.90->0.92，只取最小的噪声样本）
R = round(k_ratio * N);    % OS_CFAR的噪声功率选取索引
Pfa = 1e-6;                % 最严格的虚警概率（5e-6->1e-6）
K_factor = Pfa^(-1 / window_size) - 1; % 检测阈值因子
threshold_adjust = 500000;  % 极高的门限调整（250k->500k，翻倍）

fprintf('[极低SNR-CFAR] 窗口=%d, k=%.2f, Pfa=%.0e, 门限调整=%d\n', ...
        window_size, k_ratio, Pfa, threshold_adjust);
fprintf('[警告] 在-20dB SNR下，真实目标可能被淹没在噪声中\n');

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

fprintf('[极低SNR-CFAR] 检测完成，共 %d 个目标\n', size(target_index, 1));

end
