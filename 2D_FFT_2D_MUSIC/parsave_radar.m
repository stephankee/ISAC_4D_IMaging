function parsave_radar(filename, Velocity_fft_antenna_1_1, RD_threshold_matrix, RD_target_index, RD_detect_matrix_abs)
% PARSAVE_RADAR 保存雷达处理相关数据
% 
% 输入参数:
%   filename - 保存文件的完整路径
%   Velocity_fft_antenna_1_1 - 第一个天线的速度-距离FFT结果（2D矩阵）
%   RD_threshold_matrix - Range-Doppler CFAR检测门限矩阵
%   RD_target_index - 检测到的目标索引 [N×2]，每行为 [velocity_idx, range_idx]
%   RD_detect_matrix_abs - Range-Doppler检测结果矩阵幅值
%
% 说明:
%   只保存第一个天线(1,1)的FFT结果以节省空间
%   完整的多天线数据可以从OFDM数据重新计算
%   文件大小相比保存所有天线减少约 256 倍 (16×16)
%   parfor循环不允许直接使用save命令，需要通过函数封装

save(filename, 'Velocity_fft_antenna_1_1', 'RD_threshold_matrix', 'RD_target_index', 'RD_detect_matrix_abs', '-v7.3');

end
