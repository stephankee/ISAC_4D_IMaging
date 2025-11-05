# Batch Generate Scenario 1 - 使用说明

## 概述
`batch_generate_scenario1.py` 是一个批量生成蒙特卡洛交通场景的脚本，支持将场景数据保存为 MATLAB 可读的 .mat 文件格式。

## 功能特性
- 批量生成多个场景
- 自动保存场景可视化图片（PNG 格式）
- 保存场景数据为 MATLAB .mat 文件
- 生成统计图表
- 生成汇总数据文件

## 使用方法

### 基本用法
```bash
python batch_generate_scenario1.py --num-scenes 10
```

### 命令行参数
- `--num-scenes`: 要生成的场景数量（默认：10）
- `--output-dir`: 输出目录（默认：scenario_1）
- `--seed`: 起始随机种子（默认：0）
- `--no-mat`: 不保存 .mat 文件（只生成图片）

### 示例
```bash
# 生成 5 个场景，保存到 my_scenarios 目录
python batch_generate_scenario1.py --num-scenes 5 --output-dir my_scenarios

# 生成 20 个场景，使用特定随机种子
python batch_generate_scenario1.py --num-scenes 20 --seed 42

# 只生成图片，不保存 .mat 文件
python batch_generate_scenario1.py --num-scenes 10 --no-mat
```

## 输出文件结构

```
output_dir/
├── scene_001.png           # 场景可视化图片
├── scene_002.png
├── ...
├── statistics.png          # 统计图表
├── summary.mat             # 汇总数据文件
└── mat_files/              # MATLAB 数据文件目录
    ├── scene_001.mat       # 场景 1 的详细数据
    ├── scene_002.mat
    └── ...
```

## MAT 文件结构

### 单个场景文件 (scene_XXX.mat)

每个场景 .mat 文件包含以下字段：

#### 1. 场景基本信息
- `scene_id`: 场景编号（整数）
- `object_counts`: 对象计数结构体
  - `num_vehicles`: 车辆数量
  - `num_pedestrians`: 行人数量
  - `num_lights`: 路灯数量
  - `num_scatterers`: 总散射点数量

#### 2. 散射点数据 (scatterers)
- `all`: 所有散射点 [N×4] - (x, y, z, RCS)
- `vehicles`: 车辆散射点 [M×4]
- `barrier`: 隔离带散射点 [P×4]
- `lights`: 路灯散射点 [Q×4]
- `pedestrians`: 行人散射点 [R×4]

#### 3. 车辆详细信息 (vehicles)
- `centers`: 车辆中心点 [N×3] - (x, y, z)
- `directions`: 车辆朝向角度 [1×N] - 弧度制
- `velocities`: 车辆速度 [1×N] - m/s
- `scatterers`: 车辆散射点 [M×4]

#### 4. 行人详细信息 (pedestrians)
- `centers`: 行人中心点 [N×3]
- `directions`: 行人朝向角度 [1×N]
- `velocities`: 行人速度 [1×N]
- `scatterers`: 行人散射点 [M×4]

#### 5. 固定对象信息
**隔离带 (barrier):**
- `start`: 起始点 [3×1] - (x, y, z)
- `center`: 中心点 [3×1]
- `length`: 长度（米）
- `direction`: 方向角度（弧度）
- `scatterers`: 散射点 [N×4]

**路灯 (lights):**
- `centers`: 路灯位置 [N×3]
- `scatterers`: 路灯散射点 [M×4]

#### 6. 场景配置 (config)
- `space_x_range`: X轴范围 [0, 28]
- `space_y_range`: Y轴范围 [0, 28]
- `space_z_range`: Z轴范围 [0, 20]
- `barrier_x`: 隔离带X坐标
- `description`: 场景描述文字

### 汇总文件 (summary.mat)

包含所有场景的统计信息：
- `num_scenes`: 场景总数
- `seed_start`: 起始随机种子
- `vehicle_counts`: 每个场景的车辆数量 [1×N]
- `pedestrian_counts`: 每个场景的行人数量 [1×N]
- `total_scatterers`: 每个场景的总散射点数 [1×N]
- `scene_info`: 场景详细信息（结构体数组）

## MATLAB 读取示例

### 读取单个场景
```matlab
% 加载场景数据
data = load('scenario_1/mat_files/scene_001.mat');

% 获取所有散射点
all_scatterers = data.scatterers.all;  % [N, 4]
x = all_scatterers(:, 1);
y = all_scatterers(:, 2);
z = all_scatterers(:, 3);
rcs = all_scatterers(:, 4);

% 获取车辆信息
vehicle_centers = data.vehicles.centers;     % [N, 3]
vehicle_directions = data.vehicles.directions; % [1, N]
vehicle_velocities = data.vehicles.velocities; % [1, N]

% 获取行人信息
pedestrian_centers = data.pedestrians.centers;
pedestrian_directions = data.pedestrians.directions;

% 可视化
figure;
scatter3(x, y, z, 50, rcs, 'filled');
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');
title(sprintf('Scene %d', data.scene_id));
colorbar;
```

### 读取汇总数据
```matlab
% 加载汇总数据
summary = load('scenario_1/summary.mat');

% 统计信息
fprintf('场景数量: %d\n', summary.num_scenes);
fprintf('车辆数量: %.2f ± %.2f\n', mean(summary.vehicle_counts), std(summary.vehicle_counts));
fprintf('行人数量: %.2f ± %.2f\n', mean(summary.pedestrian_counts), std(summary.pedestrian_counts));
fprintf('散射点数: %.2f ± %.2f\n', mean(summary.total_scatterers), std(summary.total_scatterers));

% 绘制统计图
figure;
subplot(1,2,1);
histogram(summary.vehicle_counts);
xlabel('车辆数量');
ylabel('场景数');
title('车辆数量分布');

subplot(1,2,2);
histogram(summary.pedestrian_counts);
xlabel('行人数量');
ylabel('场景数');
title('行人数量分布');
```

## 工具脚本

### inspect_mat_file.py
用于检查 .mat 文件内容的 Python 工具：

```bash
# 检查场景文件
python inspect_mat_file.py scenario_1/mat_files/scene_001.mat

# 检查汇总文件
python inspect_mat_file.py scenario_1/summary.mat --summary
```

## 注意事项

1. **散射点坐标系统**: 所有坐标使用右手坐标系，单位为米
   - X轴: 0-28m
   - Y轴: 0-28m
   - Z轴: 0-20m

2. **角度单位**: 所有方向角度保存为弧度制（radians）

3. **RCS 值**: 散射点的雷达散射截面（第4列）单位为平方米

4. **速度**: 可以为负值，表示反向运动

5. **MATLAB 兼容性**: .mat 文件使用 scipy.io.savemat 生成，兼容 MATLAB R2006a 及以上版本

## 依赖项

```bash
pip install numpy matplotlib scipy tqdm
```

## 相关文件
- `monte_carlo_generator_scenario1.py`: 单场景生成器
- `verify_collision.py`: 碰撞检测验证工具
- `scene_objects.py`: 场景对象类定义
