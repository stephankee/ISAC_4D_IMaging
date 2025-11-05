function [outputArg1] = environment_new_test(scene_file)
%ENVIRONMENT_NEW_TEST 从 .mat 文件读取场景环境
%   读取由 batch_generate_scenario1.py 生成的场景数据
%   参数：
%       scene_file: .mat 文件路径，例如 'scenario_1/mat_files/scene_001.mat'
%   返回：
%       outputArg1: [N×4] 散射点矩阵 (x, y, z, velocity)
%
%   示例：
%       scatterers = environment_new_test('scenario_1/mat_files/scene_001.mat');
%       scatter3(scatterers(:,1), scatterers(:,2), scatterers(:,3), 50, scatterers(:,4), 'filled');

%% 检查输入参数
if nargin < 1
    % 如果没有提供参数，使用默认的测试场景
    scene_file = 'scenario_1/mat_files/scene_001.mat';
    fprintf('未提供场景文件，使用默认场景: %s\n', scene_file);
end

%% 加载场景数据
if ~exist(scene_file, 'file')
    error('场景文件不存在: %s', scene_file);
end

fprintf('正在加载场景: %s\n', scene_file);
data = load(scene_file);

%% 提取散射点数据
% 所有散射点 [N×4]: (x, y, z, RCS)
all_scatterers = data.scatterers.all;

fprintf('场景 ID: %d\n', data.scene_id);
fprintf('对象统计:\n');
fprintf('  - 车辆数量: %d\n', data.object_counts.num_vehicles);
fprintf('  - 行人数量: %d\n', data.object_counts.num_pedestrians);
fprintf('  - 路灯数量: %d\n', data.object_counts.num_lights);
fprintf('  - 总散射点数: %d\n', data.object_counts.num_scatterers);

%% 构建速度场
% 原始的 environment.m 返回 [N×4] 矩阵，最后一列是速度
% 这里需要为每个散射点分配对应的速度值

num_vehicle_scatterers = size(data.scatterers.vehicles, 1);
num_barrier_scatterers = size(data.scatterers.barrier, 1);
num_light_scatterers = size(data.scatterers.lights, 1);
num_pedestrian_scatterers = size(data.scatterers.pedestrians, 1);

% 初始化速度列
velocity_column = zeros(size(all_scatterers, 1), 1);

%% 为车辆散射点分配速度
if num_vehicle_scatterers > 0
    vehicle_velocities = data.vehicles.velocities(:);  % [N_vehicles×1]
    vehicle_centers = data.vehicles.centers;           % [N_vehicles×3]
    vehicle_scatterers = data.scatterers.vehicles;     % [M×4]
    
    % 为每个车辆的散射点分配速度
    % 假设散射点按车辆顺序排列
    scatterers_per_vehicle = num_vehicle_scatterers / length(vehicle_velocities);
    
    for i = 1:length(vehicle_velocities)
        start_idx = round((i-1) * scatterers_per_vehicle) + 1;
        end_idx = round(i * scatterers_per_vehicle);
        velocity_column(start_idx:end_idx) = vehicle_velocities(i);
    end
end

%% 为隔离带散射点分配速度（静止，速度=0）
barrier_start = num_vehicle_scatterers + 1;
barrier_end = barrier_start + num_barrier_scatterers - 1;
% 已经初始化为0，无需再设置

%% 为路灯散射点分配速度（静止，速度=0）
light_start = barrier_end + 1;
light_end = light_start + num_light_scatterers - 1;
% 已经初始化为0，无需再设置

%% 为行人散射点分配速度
if num_pedestrian_scatterers > 0
    pedestrian_velocities = data.pedestrians.velocities(:);  % [N_pedestrians×1]
    pedestrian_centers = data.pedestrians.centers;           % [N_pedestrians×3]
    pedestrian_scatterers = data.scatterers.pedestrians;     % [M×4]
    
    % 为每个行人的散射点分配速度
    pedestrian_start = light_end + 1;
    scatterers_per_pedestrian = num_pedestrian_scatterers / length(pedestrian_velocities);
    
    for i = 1:length(pedestrian_velocities)
        start_idx = pedestrian_start + round((i-1) * scatterers_per_pedestrian);
        end_idx = pedestrian_start + round(i * scatterers_per_pedestrian) - 1;
        velocity_column(start_idx:end_idx) = pedestrian_velocities(i);
    end
end

%% 构建输出矩阵 [N×4]: (x, y, z, velocity)
% 注意：原始 environment.m 的第4列是速度（m/s）
% 而我们保存的第4列是 RCS
% 这里用速度替换 RCS 列，以保持与原始接口一致
outputArg1 = all_scatterers;
outputArg1(:, 4) = velocity_column;

fprintf('已成功加载 %d 个散射点\n', size(outputArg1, 1));
fprintf('速度范围: [%.2f, %.2f] m/s\n', min(velocity_column), max(velocity_column));

end
