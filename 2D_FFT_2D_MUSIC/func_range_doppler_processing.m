function [Velocity_fft, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = func_range_doppler_processing(multi_Rx_complex_carrier_matrix_radar, complex_carrier_matrix, radar_params, do_visualization, snr_db)
% 功能：Range-Doppler 2D FFT处理与OSCA-CFAR检测
% 输入：
%   multi_Rx_complex_carrier_matrix_radar - 多天线回波矩阵 [symbols_per_carrier × IFFT_length × M × N]
%   complex_carrier_matrix - 原始发送调制符号
%   radar_params - 雷达参数结构体（M, N, IFFT_length, symbols_per_carrier等）
%   do_visualization - 是否绘制可视化结果（布尔值，默认true）
%   snr_db - 信噪比（dB），用于选择合适的CFAR版本（可选，默认Inf）
% 输出：
%   Velocity_fft - 所有天线的速度-距离FFT结果 [symbols_per_carrier × IFFT_length × M × N]
%   RD_threshold_matrix - OSCA-CFAR检测门限矩阵
%   RD_target_index - 检测到的目标索引 [N×2]
%   RD_detect_matrix_abs - CFAR检测结果矩阵

    if nargin < 4
        do_visualization = true;
    end
    if nargin < 5
        snr_db = Inf; % 默认无噪声
    end
    
    disp('开始测速测距......');
    
    M = radar_params.M;
    N = radar_params.N;
    IFFT_length = radar_params.IFFT_length;
    symbols_per_carrier = radar_params.symbols_per_carrier;
    
    % 测速测距FFT
    Velocity_fft = zeros(size(multi_Rx_complex_carrier_matrix_radar));
    
    fprintf('正在为所有天线回波进行FFT (总共 %d×%d=%d 个天线)...\n', M, N, M*N);
    tCount1 = 0;
    for i = 1:M
        t00 = tic;
        for j = 1:N
            div_page = multi_Rx_complex_carrier_matrix_radar(:, :, i, j) ./ complex_carrier_matrix;
            page_ifft = ifft(div_page, IFFT_length, 2);
            page_fft = fftshift(fft(page_ifft, symbols_per_carrier, 1), 1);
            Velocity_fft(:, :, i, j) = page_fft;
        end
        
        % 剩余时间预估（每4行输出一次进度）
        tCount1 = tCount1 + toc(t00);
        if mod(i, 4) == 0 || i == M
            t_step = tCount1 / i;
            t_res = (M - i) * t_step;
            fprintf('  进度: %d/%d (%.1f%%), 剩余时间: %.1f 秒\n', i, M, 100*i/M, t_res);
        end
    end
    fprintf('所有天线FFT完成！\n');
    
    % 针对测速测距结果进行恒虚警检测（使用第一个天线）
    % 根据SNR自动选择合适的CFAR函数
    fprintf('开始OSCA-CFAR检测 (SNR = %.1f dB)...\n', snr_db);
    
    if isinf(snr_db) || snr_db >= 10
        % 高SNR (Inf, >=10 dB)
        [RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = OSCA_CFAR_high_snr(Velocity_fft(:, :, 1, 1));
    elseif snr_db >= 0
        % 中等SNR (0 dB)
        [RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = OSCA_CFAR_mid_snr(Velocity_fft(:, :, 1, 1));
    elseif snr_db >= -10
        % 低SNR (-10 dB)
        [RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = OSCA_CFAR_low_snr(Velocity_fft(:, :, 1, 1));
    else
        % 极低SNR (-20 dB)
        [RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs] = OSCA_CFAR_very_low_snr(Velocity_fft(:, :, 1, 1));
    end
    
    disp('测速测距完毕！');
    
    % 可视化
    if do_visualization
        disp('绘制CFAR输入数据（天线1,1的速度-距离FFT结果）...');
        
        % 提取第一个天线的FFT结果
        Velocity_fft_antenna_1_1 = Velocity_fft(:, :, 1, 1);
        Velocity_fft_abs = abs(Velocity_fft_antenna_1_1);
        
        % 绘制热力图
        figure;
        imagesc(Velocity_fft_abs);
        colorbar;
        title('Range-Doppler Heatmap (Antenna 1,1)');
        xlabel('Range Bin');
        ylabel('Velocity Bin');
        
        % 标记 CFAR 检测到的目标点
        hold on;
        plot(RD_target_index(:,2), RD_target_index(:,1), 'ro', 'MarkerSize', 5, 'LineWidth', 2);
        hold off;
        
        disp('CFAR输入数据可视化完成！');
        
        % 绘制测速测距结果及CFAR门限
        c = radar_params.c;
        delta_f = radar_params.delta_f;
        f_c = radar_params.f_c;
        T_OFDM = radar_params.T_OFDM;
        
        b = -symbols_per_carrier/2:1:symbols_per_carrier/2-1;
        a = 1:1:IFFT_length;
        
        figure;
        [A, B] = meshgrid(a.*(c / 2 / delta_f)/IFFT_length, b.*(c / 2 / f_c/T_OFDM)/symbols_per_carrier);
        mesh(A, B, RD_detect_matrix_abs);
        axis([50 150 -50 50 0 5e6]);
        xlabel('距离/m'); ylabel('速度（m/s）'); zlabel('信号幅值');
        title('速度距离fft结果');
        
        figure;
        [A_1, B_1] = meshgrid(a.*(c / 2 / delta_f)/IFFT_length, b.*(c / 2 / f_c/T_OFDM)/symbols_per_carrier);
        mesh(A_1, B_1, RD_threshold_matrix);
        axis([50 150 -50 50 0 5e6]);
        xlabel('距离/m'); ylabel('速度（m/s）'); zlabel('信号幅值');
        title('速度距离fft门限结果');
    end
end
