function parsave_ofdm(filename, Rx_complex_carrier_matrix, BER, SNR)
% PARSAVE_OFDM 保存OFDM通信相关数据
% 
% 输入参数:
%   filename - 保存文件的完整路径
%   Rx_complex_carrier_matrix - 接收端解调后的复数载波矩阵
%   BER - 误码率 (Bit Error Rate)
%   SNR - 信噪比
%
% 保存的文件结构:
%   - Rx_complex_carrier_matrix: OFDM接收信号
%   - BER: 误码率
%   - SNR: 信噪比
%
% 说明:
%   parfor循环不允许直接使用save命令，需要通过函数封装

save(filename, 'Rx_complex_carrier_matrix', 'BER', 'SNR', '-v7.3');

end
