function [windowed_Tx_data, baseband_out, complex_carrier_matrix, ofdm_params] = func_generate_ofdm_signal()
% func_generate_ofdm_signal - 生成OFDM信号
%
% 功能说明:
%   生成完整的OFDM信号，包括通信信息（m序列）和PRS参考信号（gold序列），
%   经过4QAM调制、IFFT、添加循环前后缀、加窗等处理，最终输出串行发送信号
%
% 输出参数:
%   windowed_Tx_data          - [1×N] 加窗后的串行发送信号
%   baseband_out              - [1×baseband_out_length] 基带比特序列
%   complex_carrier_matrix    - [symbols_per_carrier×IFFT_length] 调制后的复数符号矩阵
%   ofdm_params               - 结构体，包含所有OFDM参数
%
% 说明:
%   - 使用m序列填充通信信息比特
%   - 使用gold序列填充PRS参考信号比特
%   - 采用4QAM调制方式
%   - 加窗后符号重叠传输（后缀与下一符号前缀重叠）
%
% 作者: AI Assistant
% 日期: 2025-11-07

%% OFDM参数设置
ref_space = 4;          % 每4个时隙插入一组导频
slot_num = 16;          % 时隙数
IFFT_length = 2048;     % 子载波资源数
carrier_count = 200;    % 子载波数
ref_carrier_count = IFFT_length/4; % 导频频域占用,comb4
comb_num = 4;
symbols_per_carrier = 224; % OFDM符号数
ref_symbol_count = (slot_num/ref_space) * 12; % 导频时域占用

bits_per_symbol = 2;    % 4QAM对应2比特

PrefixRatio = 1/4;      % 循环前缀比率
GI = PrefixRatio * IFFT_length;     % 循环前缀长度
beta = 1/32;            % 循环后缀比率
GIP = beta * (IFFT_length + GI);    % 循环后缀长度

%% 基本参数设置
c = 3*10^8;             % 电磁波传播速度, m/s
delta_f = 240*10^3;     % 载波间隔, Hz
f_c = 70*10^9;          % 信号中心频偏, Hz

% 计算OFDM符号周期
T_OFDM = (IFFT_length + GI) / delta_f / IFFT_length;

%% 保存参数到结构体
ofdm_params = struct();
ofdm_params.ref_space = ref_space;
ofdm_params.slot_num = slot_num;
ofdm_params.IFFT_length = IFFT_length;
ofdm_params.carrier_count = carrier_count;
ofdm_params.ref_carrier_count = ref_carrier_count;
ofdm_params.comb_num = comb_num;
ofdm_params.symbols_per_carrier = symbols_per_carrier;
ofdm_params.ref_symbol_count = ref_symbol_count;
ofdm_params.bits_per_symbol = bits_per_symbol;
ofdm_params.PrefixRatio = PrefixRatio;
ofdm_params.GI = GI;
ofdm_params.beta = beta;
ofdm_params.GIP = GIP;
ofdm_params.c = c;
ofdm_params.delta_f = delta_f;
ofdm_params.f_c = f_c;
ofdm_params.T_OFDM = T_OFDM;

%% 发送数据生成 - 构建索引
disp('正在构建发送数据通信信息与PRS索引......');

baseband_out_length = IFFT_length * symbols_per_carrier * bits_per_symbol;
PSF_num = ref_carrier_count * ref_symbol_count * bits_per_symbol;
Info_num = baseband_out_length - PSF_num;

% 参考信号RE频域索引
carriers_f = zeros(comb_num, ref_carrier_count);
Info_carriers_f_1 = zeros(comb_num, IFFT_length - ref_carrier_count);
f_offset = [0, 2, 1, 3];

for i = 1:comb_num
    offset = f_offset(i);
    for j = 1:ref_carrier_count
        carriers_f(i, j) = comb_num*(j-1) + 1 + offset;
    end
    Info_carriers_f_1(i, :) = setdiff((1:IFFT_length), carriers_f(i, :));
end

Info_carriers_f_1_full = repmat(Info_carriers_f_1, (12/comb_num) * ref_space, 1);
carriers_f_full = repmat(carriers_f, (12/comb_num) * ref_space, 1);

% 参考信号RE时域索引
symbols_t = zeros(1, ref_symbol_count);
for i = 1:slot_num/ref_space
    symbols_t(1, (i-1)*12+1 : i*12) = 14*ref_space*(i-1)+2 : 14*ref_space*(i-1)+13;
end

Info_symbol_t_1 = symbols_t;
Info_carriers_f_2 = repmat((1:IFFT_length), (symbols_per_carrier - ref_symbol_count), 1);
Info_symbol_t_2 = setdiff((1:slot_num*14), symbols_t);

