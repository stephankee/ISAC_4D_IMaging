"""
碰撞检测验证脚本
在生成的场景图上绘制碰撞圆，用于直观验证是否有重叠
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Circle
from monte_carlo_generator_scenario1 import MonteCarloSceneGenerator, visualize_scene


def visualize_with_collision_circles(scene_data, save_path=None):
    """
    可视化场景并绘制碰撞检测圆
    
    参数：
    - scene_data: 场景数据
    - save_path: 保存路径（可选）
    """
    scatterers = scene_data['scatterers']
    
    fig, ax = plt.subplots(figsize=(16, 11))
    
    # 绘制散射点（半透明，作为背景）
    if scatterers['vehicles'].shape[0] > 0:
        vehicle_data = scatterers['vehicles']
        ax.scatter(vehicle_data[:, 0], vehicle_data[:, 1],
                   c=vehicle_data[:, 3], s=40, marker='.', 
                   cmap='RdYlGn', vmin=0, vmax=20, alpha=0.3)
    
    barrier_data = scatterers['barrier']
    ax.scatter(barrier_data[:, 0], barrier_data[:, 1],
               c='darkgreen', s=30, marker='.', alpha=0.3)
    
    light_data = scatterers['lights']
    ax.scatter(light_data[:, 0], light_data[:, 1],
               c='gold', s=100, marker='^', alpha=0.3)
    
    if scatterers['pedestrians'].shape[0] > 0:
        pedestrian_data = scatterers['pedestrians']
        ax.scatter(pedestrian_data[:, 0], pedestrian_data[:, 1],
                   c=pedestrian_data[:, 3], s=40, marker='o',
                   cmap='Blues', vmin=0, vmax=3, alpha=0.3)
    
    # === 绘制碰撞圆 ===
    from monte_carlo_generator_scenario1 import SceneConfig
    config = SceneConfig()
    
    # 1. 车辆碰撞圆（红色）
    vehicles = scene_data['objects']['vehicles']
    for i, vehicle in enumerate(vehicles):
        # 使用实际散射点的中心
        scatterers = vehicle.get_scatterers()
        actual_center = scatterers[:, :2].mean(axis=0)
        circle = Circle(actual_center, config.VEHICLE_RADIUS, 
                       color='red', fill=False, linewidth=2, 
                       linestyle='--', alpha=0.7, label='Vehicle' if i == 0 else '')
        ax.add_patch(circle)
        ax.plot(actual_center[0], actual_center[1], 'rx', markersize=10, markeredgewidth=2)
        ax.text(actual_center[0], actual_center[1] + config.VEHICLE_RADIUS + 0.5, 
               f'V{i+1}\nR={config.VEHICLE_RADIUS}m', 
               ha='center', fontsize=9, color='red', weight='bold')
    
    # 2. 行人碰撞圆（蓝色）
    pedestrians = scene_data['objects']['pedestrians']
    for i, pedestrian in enumerate(pedestrians):
        # 使用实际散射点的中心
        scatterers = pedestrian.get_scatterers()
        actual_center = scatterers[:, :2].mean(axis=0)
        circle = Circle(actual_center, config.PEDESTRIAN_RADIUS, 
                       color='blue', fill=False, linewidth=1.5, 
                       linestyle='--', alpha=0.6, label='Pedestrian' if i == 0 else '')
        ax.add_patch(circle)
        ax.plot(actual_center[0], actual_center[1], 'b+', markersize=8, markeredgewidth=1.5)
    
    # 3. 隔离带碰撞圆（绿色）- 绘制所有20个碰撞圆
    barrier_x = 14.0
    SPACE_Y_MIN = 0
    SPACE_Y_MAX = 28
    num_segments = 20
    for i in range(num_segments):
        y_pos = SPACE_Y_MIN + (i + 0.5) * SPACE_Y_MAX / num_segments
        circle = Circle((barrier_x, y_pos), config.BARRIER_RADIUS, 
                       color='green', fill=False, linewidth=1, 
                       linestyle=':', alpha=0.5, label='Barrier' if i == 0 else '')
        ax.add_patch(circle)
        # 标记圆心
        if i % 5 == 0:  # 每5个标记一个圆心
            ax.plot(barrier_x, y_pos, 'g.', markersize=4)
    
    # 4. 路灯碰撞圆（橙色）
    lights = scene_data['objects']['lights']
    for i, light in enumerate(lights):
        center = light.requested_position[:2]
        circle = Circle(center, config.LIGHT_RADIUS, 
                       color='orange', fill=False, linewidth=1.5, 
                       linestyle='-.', alpha=0.6, label='Light' if i == 0 else '')
        ax.add_patch(circle)
        ax.plot(center[0], center[1], 'o', color='orange', markersize=8)
    
    # 设置坐标轴 - 统一为28m×28m
    ax.set_xlim(-1, 29)
    ax.set_ylim(-1, 29)
    ax.set_xlabel('X (m)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Y (m)', fontsize=12, fontweight='bold')
    ax.set_title('Collision Detection Verification (Top View)', fontsize=14, fontweight='bold')
    ax.set_aspect('equal', adjustable='box')
    
    # 网格
    from matplotlib.ticker import MultipleLocator
    ax.xaxis.set_major_locator(MultipleLocator(5))
    ax.yaxis.set_major_locator(MultipleLocator(5))
    ax.grid(True, alpha=0.3, linestyle='--')
    
    # 图例
    ax.legend(loc='upper left', fontsize=10)
    
    # 添加说明文本
    info_text = f"""Collision Radii:
