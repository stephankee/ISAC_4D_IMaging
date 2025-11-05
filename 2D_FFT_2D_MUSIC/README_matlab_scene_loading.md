# MATLAB 场景数据读取说明

## 概述
本文档说明如何在 MATLAB 中读取由 `batch_generate_scenario1.py` 生成的场景数据。

## 文件列表

### MATLAB 函数
- **`environment_new_test.m`**: 从 .mat 文件读取场景数据的核心函数
- **`environment.m`**: 原始的硬编码场景生成函数（用于对比）

### MATLAB 测试脚本
- **`test_environment_new.m`**: 完整的测试脚本，对比新旧场景
- **`example_use_new_scene.m`**: 使用示例，展示如何在成像代码中使用新场景

## 快速开始

### 1. 基本使用

```matlab
% 加载默认场景（scene_001.mat）
scatterers = environment_new_test();

% 或指定特定场景
scatterers = environment_new_test('scenario_1/mat_files/scene_002.mat');

% 返回的矩阵格式: [N × 4]
% 第1列: X 坐标 (m)
% 第2列: Y 坐标 (m)  
% 第3列: Z 坐标 (m)
% 第4列: 速度 (m/s)
```

### 2. 在现有 ISAC 成像代码中使用

**原始代码：**
```matlab
% 生成场景
scatterers = environment();

% 后续成像处理...
```

**新代码：**
```matlab
% 从文件加载场景
scatterers = environment_new_test('scenario_1/mat_files/scene_001.mat');

% 后续成像处理完全不变...
```

接口完全兼容，无需修改后续代码！

### 3. 批量处理多个场景

```matlab
% 获取所有场景文件
scene_files = dir('scenario_1/mat_files/scene_*.mat');

for i = 1:length(scene_files)
    % 构建文件路径
    scene_path = fullfile(scene_files(i).folder, scene_files(i).name);
    
    % 加载场景
    scatterers = environment_new_test(scene_path);
    
    % 进行成像处理
    result = your_imaging_function(scatterers);
    
    % 保存结果
    save(sprintf('result_%03d.mat', i), 'result');
end
```

## 运行测试

### 测试 1: 完整对比测试
```matlab
% 在 MATLAB 命令行中运行
run('test_environment_new.m')
```

这将会：
- 加载新场景和原始场景
- 显示统计信息对比
- 生成可视化对比图（3D视图、俯视图、速度分布）
- 验证数据完整性

### 测试 2: 使用示例
```matlab
% 在 MATLAB 命令行中运行
run('example_use_new_scene.m')
```

这将演示：
- 多种场景加载方式
- 批量处理示例
- 可视化示例

## 函数详解

### environment_new_test(scene_file)

**功能**: 从 .mat 文件读取场景数据并转换为与原始 `environment()` 兼容的格式

**参数**:
- `scene_file` (可选): .mat 文件路径
  - 如果不提供，默认使用 `'scenario_1/mat_files/scene_001.mat'`

**返回值**:
- `outputArg1`: [N×4] 矩阵
  - 第1列: X 坐标 (m)
  - 第2列: Y 坐标 (m)
  - 第3列: Z 坐标 (m)
  - 第4列: 速度 (m/s)

**特点**:
- 自动为每个散射点分配对应的速度
- 车辆散射点使用车辆速度
- 行人散射点使用行人速度
- 静止对象（隔离带、路灯）速度为 0
- 完全兼容原始 `environment()` 函数的返回格式

## 数据结构说明

### .mat 文件结构

每个场景 .mat 文件包含：

```matlab
data = load('scenario_1/mat_files/scene_001.mat');

% 基本信息
data.scene_id                    % 场景编号
data.object_counts               % 对象计数结构体
  .num_vehicles                  % 车辆数量
  .num_pedestrians               % 行人数量
  .num_lights                    % 路灯数量
  .num_scatterers                % 总散射点数

% 散射点数据
data.scatterers                  % 散射点结构体
  .all                           % [N×4] 所有散射点 (x,y,z,RCS)
  .vehicles                      % [M×4] 车辆散射点
  .barrier                       % [P×4] 隔离带散射点
  .lights                        % [Q×4] 路灯散射点
  .pedestrians                   % [R×4] 行人散射点

% 车辆信息
data.vehicles                    % 车辆信息结构体
  .centers                       % [N_v×3] 车辆中心点
  .directions                    % [1×N_v] 朝向角度（弧度）
  .velocities                    % [1×N_v] 速度 (m/s)

% 行人信息
data.pedestrians                 % 行人信息结构体
  .centers                       % [N_p×3] 行人中心点
  .directions                    % [1×N_p] 朝向角度（弧度）
  .velocities                    % [1×N_p] 速度 (m/s)

% 固定对象
data.barrier                     % 隔离带信息
data.lights                      % 路灯信息
data.config                      % 场景配置
```

