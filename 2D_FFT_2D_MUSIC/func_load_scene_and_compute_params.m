function [environment_point, point_info] = func_load_scene_and_compute_params(scene_file, base_pos)
% 功能：加载蒙特卡洛场景文件并计算散射点参数（距离、速度、方位角、俯仰角）
% 输入：
%   scene_file - 场景文件路径（.mat文件）
%   base_pos - 基站天线位置 [x, y, z]
% 输出：
%   environment_point - 散射点矩阵 [N×4]: (x, y, z, velocity)
%   point_info - 散射点信息矩阵 [N×4]: (距离, 速度, 方位角, 俯仰角)

    disp('正在从蒙特卡洛场景文件加载散射环境......');
    
    % 加载场景文件
    loaded_data = load(scene_file);
    
    % 提取所有散射点数据 [N×4] - (x, y, z, velocity)
    environment_point = loaded_data.scatterers.all;
    
    disp(['成功加载场景文件：', scene_file]);
    fprintf('散射点总数：%d\n', size(environment_point, 1));
    fprintf('车辆散射点：%d\n', size(loaded_data.scatterers.vehicles, 1));
    fprintf('行人散射点：%d\n', size(loaded_data.scatterers.pedestrians, 1));
    fprintf('隔离带散射点：%d\n', size(loaded_data.scatterers.barrier, 1));
    fprintf('路灯散射点：%d\n', size(loaded_data.scatterers.lights, 1));
    
    % 计算散射点参数
    point_info = zeros(size(environment_point, 1), 4);
    base_pos_full = repmat(base_pos, size(environment_point, 1), 1);
    
    % 距离
    R_info = sqrt((environment_point(:,1) - base_pos_full(:,1)).^2 + ...
                  (environment_point(:,2) - base_pos_full(:,2)).^2 + ...
                  (environment_point(:,3) - base_pos_full(:,3)).^2);
    
    % 速度
    V_info = environment_point(:,4);
    
    % 方位角与俯仰角
    xoy_dis = sqrt((environment_point(:,1) - base_pos_full(:,1)).^2 + ...
                   (environment_point(:,2) - base_pos_full(:,2)).^2);
    A1_info = acos((base_pos_full(:,1) - environment_point(:,1)) ./ xoy_dis);
    A2_info = acos((base_pos_full(:,3) - environment_point(:,3)) ./ R_info);
    
    point_info(:,1) = R_info;
    point_info(:,2) = V_info;
    point_info(:,3) = A1_info;
    point_info(:,4) = A2_info;
    
    disp('速度、时延、方位信息模拟完毕！');
end
