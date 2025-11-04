"""
弯道场景仿真 V2：使用 scene_objects 模块
展示如何使用封装好的类来创建场景

特性：
1. 导入 scene_objects 模块中的类
2. 更简洁的代码结构
3. 与 environment_new_v1.py 生成相同的场景
4. 便于扩展和维护
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.ticker import MultipleLocator

# 导入场景对象类
from scene_objects import Vehicle, StraightBarrier, CurveBarrier, StreetLight, Pedestrian


def create_scene():
    """
    创建弯道场景（与 environment_new_v1.py 相同的场景）
    
    返回：
    - dict: 包含各类对象散射点数据的字典
    """
    print("正在创建场景对象...")
    
    # 创建车辆（2辆）
    vehicles = [
        Vehicle(center=(8, 12, 0), direction=0, velocity=10),
        Vehicle(center=(18, 2, 0), direction=0, velocity=-10),
    ]
    
    # 创建直线隔离带
    straight_barriers = [
        StraightBarrier(start=(13, 0, 0), direction=0, length=20, spacing=0.5),
    ]
    
    # 创建圆弧隔离带（弯道）
    curve_barriers = [
        CurveBarrier(center=(35, 0, 0), radius=15, start_angle=0, sweep_angle=90, angle_step=2.86),
    ]
    
    # 创建路灯（2个）
    lights = [
        StreetLight(position=(15, 3, 0)),
        StreetLight(position=(14, 18, 0)),
    ]
    
    # 创建行人（4个）
    pedestrians = [
        Pedestrian(center=(1, 2, 0), direction=0, velocity=2),
        Pedestrian(center=(2, 13, 0), direction=0, velocity=2),
        Pedestrian(center=(27, 7, 0), direction=180, velocity=-2),
        Pedestrian(center=(27, 18, 0), direction=180, velocity=-2),
    ]
    
    # 获取所有散射点数据
    car_group = np.vstack([v.get_scatterers() for v in vehicles])
    plant_straight = np.vstack([b.get_scatterers() for b in straight_barriers])
    plant_curve = np.vstack([c.get_scatterers() for c in curve_barriers])
    light_group = np.vstack([l.get_scatterers() for l in lights])
    people_group = np.vstack([p.get_scatterers() for p in pedestrians])
    
    print(f"✓ 场景创建完成")
    
    return {
        'car': car_group,
        'plant_straight': plant_straight,
        'plant_curve': plant_curve,
        'light': light_group,
        'people': people_group,
        'all': np.vstack([car_group, plant_straight, plant_curve, light_group, people_group])
    }


def visualize_environment(car_group, plant_straight, plant_curve, light_group, people_group):
    """可视化整个交通场景（包含直线和圆弧隔离带）"""
    fig = plt.figure(figsize=(16, 9))
    ax = fig.add_subplot(111, projection='3d')
    
    # 绘制车辆（颜色映射速度）
    scatter_car = ax.scatter(
        car_group[:, 0], car_group[:, 1], car_group[:, 2],
        c=car_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10,
        label='Vehicle'
    )
    
    # 绘制直线隔离带
    ax.scatter(
        plant_straight[:, 0], plant_straight[:, 1], plant_straight[:, 2],
        c=plant_straight[:, 3], s=80, marker='.', cmap='viridis', vmin=-10, vmax=10,
        alpha=0.6, label='Straight Barrier'
    )
    
    # 绘制圆弧隔离带（弯道）
    ax.scatter(
        plant_curve[:, 0], plant_curve[:, 1], plant_curve[:, 2],
        c=plant_curve[:, 3], s=80, marker='.', cmap='viridis', vmin=-10, vmax=10,
        alpha=0.8, label='Curve Barrier'
    )
    
    # 绘制路灯
    ax.scatter(
        light_group[:, 0], light_group[:, 1], light_group[:, 2],
        c=light_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10,
        label='Street Light'
    )
    
    # 绘制行人
    ax.scatter(
        people_group[:, 0], people_group[:, 1], people_group[:, 2],
        c=people_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10,
        label='Pedestrian'
    )
    
    # 设置坐标轴（X轴扩展到50m）
    ax.set_xlim(0, 50)
    ax.set_ylim(0, 20)
    ax.set_zlim(0, 20)
    ax.set_xlabel('X (m)', fontsize=12)
    ax.set_ylabel('Y (m)', fontsize=12)
    ax.set_zlabel('Z (m)', fontsize=12)
    ax.set_title('Curved Road Scenario V2 (50m × 20m × 20m)', fontsize=14, fontweight='bold')
    
    # 设置三个轴的比例一致（1m在三个轴上显示长度相同）
    ax.set_box_aspect([50, 20, 20])  # 与实际空间尺寸比例一致
    
    # 设置网格间隔为1m
    ax.xaxis.set_major_locator(MultipleLocator(5))  # X轴主刻度每5m
    ax.yaxis.set_major_locator(MultipleLocator(2))  # Y轴主刻度每2m
    ax.zaxis.set_major_locator(MultipleLocator(2))  # Z轴主刻度每2m
    ax.xaxis.set_minor_locator(MultipleLocator(1))  # X轴次刻度每1m
    ax.yaxis.set_minor_locator(MultipleLocator(1))  # Y轴次刻度每1m
    ax.zaxis.set_minor_locator(MultipleLocator(1))  # Z轴次刻度每1m
    ax.grid(True, which='major', alpha=0.4, linestyle='-', linewidth=0.8)
    ax.grid(True, which='minor', alpha=0.2, linestyle=':', linewidth=0.5)
    
    # 添加颜色条
    cbar = plt.colorbar(scatter_car, ax=ax, pad=0.1, shrink=0.8)
    cbar.set_label('Velocity (m/s)', rotation=270, labelpad=20, fontsize=11)
    
    # 添加图例
    ax.legend(loc='upper left', fontsize=9)
    
    # 设置视角
    ax.view_init(elev=15, azim=45)
    
    plt.tight_layout()
    return fig, ax


def print_statistics(scene_data):
    """打印场景统计信息"""
    print("\n" + "=" * 60)
    print("场景统计信息")
    print("=" * 60)
    print(f"车辆散射点数: {scene_data['car'].shape[0]}")
    print(f"直线隔离带散射点数: {scene_data['plant_straight'].shape[0]}")
    print(f"圆弧隔离带散射点数: {scene_data['plant_curve'].shape[0]}")
    print(f"路灯散射点数: {scene_data['light'].shape[0]}")
    print(f"行人散射点数: {scene_data['people'].shape[0]}")
    print(f"总散射点数: {scene_data['all'].shape[0]}")
    print("=" * 60)


def main():
    """主函数：生成并可视化弯道场景"""
    print("=" * 60)
    print("弯道场景仿真 - Environment New V2")
    print("使用 scene_objects 模块")
    print("场景尺寸: 50m × 20m × 20m")
    print("=" * 60)
    
    # 创建场景
    scene_data = create_scene()
    
    # 打印统计信息
    print_statistics(scene_data)
    
    # 可视化
    print("\n正在生成可视化...")
    fig, ax = visualize_environment(
        scene_data['car'],
        scene_data['plant_straight'],
        scene_data['plant_curve'],
        scene_data['light'],
        scene_data['people']
    )
    
    # 保存图像
    output_path = '2D_FFT_2D_MUSIC/image/environment_new_v2.png'
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✓ 图像已保存: {output_path}")
    
    plt.show()
    
    return scene_data


def demo_custom_scene():
    """演示：创建自定义场景"""
    print("\n" + "=" * 60)
    print("自定义场景演示")
    print("=" * 60)
    
    # 创建一个更复杂的场景
    vehicles = [
        Vehicle(center=(10, 5, 0), direction=0, velocity=15),
        Vehicle(center=(20, 10, 0), direction=45, velocity=12),
        Vehicle(center=(30, 15, 0), direction=90, velocity=18),
    ]
    
    barriers = [
        StraightBarrier(start=(5, 0, 0), direction=0, length=20),
        CurveBarrier(center=(40, 10, 0), radius=12, start_angle=0, sweep_angle=180),
    ]
    
    lights = [StreetLight(position=(i*10, 3, 0)) for i in range(1, 5)]
    
    pedestrians = [
        Pedestrian(center=(8, i*5, 0), direction=0, velocity=1.5) for i in range(1, 4)
    ]
    
    # 合并所有对象
    all_objects = vehicles + barriers + lights + pedestrians
    scene_data = np.vstack([obj.get_scatterers() for obj in all_objects])
    
    print(f"自定义场景总散射点数: {scene_data.shape[0]}")
    print(f"  - 车辆: {len(vehicles)} 辆")
    print(f"  - 隔离带: {len(barriers)} 段")
    print(f"  - 路灯: {len(lights)} 个")
    print(f"  - 行人: {len(pedestrians)} 人")
    
    return scene_data


if __name__ == '__main__':
    # 运行主场景
    scene_data = main()
    
    # 取消注释下面这行来运行自定义场景演示
    # custom_scene = demo_custom_scene()
