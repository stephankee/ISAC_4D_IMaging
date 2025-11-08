function [pos_all, angle_all] = func_reconstruct_target_positions(RD_target_index, A2_Angle_target_cell, base_pos, radar_params, music_params)
% 功能：根据Range-Doppler和角度估计结果重建目标笛卡尔坐标
% 输入：
%   RD_target_index - Range-Doppler域检测到的目标索引 [N×2]
%   A2_Angle_target_cell - 每个RE检测到的角度目标索引（cell数组）
%   base_pos - 基站位置 [x, y, z]
%   radar_params - 雷达参数结构体（c, delta_f, f_c, T_OFDM, IFFT_length, symbols_per_carrier）
%   music_params - MUSIC参数结构体（space, theta_head_offset, faii_head_offset）
% 输出：
%   pos_all - 所有目标的位置矩阵 [N×4]: (x, y, z, velocity)
%   angle_all - 所有目标的角度矩阵 [N×2]: (theta, faii)

    c = radar_params.c;
    delta_f = radar_params.delta_f;
    f_c = radar_params.f_c;
    T_OFDM = radar_params.T_OFDM;
    IFFT_length = radar_params.IFFT_length;
    symbols_per_carrier = radar_params.symbols_per_carrier;
    
    space = music_params.space;
    theta_head_offset = music_params.theta_head_offset;
    faii_head_offset = music_params.faii_head_offset;
    
    pos_all = [];
    angle_all = [];
    
    for i = 1:size(RD_target_index, 1)
        % 速度距离计算
        M_R = ((RD_target_index(i, 2)-1) / IFFT_length) * (c / 2 / delta_f);
        N_V = -((RD_target_index(i, 1)-symbols_per_carrier/2-1) / symbols_per_carrier) * (c / 2 / f_c / T_OFDM);
        
        % 空间角度查询
        for j = 1:size(A2_Angle_target_cell{i, 1}, 1)
            theta_estimation = A2_Angle_target_cell{i, 1}(j,1) * space + theta_head_offset;
            faii_estimation = A2_Angle_target_cell{i, 1}(j,2) * space + faii_head_offset;
            
            angle_all = [angle_all; theta_estimation faii_estimation];
            
            % 恢复笛卡尔坐标系信息
            pos_z = base_pos(3) - M_R * cosd(faii_estimation);
            pos_x = base_pos(1) + M_R * sind(faii_estimation) * cosd(theta_estimation);
            pos_y = base_pos(2) - M_R * sind(faii_estimation) * sind(theta_estimation);
            
            % 储存位置信息
            pos_all = [pos_all; pos_x pos_y pos_z N_V];
        end
    end
end
