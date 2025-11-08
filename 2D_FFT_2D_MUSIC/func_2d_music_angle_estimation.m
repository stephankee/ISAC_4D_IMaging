function [Angle_music_matrix, Angle_music_threshold_matrix, Angle_music_abs_matrix, A2_Angle_target_cell] = func_2d_music_angle_estimation(Velocity_fft, RD_target_index, radar_params, music_params)
% 功能：2D MUSIC算法进行角度估计（方位角+俯仰角）+ CA-CFAR检测
% 输入：
%   Velocity_fft - 所有天线的速度-距离FFT结果 [symbols_per_carrier × IFFT_length × M × N]
%   RD_target_index - Range-Doppler域检测到的目标索引 [N×2]
%   radar_params - 雷达参数结构体（M, N, lambda, d, K_sub等）
%   music_params - MUSIC算法参数结构体，包含：
%       .space - 搜索粒度
%       .theta_head_offset - 方位角搜索起始偏移
%       .theta_back_offset - 方位角搜索结束偏移
%       .faii_head_offset - 俯仰角搜索起始偏移
%       .faii_back_offset - 俯仰角搜索结束偏移
% 输出：
%   Angle_music_matrix - MUSIC谱矩阵 [theta_bins × faii_bins × Angel_page_num]
%   Angle_music_threshold_matrix - CA-CFAR门限矩阵
%   Angle_music_abs_matrix - CA-CFAR检测结果矩阵
%   A2_Angle_target_cell - 每个RE检测到的角度目标索引（cell数组）

    disp('正在构建多天线角度回波矩阵......');
    
    % 提取参数
    M = radar_params.M;
    N = radar_params.N;
    lambda = radar_params.lambda;
    d = radar_params.d;
    K_sub = radar_params.K_sub;
    
    space = music_params.space;
    theta_head_offset = music_params.theta_head_offset;
    theta_back_offset = music_params.theta_back_offset;
    faii_head_offset = music_params.faii_head_offset;
    faii_back_offset = music_params.faii_back_offset;
    
    % 构建角度测量矩阵
    Angel_page_num = size(RD_target_index, 1);
    Angle_matrix = zeros(M, N, Angel_page_num);
    
    for i = 1:Angel_page_num
        Angle_matrix(:, :, i) = Velocity_fft(RD_target_index(i,1), RD_target_index(i,2), :, :);
    end
    disp('多天线角度回波信号生成完毕！');
    
    % MUSIC角度搜索
    disp('开始测角......');
    theta_list = space + theta_head_offset: space: 180 - theta_back_offset;
    faii_list = space + faii_head_offset: space: 180 - faii_back_offset;
    
    Angle_music_matrix = zeros(length(theta_list), length(faii_list), Angel_page_num);
    Angle_music_threshold_matrix = zeros(length(theta_list), length(faii_list), Angel_page_num);
    Angle_music_abs_matrix = zeros(length(theta_list), length(faii_list), Angel_page_num);
    A2_Angle_target_cell = cell(size(RD_target_index, 1), 1);
    
    win = waitbar(0, 'RE目标检测中...');
    tCount1 = 0;
    
    for i = 1:Angel_page_num
        t00 = tic;
        
        % 构建协方差矩阵
        W = Angle_matrix(:, :, i);
        W_azimuth = W(:, 1);
        W_pitch = W(1, :).';
        
        % 空间平滑算法
        R_azimuth_ns = W_azimuth * W_azimuth';
        R_pitch_ns = W_pitch * W_pitch';
        R_azimuth = smooth_covariance(R_azimuth_ns, K_sub);
        R_pitch = smooth_covariance(R_pitch_ns, K_sub);
        
        % 特征分解
        [EV_azimuth, D_azimuth] = eig(R_azimuth);
        diag_azimuth = diag(D_azimuth);
        signal_space_num_azimuth = WCA_CFAR_1D(diag_azimuth);
        En_azimuth = EV_azimuth(:, 1:(K_sub-signal_space_num_azimuth));
        
        [EV_pitch, D_pitch] = eig(R_pitch);
        diag_pitch = diag(D_pitch);
        signal_space_num_pitch = WCA_CFAR_1D(diag_pitch);
        En_pitch = EV_pitch(:, 1:(K_sub-signal_space_num_pitch));
        
        % MUSIC谱搜索
        o_matrix_azimuth_m = zeros(length(theta_list), length(faii_list));
        o_matrix_pitch_m = zeros(length(theta_list), length(faii_list));
        
        for theta_index = 1:length(theta_list)
            theta_search = theta_list(theta_index) * pi/180;
            for faii_index = 1:length(faii_list)
                faii_search = faii_list(faii_index) * pi/180;
                W_search = zeros(K_sub, K_sub);
                
                % 构建导向矢量
                for index_x = 1:K_sub
                    for index_y = 1:K_sub
                        if theta_search > (90*pi/180)
                            if faii_search <= (90*pi/180)
                                r = (index_x-1)*d*cos(pi-theta_search) - (index_y-1)*d*sin(pi-theta_search);
                                W_search(index_x, index_y) = exp(-1j*2*pi*r*cos(faii_search)/lambda);
                            else
                                r = (index_x-1)*d*cos(pi-theta_search) + (index_y-1)*d*sin(pi-theta_search);
                                W_search(index_x, index_y) = exp(-1j*2*pi*r*cos(pi-faii_search)/lambda);
                            end
                        else
                            if faii_search <= (90*pi/180)
                                r = (index_x-1)*d*cos(theta_search) + (index_y-1)*d*sin(theta_search);
                                W_search(index_x, index_y) = exp(1j*2*pi*r*cos(faii_search)/lambda);
                            else
                                r = (index_x-1)*d*cos(theta_search) - (index_y-1)*d*sin(theta_search);
                                W_search(index_x, index_y) = exp(1j*2*pi*r*cos(pi-faii_search)/lambda);
                            end
                        end
                    end
                end
                
                W_search_azimuth = W_search(:, 1);
                W_search_pitch = W_search(1, :).';
                
                o_matrix_azimuth = (W_search_azimuth'*En_azimuth)*(En_azimuth'*W_search_azimuth);
                o_matrix_pitch = (W_search_pitch'*En_pitch)*(En_pitch'*W_search_pitch);
                
                o_matrix_azimuth_m(theta_index, faii_index) = abs(1./o_matrix_azimuth);
                o_matrix_pitch_m(theta_index, faii_index) = abs(1./o_matrix_pitch);
            end
        end
        
        Angle_music_matrix(:, :, i) = o_matrix_azimuth_m .* o_matrix_pitch_m;
        
        % CA-CFAR检测
        [A2_threshold_matrix, A2_target_index, A2_detect_matrix_abs] = CA_CFAR(Angle_music_matrix(:, :, i));
        Angle_music_threshold_matrix(:, :, i) = A2_threshold_matrix;
        Angle_music_abs_matrix(:, :, i) = A2_detect_matrix_abs;
        A2_Angle_target_cell{i, 1} = A2_target_index;
        
        disp(['第', num2str(i), '个目标RE检测完毕']);
        
        % 剩余时间预估
        tCount1 = tCount1 + toc(t00);
        t_step = tCount1 / i;
        t_res = (Angel_page_num - i) * t_step;
        str = ['剩余运行时间：', num2str(t_res/60), 'min'];
        waitbar(i/Angel_page_num, win, str);
    end
    
    close(win);
    disp('测角完毕！');
end
