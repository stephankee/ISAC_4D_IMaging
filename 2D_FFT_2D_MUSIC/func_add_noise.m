function Rx_data = func_add_noise(windowed_Tx_data, SNR)
% 功能：为发送信号添加高斯白噪声
% 输入：
%   windowed_Tx_data - 加窗后的发送信号
%   SNR - 信噪比(dB)，Inf表示无噪声
% 输出：
%   Rx_data - 添加噪声后的接收信号

    if isinf(SNR)
        % 不加噪声
        Rx_data = windowed_Tx_data;
    else
        % 添加噪声
        Tx_signal_power = var(windowed_Tx_data);
        linear_SNR = 10^(SNR/10);
        noise_sigma = Tx_signal_power/linear_SNR;
        noise_scale_factor = sqrt(noise_sigma);
        noise = randn(size(windowed_Tx_data)) * noise_scale_factor;
        Rx_data = windowed_Tx_data + noise;
    end
end
