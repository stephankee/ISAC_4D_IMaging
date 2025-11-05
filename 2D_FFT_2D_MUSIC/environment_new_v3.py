"""
使用 scene_objects.py 中的对象类生成与 environment_disp.py 一致的固定场景
- 2辆车：位置 [8, 12] (+10 m/s) 和 [18, 2] (-10 m/s)
- 1段直线隔离带：从 [15, 0] 开始，长度20m
- 2个路灯：位置 [15, 3] 和 [14, 18]
- 4个行人：位置 [1, 2], [2, 13] (+2 m/s) 和 [27, 7], [27, 18] (-2 m/s)
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from scene_objects import Vehicle, StraightBarrier, StreetLight, Pedestrian


def create_fixed_scene():
    """
    创建固定的交通场景
    
    返回：
    - dict: 包含所有对象和散射点数据
    """
    # 1. 创建车辆
    # 车辆1：中心 [8, 12, 0]，沿Y轴正向（0度），速度 +10 m/s
    vehicle_1 = Vehicle(center=(8, 12, 0), direction=0, velocity=10)
    
    # 车辆2：中心 [18, 2, 0]，沿Y轴正向（0度），速度 -10 m/s
    vehicle_2 = Vehicle(center=(18, 2, 0), direction=0, velocity=-10)
    
    # 2. 创建隔离带
    # 直线隔离带：起点 [15, 0, 0]，沿Y轴正向（0度），长度 20m
    barrier = StraightBarrier(start=(15, 0, 0), direction=0, length=20)
    
    # 3. 创建路灯
    # 路灯1：位置 [15, 3, 0]
    light_1 = StreetLight(position=(14.5, 3, 0))
    
    # 路灯2：位置 [14, 18, 0]
    light_2 = StreetLight(position=(15.5, 18, 0))
    
    # 4. 创建行人
    # 行人1：中心 [1, 2, 0]，沿Y轴正向（0度），速度 +2 m/s
    pedestrian_1 = Pedestrian(center=(1, 2, 0), direction=0, velocity=2)
    
    # 行人2：中心 [2, 13, 0]，沿Y轴正向（0度），速度 +2 m/s
    pedestrian_2 = Pedestrian(center=(2, 13, 0), direction=0, velocity=2)
    
    # 行人3：中心 [27, 7, 0]，沿Y轴正向（0度），速度 -2 m/s
    pedestrian_3 = Pedestrian(center=(27, 7, 0), direction=0, velocity=-2)
    
    # 行人4：中心 [27, 18, 0]，沿Y轴正向（0度），速度 -2 m/s
    pedestrian_4 = Pedestrian(center=(27, 18, 0), direction=0, velocity=-2)
    
    # 5. 收集所有散射点
    scatterers = {
        'vehicles': [vehicle_1, vehicle_2],
        'barriers': [barrier],
        'lights': [light_1, light_2],
        'pedestrians': [pedestrian_1, pedestrian_2, pedestrian_3, pedestrian_4]
    }
    
    # 6. 获取所有散射点数组
    vehicle_scatterers = np.vstack([v.get_scatterers() for v in scatterers['vehicles']])
    barrier_scatterers = np.vstack([b.get_scatterers() for b in scatterers['barriers']])
    light_scatterers = np.vstack([l.get_scatterers() for l in scatterers['lights']])
    pedestrian_scatterers = np.vstack([p.get_scatterers() for p in scatterers['pedestrians']])
    
    all_scatterers = np.vstack([
        vehicle_scatterers,
        barrier_scatterers,
        light_scatterers,
        pedestrian_scatterers
    ])
    
    return {
        'objects': scatterers,
        'scatterers': {
            'vehicles': vehicle_scatterers,
            'barriers': barrier_scatterers,
            'lights': light_scatterers,
            'pedestrians': pedestrian_scatterers,
            'all': all_scatterers
        }
    }


def visualize_scene(scene_data):
    """
    可视化交通场景
    
    参数：
    - scene_data: create_fixed_scene() 返回的场景数据
    """
    scatterers = scene_data['scatterers']
    
    fig = plt.figure(figsize=(12, 9))
    ax = fig.add_subplot(111, projection='3d')
    
    # 绘制车辆（红色系）
    vehicle_data = scatterers['vehicles']
    scatter_vehicle = ax.scatter(
        vehicle_data[:, 0], vehicle_data[:, 1], vehicle_data[:, 2],
        c=vehicle_data[:, 3], s=100, marker='.', cmap='RdYlGn', 
        vmin=-10, vmax=10, label='Vehicles'
    )
    
    # 绘制隔离带（绿色）
    barrier_data = scatterers['barriers']
    ax.scatter(
        barrier_data[:, 0], barrier_data[:, 1], barrier_data[:, 2],
        c='green', s=50, marker='.', alpha=0.6, label='Barrier'
    )
    
    # 绘制路灯（黄色）
    light_data = scatterers['lights']
    ax.scatter(
        light_data[:, 0], light_data[:, 1], light_data[:, 2],
        c='gold', s=80, marker='^', label='Street Lights'
    )
    
    # 绘制行人（蓝色系）
    pedestrian_data = scatterers['pedestrians']
    ax.scatter(
        pedestrian_data[:, 0], pedestrian_data[:, 1], pedestrian_data[:, 2],
        c=pedestrian_data[:, 3], s=80, marker='o', cmap='coolwarm',
        vmin=-2, vmax=2, label='Pedestrians'
    )
    
    # 设置坐标轴
    ax.set_xlim(0, 28)
    ax.set_ylim(0, 20)
    ax.set_zlim(0, 20)
    ax.set_xlabel('X (m)', fontsize=12)
    ax.set_ylabel('Y (m)', fontsize=12)
    ax.set_zlabel('Z (m)', fontsize=12)
    ax.set_title('Traffic Scene (Fixed Layout)', fontsize=14, fontweight='bold')
    
    # 设置三个轴的比例一致
    ax.set_box_aspect([28, 20, 20])
    
    # 设置网格
    from matplotlib.ticker import MultipleLocator
    ax.xaxis.set_major_locator(MultipleLocator(5))
    ax.yaxis.set_major_locator(MultipleLocator(2))
    ax.zaxis.set_major_locator(MultipleLocator(2))
    ax.xaxis.set_minor_locator(MultipleLocator(1))
    ax.yaxis.set_minor_locator(MultipleLocator(1))
    ax.zaxis.set_minor_locator(MultipleLocator(1))
    ax.grid(True, which='major', alpha=0.4, linestyle='-', linewidth=0.8)
    ax.grid(True, which='minor', alpha=0.2, linestyle=':', linewidth=0.5)
    
    # 添加颜色条（车辆速度）
    cbar = plt.colorbar(scatter_vehicle, ax=ax, pad=0.1, shrink=0.6)
    cbar.set_label('Velocity (m/s)', rotation=270, labelpad=20)
    
    # 添加图例
    ax.legend(loc='upper left', fontsize=10)
    
    # 设置视角
    ax.view_init(elev=10, azim=30)
    
    plt.tight_layout()
    return fig, ax


def print_statistics(scene_data):
    """
    打印场景统计信息
    
    参数：
    - scene_data: create_fixed_scene() 返回的场景数据
    """
    scatterers = scene_data['scatterers']
    objects = scene_data['objects']
    
    print("=" * 60)
    print("场景统计信息")
    print("=" * 60)
    print(f"车辆数量: {len(objects['vehicles'])} 辆")
    print(f"  - 散射点数: {scatterers['vehicles'].shape[0]}")
    print(f"隔离带数量: {len(objects['barriers'])} 段")
    print(f"  - 散射点数: {scatterers['barriers'].shape[0]}")
    print(f"路灯数量: {len(objects['lights'])} 个")
    print(f"  - 散射点数: {scatterers['lights'].shape[0]}")
    print(f"行人数量: {len(objects['pedestrians'])} 人")
    print(f"  - 散射点数: {scatterers['pedestrians'].shape[0]}")
    print("-" * 60)
    print(f"总散射点数: {scatterers['all'].shape[0]}")
    print("=" * 60)
    
    # 打印各对象的详细信息
    print("\n车辆详细信息:")
    for i, vehicle in enumerate(objects['vehicles'], 1):
        bbox = vehicle.get_bounding_box()
        print(f"  车辆 {i}: 中心 ({bbox['center'][0]:.1f}, {bbox['center'][1]:.1f}, {bbox['center'][2]:.1f}), "
              f"速度 {vehicle.velocity:.1f} m/s")
    
    print("\n隔离带详细信息:")
    for i, barrier in enumerate(objects['barriers'], 1):
        bbox = barrier.get_bounding_box()
        print(f"  隔离带 {i}: 中心 ({bbox['center'][0]:.1f}, {bbox['center'][1]:.1f}, {bbox['center'][2]:.1f}), "
              f"长度 {barrier.length:.1f} m")
    
    print("\n路灯详细信息:")
    for i, light in enumerate(objects['lights'], 1):
        bbox = light.get_bounding_box()
        print(f"  路灯 {i}: 位置 ({bbox['center'][0]:.1f}, {bbox['center'][1]:.1f}, {bbox['center'][2]:.1f})")
    
    print("\n行人详细信息:")
    for i, pedestrian in enumerate(objects['pedestrians'], 1):
        bbox = pedestrian.get_bounding_box()
        print(f"  行人 {i}: 中心 ({bbox['center'][0]:.1f}, {bbox['center'][1]:.1f}, {bbox['center'][2]:.1f}), "
              f"速度 {pedestrian.velocity:.1f} m/s")


def main():
    """主函数"""
    print("=" * 60)
    print("Environment New V3 - 使用 scene_objects.py 生成固定场景")
    print("=" * 60)
    print()
    
    # 创建场景
    print("正在创建场景...")
    scene_data = create_fixed_scene()
    print("✓ 场景创建完成\n")
    
    # 打印统计信息
    print_statistics(scene_data)
    
    # 可视化
    print("\n正在生成可视化...")
    fig, ax = visualize_scene(scene_data)
    
    # 保存图片
    import os
    os.makedirs('image', exist_ok=True)
    output_path = 'image/environment_new_v3.png'
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✓ 图片已保存: {output_path}")
    
    plt.show()
    
    return scene_data


if __name__ == '__main__':
    scene_data = main()