Vehicle: {config.VEHICLE_RADIUS}m
Pedestrian: {config.PEDESTRIAN_RADIUS}m
Barrier: {config.BARRIER_RADIUS}m
Light: {config.LIGHT_RADIUS}m
Safety Buffer: {config.SAFETY_BUFFER}m"""
    ax.text(0.02, 0.98, info_text, transform=ax.transAxes,
            fontsize=9, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))
    
    plt.tight_layout()
    
    if save_path:
        import os
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"✓ 碰撞验证图已保存: {save_path}")
    
    return fig, ax


def verify_no_collision(scene_data):
    """
    程序化验证是否有碰撞
    
    返回：
    - bool: True=无碰撞, False=有碰撞
    """
    from monte_carlo_generator_scenario1 import SceneConfig
    config = SceneConfig()
    
    vehicles = scene_data['objects']['vehicles']
    pedestrians = scene_data['objects']['pedestrians']
    lights = scene_data['objects']['lights']
    
    # 收集所有物体的中心和半径
    objects = []
    
    # 车辆
    for i, v in enumerate(vehicles):
        scatterers = v.get_scatterers()
        actual_center = scatterers[:, :2].mean(axis=0)
        objects.append({
            'type': 'vehicle',
            'id': i,
            'center': actual_center,
            'radius': config.VEHICLE_RADIUS
        })
    
    # 行人
    for i, p in enumerate(pedestrians):
        scatterers = p.get_scatterers()
        actual_center = scatterers[:, :2].mean(axis=0)
        objects.append({
            'type': 'pedestrian',
            'id': i,
            'center': actual_center,
            'radius': config.PEDESTRIAN_RADIUS
        })
    
    # 路灯
    for i, l in enumerate(lights):
        objects.append({
            'type': 'light',
            'id': i,
            'center': l.requested_position[:2],
            'radius': config.LIGHT_RADIUS
        })
    
    # 检查每对物体
    has_collision = False
    for i in range(len(objects)):
        for j in range(i+1, len(objects)):
            obj1, obj2 = objects[i], objects[j]
            distance = np.sqrt(
                (obj1['center'][0] - obj2['center'][0])**2 +
                (obj1['center'][1] - obj2['center'][1])**2
            )
            min_distance = obj1['radius'] + obj2['radius'] + config.SAFETY_BUFFER
            
            if distance < min_distance:
                print(f"⚠ 碰撞检测到!")
                print(f"  {obj1['type']} {obj1['id']} @ {obj1['center']}")
                print(f"  {obj2['type']} {obj2['id']} @ {obj2['center']}")
                print(f"  距离: {distance:.2f}m < 最小距离: {min_distance:.2f}m")
                print(f"  重叠: {min_distance - distance:.2f}m")
                has_collision = True
    
    if not has_collision:
        print("✓ 验证通过：所有物体之间无碰撞")
    
    return not has_collision


def main():
    """主函数"""
    print("=" * 60)
    print("碰撞检测验证")
    print("=" * 60)
    
    # 生成场景
    generator = MonteCarloSceneGenerator(seed=123)
    scene_data = generator.generate_scene()
    
    # 验证碰撞
    print("\n" + "=" * 60)
    print("程序化验证")
    print("=" * 60)
    is_valid = verify_no_collision(scene_data)
    
    # 可视化验证
    print("\n" + "=" * 60)
    print("可视化验证")
    print("=" * 60)
    fig, ax = visualize_with_collision_circles(
        scene_data, 
        save_path='image/collision_verification.png'
    )
    
    plt.show()
    
    return is_valid


if __name__ == '__main__':
    is_valid = main()
