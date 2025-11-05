% test_environment_new.m
% 测试 environment_new_test.m 函数
% 比较原始 environment.m 和新的场景加载

clear; clc; close all;

%% 测试1: 加载新场景
fprintf('========================================\n');
fprintf('测试1: 加载新生成的场景\n');
fprintf('========================================\n');

% 加载场景
scatterers_new = environment_new_test('scenario_1/mat_files/scene_001.mat');

fprintf('\n新场景散射点矩阵大小: %d × %d\n', size(scatterers_new));

%% 测试2: 与原始环境对比
fprintf('\n========================================\n');
fprintf('测试2: 与原始环境对比\n');
fprintf('========================================\n');

% 加载原始环境
scatterers_old = environment();

fprintf('原始环境散射点数量: %d\n', size(scatterers_old, 1));
fprintf('新场景散射点数量: %d\n', size(scatterers_new, 1));

%% 测试3: 可视化对比
fprintf('\n========================================\n');
fprintf('测试3: 可视化场景\n');
fprintf('========================================\n');

% 创建图形窗口
figure('Position', [100, 100, 1400, 600]);

% 子图1: 原始环境
subplot(1, 2, 1);
scatter3(scatterers_old(:,1), scatterers_old(:,2), scatterers_old(:,3), ...
         30, scatterers_old(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');
title('Original Environment (environment.m)');
colorbar;
colormap(gca, 'jet');
grid on;
axis equal;
view(3);

% 子图2: 新场景
subplot(1, 2, 2);
scatter3(scatterers_new(:,1), scatterers_new(:,2), scatterers_new(:,3), ...
         30, scatterers_new(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');
title('New Scene (scenario\_1/mat\_files/scene\_001.mat)');
colorbar;
colormap(gca, 'jet');
grid on;
axis equal;
view(3);

%% 测试4: 俯视图对比
figure('Position', [100, 100, 1400, 600]);

% 子图1: 原始环境俯视图
subplot(1, 2, 1);
scatter(scatterers_old(:,1), scatterers_old(:,2), ...
        50, scatterers_old(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
title('Original Environment (Top View)');
colorbar;
colormap(gca, 'jet');
grid on;
axis equal;

% 子图2: 新场景俯视图
subplot(1, 2, 2);
scatter(scatterers_new(:,1), scatterers_new(:,2), ...
        50, scatterers_new(:,4), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
title('New Scene (Top View)');
colorbar;
colormap(gca, 'jet');
grid on;
axis equal;

%% 测试5: 速度分布分析
fprintf('\n========================================\n');
fprintf('测试5: 速度分布分析\n');
fprintf('========================================\n');

figure('Position', [100, 100, 1400, 600]);

% 原始环境速度分布
subplot(1, 2, 1);
histogram(scatterers_old(:,4), 20);
xlabel('Velocity (m/s)');
ylabel('Count');
title('Original Environment - Velocity Distribution');
grid on;

% 新场景速度分布
subplot(1, 2, 2);
histogram(scatterers_new(:,4), 20);
xlabel('Velocity (m/s)');
ylabel('Count');
title('New Scene - Velocity Distribution');
grid on;

fprintf('原始环境速度统计:\n');
fprintf('  - 最小值: %.2f m/s\n', min(scatterers_old(:,4)));
fprintf('  - 最大值: %.2f m/s\n', max(scatterers_old(:,4)));
fprintf('  - 平均值: %.2f m/s\n', mean(scatterers_old(:,4)));
fprintf('  - 标准差: %.2f m/s\n', std(scatterers_old(:,4)));

fprintf('\n新场景速度统计:\n');
fprintf('  - 最小值: %.2f m/s\n', min(scatterers_new(:,4)));
fprintf('  - 最大值: %.2f m/s\n', max(scatterers_new(:,4)));
fprintf('  - 平均值: %.2f m/s\n', mean(scatterers_new(:,4)));
fprintf('  - 标准差: %.2f m/s\n', std(scatterers_new(:,4)));

%% 测试6: 数据结构验证
fprintf('\n========================================\n');
fprintf('测试6: 数据结构验证\n');
fprintf('========================================\n');

fprintf('原始环境矩阵大小: [%d × %d]\n', size(scatterers_old));
fprintf('新场景矩阵大小: [%d × %d]\n', size(scatterers_new));

% 检查是否有 NaN 或 Inf
fprintf('\n数据完整性检查:\n');
fprintf('原始环境 - NaN数量: %d, Inf数量: %d\n', ...
        sum(isnan(scatterers_old(:))), sum(isinf(scatterers_old(:))));
fprintf('新场景 - NaN数量: %d, Inf数量: %d\n', ...
        sum(isnan(scatterers_new(:))), sum(isinf(scatterers_new(:))));

% 检查坐标范围
fprintf('\n坐标范围:\n');
fprintf('原始环境:\n');
fprintf('  X: [%.2f, %.2f] m\n', min(scatterers_old(:,1)), max(scatterers_old(:,1)));
fprintf('  Y: [%.2f, %.2f] m\n', min(scatterers_old(:,2)), max(scatterers_old(:,2)));
fprintf('  Z: [%.2f, %.2f] m\n', min(scatterers_old(:,3)), max(scatterers_old(:,3)));

fprintf('\n新场景:\n');
fprintf('  X: [%.2f, %.2f] m\n', min(scatterers_new(:,1)), max(scatterers_new(:,1)));
fprintf('  Y: [%.2f, %.2f] m\n', min(scatterers_new(:,2)), max(scatterers_new(:,2)));
fprintf('  Z: [%.2f, %.2f] m\n', min(scatterers_new(:,3)), max(scatterers_new(:,3)));

fprintf('\n========================================\n');
fprintf('所有测试完成！\n');
fprintf('========================================\n');