## 可视化示例

### 基本可视化
```matlab
scatterers = environment_new_test('scenario_1/mat_files/scene_001.mat');

% 3D 散点图（按速度着色）
figure;
scatter3(scatterers(:,1), scatterers(:,2), scatterers(:,3), ...
         30, scatterers(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');
title('Scene Scatterers (colored by velocity)');
colorbar;
grid on;
```

### 俯视图
```matlab
% 俯视图（按速度着色）
figure;
scatter(scatterers(:,1), scatterers(:,2), ...
        50, scatterers(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
title('Top View');
colorbar;
axis equal;
grid on;
```

### 分对象可视化
```matlab
% 加载原始数据以区分对象类型
data = load('scenario_1/mat_files/scene_001.mat');

figure;
hold on;
scatter3(data.scatterers.vehicles(:,1), ...
         data.scatterers.vehicles(:,2), ...
         data.scatterers.vehicles(:,3), 'r.');
scatter3(data.scatterers.pedestrians(:,1), ...
         data.scatterers.pedestrians(:,2), ...
         data.scatterers.pedestrians(:,3), 'b.');
scatter3(data.scatterers.barrier(:,1), ...
         data.scatterers.barrier(:,2), ...
         data.scatterers.barrier(:,3), 'g.');
scatter3(data.scatterers.lights(:,1), ...
         data.scatterers.lights(:,2), ...
         data.scatterers.lights(:,3), 'yo', 'MarkerSize', 8);
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');
legend('Vehicles', 'Pedestrians', 'Barrier', 'Lights');
grid on;
view(3);
```

## 注意事项

1. **速度分配**: 
   - `environment_new_test()` 自动为散射点分配速度
   - 车辆和行人的散射点使用对应对象的速度
   - 隔离带和路灯散射点速度为 0

2. **坐标系统**:
   - X轴: 0-28m
   - Y轴: 0-28m
   - Z轴: 0-20m
   - 与原始 `environment.m` 的坐标范围不同

3. **角度单位**:
   - .mat 文件中的方向角度使用弧度制
   - 如需使用请转换为度: `degrees = radians * 180 / pi`

4. **文件路径**:
   - 使用相对路径或绝对路径
   - 确保 .mat 文件存在于指定位置

## 与原始 environment.m 的区别

| 特性 | environment.m | environment_new_test.m |
|------|---------------|------------------------|
| 场景来源 | 硬编码 | 从文件读取 |
| 灵活性 | 固定场景 | 可加载任意场景 |
| 对象数量 | 固定 | 可变 |
| 坐标范围 | 约 0-28m | 0-28m |
| 返回格式 | [N×4] (x,y,z,v) | [N×4] (x,y,z,v) |
| 接口兼容性 | - | 完全兼容 |

## 故障排除

### 问题1: 文件不存在错误
```
错误: 场景文件不存在: scenario_1/mat_files/scene_001.mat
```
**解决**: 
- 检查文件路径是否正确
- 确保已运行 `batch_generate_scenario1.py` 生成场景
- 检查 MATLAB 当前工作目录

### 问题2: 速度值全为 0
**原因**: 可能是速度分配逻辑有误
**解决**: 检查 .mat 文件中是否包含正确的速度信息

### 问题3: 矩阵维度错误
**解决**: 确保 .mat 文件是由最新版本的 `batch_generate_scenario1.py` 生成的

## 进一步开发

如需在 ISAC 成像主流程中使用新场景：

1. 找到调用 `environment()` 的位置
2. 替换为 `environment_new_test('path/to/scene.mat')`
3. 后续代码无需修改

例如在 `ref_ofdm_imaging_2DFFT_2DMUSIC.m` 中：
```matlab
% 原来的代码
% pos_all = environment();

% 新代码
pos_all = environment_new_test('scenario_1/mat_files/scene_001.mat');
```

## 相关文件
- Python 生成脚本: `batch_generate_scenario1.py`
- Python 检查工具: `inspect_mat_file.py`
- Python 文档: `README_batch_generate_scenario1.md`
