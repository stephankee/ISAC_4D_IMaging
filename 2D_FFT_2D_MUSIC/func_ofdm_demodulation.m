function [Rx_complex_carrier_matrix, BER] = func_ofdm_demodulation(Rx_data, baseband_out, IFFT_length, symbols_per_carrier, GI, GIP)
% 功能：OFDM信号解调与误比特率计算
% 输入：
%   Rx_data - 接收信号
%   baseband_out - 原始发送比特（用于BER计算）
%   IFFT_length - IFFT长度
%   symbols_per_carrier - OFDM符号数
%   GI - 循环前缀长度
%   GIP - 循环后缀长度
% 输出：
%   Rx_complex_carrier_matrix - 频域复信号矩阵 [symbols_per_carrier × IFFT_length]
%   BER - 误比特率

    disp('正在进行串并转换与循环前后缀消除......');
    Rx_data_matrix = zeros(symbols_per_carrier, IFFT_length+GI+GIP);
    
    % 串并转换
    for i=1:symbols_per_carrier
        Rx_data_matrix(i,:) = Rx_data(1, (i-1)*(IFFT_length+GI)+1:i*(IFFT_length+GI)+GIP);
    end
    
    % 循环前后缀去除
    Rx_data_complex_matrix = Rx_data_matrix(:, GI+1:IFFT_length+GI);
    disp('并行信号恢复成功！');
    
    % FFT恢复频域信息
    disp('正在使用FFT恢复频域信息......');
    Y1 = fft(Rx_data_complex_matrix, IFFT_length, 2);
    Rx_carriers = Y1;
    Rx_phase = angle(Rx_carriers);
    Rx_mag = abs(Rx_carriers);
    
    % 极坐标转笛卡尔坐标
    [M, N] = pol2cart(Rx_phase, Rx_mag);
    Rx_complex_carrier_matrix = complex(M, N);
    disp('频域信息恢复成功！');
    
    % 4QAM解调
    disp('正在解调获取原始数据比特......');
    Rx_serial_complex_symbols = reshape(Rx_complex_carrier_matrix', 1, size(Rx_complex_carrier_matrix,1)*size(Rx_complex_carrier_matrix,2))';
    Rx_decoded_binary_symbols = demoduqam4(Rx_serial_complex_symbols);
    baseband_in = Rx_decoded_binary_symbols;
    disp('解调完毕！');
    
    % 计算误比特率
    bit_errors = find(baseband_in ~= baseband_out);
    bit_error_count = size(bit_errors, 2);
    baseband_out_length = length(baseband_out);
    BER = bit_error_count / baseband_out_length;
    disp(['误码率为：', num2str(BER)]);
end
