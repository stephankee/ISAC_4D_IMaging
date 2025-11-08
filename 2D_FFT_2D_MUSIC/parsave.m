function parsave(filename, Velocity_fft, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs)
% PARSAVE 用于在parfor循环中保存变量的辅助函数
% 
% 输入参数:
%   filename - 保存文件的完整路径
%   Velocity_fft - 速度FFT结果
%   RD_threshold_matrix - Range-Doppler阈值矩阵
%   RD_target_index - 检测到的目标索引
%   RD_detect_matrix_abs - Range-Doppler检测矩阵幅值
%
% 说明:
%   parfor循环不允许直接使用save命令，需要通过函数封装

save(filename, 'Velocity_fft', 'RD_threshold_matrix', 'RD_target_index', 'RD_detect_matrix_abs');

end

function parsave_compact(filename, SNR, BER, Velocity_fft_antenna_1_1, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs)
% PARSAVE_COMPACT 紧凑版本：只保存第一个天线的FFT结果以节省空间
% 
% 输入参数:
%   filename - 保存文件的完整路径
%   SNR - 当前仿真的信噪比
%   BER - 比特误码率
%   Velocity_fft_antenna_1_1 - 第一个天线的速度FFT结果（2D矩阵）
%   RD_threshold_matrix - Range-Doppler阈值矩阵
%   RD_target_index - 检测到的目标索引
%   RD_detect_matrix_abs - Range-Doppler检测矩阵幅值
%
% 说明:
%   相比完整版本，文件大小可以减少约 256 倍 (16×16)

save(filename, 'SNR', 'BER', 'Velocity_fft_antenna_1_1', 'RD_threshold_matrix', 'RD_target_index', 'RD_detect_matrix_abs');

end
