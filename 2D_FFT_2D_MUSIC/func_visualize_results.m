function func_visualize_results(pos_all, pos_all_true)
% 功能：可视化目标估计位置与真实位置对比
% 输入：
%   pos_all - 估计的目标位置 [N×4]: (x, y, z, velocity)
%   pos_all_true - 真实目标位置 [N×4]: (x, y, z, velocity)（可选）

    % 绘制估计结果
    figure;
    x = pos_all(:,1);
    y = pos_all(:,2);
    z = pos_all(:,3);
    c = pos_all(:,4);
    
    scatter3(x, y, z, 50, c, '.');
    axis([0 30 0 20 0 20]);
    xlabel('X/m');
    ylabel('Y/m');
    zlabel('Z/m');
    grid on;
    h = colorbar;
    set(get(h,'label'), 'string', '运动速度');
    title('估计的目标位置');
    
    % 如果提供了真实位置，绘制对比图
    if nargin > 1 && ~isempty(pos_all_true)
        figure;
        x_true = pos_all_true(:,1);
        y_true = pos_all_true(:,2);
        z_true = pos_all_true(:,3);
        c_true = pos_all_true(:,4);
        
        scatter3(x_true, y_true, z_true, 50, c_true, '.');
        axis([0 30 0 20 0 20]);
        xlabel('X/m');
        ylabel('Y/m');
        zlabel('Z/m');
        grid on;
        h = colorbar;
        set(get(h,'label'), 'string', '运动速度');
        title('真实的目标位置');
    end
end
