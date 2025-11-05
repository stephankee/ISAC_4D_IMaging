% example_use_new_scene.m
% 演示如何在 ISAC 成像代码中使用新的场景数据
% 这是一个简单示例，展示如何替换原来的 environment() 调用

clear; clc; close all;

%% 方法1: 使用默认场景
fprintf('=== 方法1: 使用默认场景 ===\n');
scatterers = environment_new_test();
fprintf('加载了 %d 个散射点\n\n', size(scatterers, 1));

%% 方法2: 指定特定场景
fprintf('=== 方法2: 指定特定场景 ===\n');
scatterers = environment_new_test('scenario_1/mat_files/scene_002.mat');
fprintf('加载了 %d 个散射点\n\n', size(scatterers, 1));

%% 方法3: 在原始代码中替换
fprintf('=== 方法3: 在原始 ISAC 成像代码中使用 ===\n');
fprintf('只需将以下代码:\n');
fprintf('    scatterers = environment();\n');
fprintf('替换为:\n');
fprintf('    scatterers = environment_new_test(''scenario_1/mat_files/scene_001.mat'');\n\n');

%% 方法4: 批量处理多个场景
fprintf('=== 方法4: 批量处理多个场景 ===\n');

% 获取所有场景文件
scene_files = dir('scenario_1/mat_files/scene_*.mat');
fprintf('发现 %d 个场景文件\n\n', length(scene_files));

% 处理前3个场景作为示例
for i = 1:min(3, length(scene_files))
    scene_path = fullfile(scene_files(i).folder, scene_files(i).name);
    fprintf('处理场景 %d: %s\n', i, scene_files(i).name);
    
    scatterers = environment_new_test(scene_path);
    
    % 这里可以调用 ISAC 成像算法
    % 例如：
    % result = your_imaging_function(scatterers);
    
    fprintf('  散射点数: %d\n', size(scatterers, 1));
    fprintf('  速度范围: [%.2f, %.2f] m/s\n\n', ...
            min(scatterers(:,4)), max(scatterers(:,4)));
end

%% 可视化示例
fprintf('=== 可视化场景 ===\n');
scatterers = environment_new_test('scenario_1/mat_files/scene_001.mat');

figure('Position', [100, 100, 1200, 500]);

% 3D 视图
subplot(1, 2, 1);
scatter3(scatterers(:,1), scatterers(:,2), scatterers(:,3), ...
         30, scatterers(:,4), 'filled');
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
zlabel('Z (m)', 'FontSize', 12);
title('3D View of Scene', 'FontSize', 14);
colorbar;
colormap('jet');
grid on;
view(45, 30);

% 俯视图
subplot(1, 2, 2);
scatter(scatterers(:,1), scatterers(:,2), ...
        50, scatterers(:,4), 'filled', 'MarkerEdgeColor', 'k');
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
title('Top View of Scene', 'FontSize', 14);
colorbar;
colormap('jet');
grid on;
axis equal;

fprintf('\n可视化完成！\n');

%% 数据格式说明
fprintf('\n=== 数据格式说明 ===\n');
fprintf('environment_new_test() 返回的矩阵格式: [N × 4]\n');
fprintf('  第1列: X 坐标 (m)\n');
fprintf('  第2列: Y 坐标 (m)\n');
fprintf('  第3列: Z 坐标 (m)\n');
fprintf('  第4列: 速度 (m/s)\n');
fprintf('\n这与原始 environment() 函数的返回格式完全一致！\n');
fprintf('因此可以直接替换使用，无需修改后续的成像算法代码。\n');
