function multi_Rx_complex_carrier_matrix_radar = func_generate_radar_echo(Rx_complex_carrier_matrix, point_info, radar_params)
% 功能：生成多天线雷达回波信号（叠加距离、速度、角度信息）
% 输入：
%   Rx_complex_carrier_matrix - 频域接收信号矩阵 [symbols_per_carrier × IFFT_length]
%   point_info - 散射点信息 [N×4]: (距离, 速度, 方位角, 俯仰角)
%   radar_params - 雷达参数结构体，包含：
%       .M - x方向阵元数
%       .N - y方向阵元数
%       .lambda - 波长
%       .d - 阵元间距
%       .c - 光速
%       .f_c - 载波频率
%       .delta_f - 子载波间隔
%       .IFFT_length - IFFT长度
%       .symbols_per_carrier - OFDM符号数
%       .T_OFDM - OFDM符号周期
% 输出：
%   multi_Rx_complex_carrier_matrix_radar - 多天线回波矩阵 [symbols_per_carrier × IFFT_length × M × N]

    disp('正在生成多天线回波信号，可能耗时较长，请稍后......');
    
    % 提取参数
    M = radar_params.M;
    N = radar_params.N;
    lambda = radar_params.lambda;
    d = radar_params.d;
    c = radar_params.c;
    f_c = radar_params.f_c;
    delta_f = radar_params.delta_f;
    IFFT_length = radar_params.IFFT_length;
    symbols_per_carrier = radar_params.symbols_per_carrier;
    T_OFDM = radar_params.T_OFDM;
    
    % 初始化多天线接收矩阵
    multi_Rx_complex_carrier_matrix_radar = zeros(symbols_per_carrier, IFFT_length, M, N);
    
    num_targets = size(point_info, 1);
    fprintf('回波计算中 (总共 %d 个目标)...\n', num_targets);
    tCount1 = 0;
    
    for tgt_index = 1:num_targets
        t00 = tic;
        
        % 获取单目标信息
        R = point_info(tgt_index, 1);       % 目标距离
        V = point_info(tgt_index, 2);       % 目标速度
        theta = point_info(tgt_index, 3);   % 目标方位角
        faii = point_info(tgt_index, 4);    % 目标俯仰角
        
        % 单目标距离信息（kr）
        kr = zeros(1, IFFT_length);
        for k = 1:IFFT_length
            kr(k) = exp(-1i * 2 * pi * (k-1) * delta_f * 2 * R / c);
        end
        
        % 单目标速度信息（kd）
        kd = zeros(1, symbols_per_carrier);
        for k = 1:symbols_per_carrier
            kd(k) = exp(1i * 2 * pi * T_OFDM * (k-1) * 2 * V * f_c / c);
        end
        
        % 频域叠加时延多普勒信息
        Rx_complex_carrier_matrix_radar = Rx_complex_carrier_matrix .* (kd' * kr);
        
        % 多天线单目标角度信息（ka）
        ka = zeros(M, N);
        for index_x = 1:M
            for index_y = 1:N
                % 根据角度计算波程差
                if theta > (90*pi/180)
                    if faii <= (90*pi/180)
                        r = (index_x-1)*d*cos(pi-theta) - (index_y-1)*d*sin(pi-theta);
                        ka(index_x, index_y) = exp(-1j*2*pi*r*cos(faii)/lambda);
                    else
                        r = (index_x-1)*d*cos(pi-theta) + (index_y-1)*d*sin(pi-theta);
                        ka(index_x, index_y) = exp(-1j*2*pi*r*cos(pi-faii)/lambda);
                    end
                else
                    if faii <= (90*pi/180)
                        r = (index_x-1)*d*cos(theta) + (index_y-1)*d*sin(theta);
                        ka(index_x, index_y) = exp(1j*2*pi*r*cos(faii)/lambda);
                    else
                        r = (index_x-1)*d*cos(theta) - (index_y-1)*d*sin(theta);
                        ka(index_x, index_y) = exp(1j*2*pi*r*cos(pi-faii)/lambda);
                    end
                end
                
                % 叠加到多天线接收矩阵
                multi_Rx_complex_carrier_matrix_radar(:,:,index_x,index_y) = ...
                    multi_Rx_complex_carrier_matrix_radar(:,:,index_x,index_y) + ...
                    Rx_complex_carrier_matrix_radar * ka(index_x, index_y);
            end
        end
        
        % 剩余时间预估（每处理若干目标输出一次进度）
        tCount1 = tCount1 + toc(t00);
        if mod(tgt_index, max(1, floor(num_targets/10))) == 0 || tgt_index == num_targets
            t_step = tCount1 / tgt_index;
            t_res = (num_targets - tgt_index) * t_step;
            fprintf('  进度: %d/%d (%.1f%%), 剩余时间: %.1f 秒\n', ...
                    tgt_index, num_targets, 100*tgt_index/num_targets, t_res);
        end
    end
    
    fprintf('多天线回波信号生成完毕！\n');
end