% 参考信号索引
ref_t_f_index = zeros(size(symbols_t, 2), size(carriers_f_full, 2), 2);
ref_t_f_index(:, :, 1) = repmat(symbols_t', 1, ref_carrier_count);
ref_t_f_index(:, :, 2) = carriers_f_full;

disp('发送数据通信信息与PRS索引构建完毕！');

%% m序列模拟的随机通信信息
disp('正在使用m序列填充通信信息数据比特......');

Tx_matric = zeros(IFFT_length*bits_per_symbol, symbols_per_carrier);

for i = 1:symbols_per_carrier
    Order_number = 12; % m序列的阶数
    mg = zeros(IFFT_length*bits_per_symbol, 1);
    
    % 生成m序列本源多项式的系数
    tmp = primpoly(Order_number, 'all', 'nodisplay');
    cur_tmp = int32(tmp(1)); % 选择第一个
    
    % 十进制化为二进制
    f = zeros(1, Order_number+2);
    for j = 1:Order_number+1
        if mod(cur_tmp, 2) == 1
            f(j) = 1;
        end
        cur_tmp = idivide(int32(cur_tmp), int32(2), 'floor');
    end
    f = f(1, 2:Order_number+1);
    
    tmp = m_generate(f);
    mg(1:IFFT_length*bits_per_symbol-1, 1) = tmp(1:IFFT_length*bits_per_symbol-1);
    Tx_matric(:, i) = mg;
end

Tx_matric = Tx_matric';
disp('通信信息数据比特填充完毕！');

%% gold序列模拟PRS信息
disp('正在使用gold序列填充PRS数据比特......');

for m = 1:ref_symbol_count
    n_slot = ceil(symbols_t(m)/14) - 1;
    seq = goldseq(n_slot, symbols_t(m)-1); % 伪随机序列
    
    for k = 1:ref_carrier_count
        Tx_matric(ref_t_f_index(m, k, 1), 2*ref_t_f_index(m, k, 2)-1) = ...
            seq(2*ref_t_f_index(m, k, 2)-1);
        Tx_matric(ref_t_f_index(m, k, 1), 2*ref_t_f_index(m, k, 2)) = ...
            seq(2*ref_t_f_index(m, k, 2));
    end
end

baseband_out = reshape(Tx_matric', 1, baseband_out_length);
disp('PRS数据比特填充完毕！');

%% 4QAM调制
disp('正在进行4QAM调制......');

complex_carrier_matrix = qam4(baseband_out);
complex_carrier_matrix = reshape(complex_carrier_matrix', IFFT_length, symbols_per_carrier)';

disp('调制完毕！');

%% IFFT
disp('正在使用IFFT生成时域OFDM符号......');

IFFT_modulation = complex_carrier_matrix;
signal_after_IFFT = ifft(IFFT_modulation, IFFT_length, 2);

disp('时域OFDM符号生成完毕！');

%% 加循环前缀CP和后缀
disp('正在添加循环前缀后缀......');

time_wave_matrix_cp = zeros(symbols_per_carrier, IFFT_length+GI+GIP);

for k = 1:symbols_per_carrier
    time_wave_matrix_cp(k, GI+1 : GI+IFFT_length) = signal_after_IFFT(k, :);
    time_wave_matrix_cp(k, 1:GI) = signal_after_IFFT(k, (IFFT_length-GI+1):IFFT_length); % 循环前缀
    time_wave_matrix_cp(k, (IFFT_length+GI+1):(IFFT_length+GI+GIP)) = signal_after_IFFT(k, 1:GIP); % 循环后缀
end

disp('循环前缀后缀添加完毕！');

%% OFDM符号加窗操作
disp('正在时域加窗并进行并串转换......');

windowed_time_wave_matrix_cp = zeros(symbols_per_carrier, IFFT_length+GI+GIP);

for i = 1:symbols_per_carrier
    windowed_time_wave_matrix_cp(i, :) = time_wave_matrix_cp(i, :) .* rcoswindow(beta, IFFT_length+GI)';
end

% 并串转换，加窗的ofdm符号传输时当前符号的后缀与下一个符号的前缀重合
windowed_Tx_data = zeros(1, symbols_per_carrier*(IFFT_length+GI)+GIP);
windowed_Tx_data(1:IFFT_length+GI+GIP) = windowed_time_wave_matrix_cp(1, :);

for i = 1:symbols_per_carrier-1
    windowed_Tx_data((IFFT_length+GI)*i+1 : (IFFT_length+GI)*(i+1)+GIP) = ...
        windowed_time_wave_matrix_cp(i+1, :);
end

disp('串行发送信号生成成功！');

end
