"""
本代码构建一个28×20×20区域的散射点空间
Python版本，复刻environment_disp.m的功能
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

print("2D_FFT_2D_MUSIC/environment_disp.py")
def create_car_model():
    """创建车辆的散射点模型"""
    tar_car = np.array([
        [2, 0, 0], [2, 0, 0.9], [2, 0.6, 0.9], [2, 1, 1.4], [2, 4.5, 1.4], [2, 5, 0.9], [2, 6, 0],
        [0, 0, 0], [0, 0, 0.9], [0, 0.6, 0.9], [0, 1, 1.4], [0, 4.5, 1.4], [0, 5, 0.9], [0, 6, 0],
        [2, 0, 0.5], [2, 1.5, 1.7], [2, 2, 1.8], [2, 2.5, 1.8], [2, 3, 1.8], [2, 3.5, 1.8], [2, 4, 1.7], [2, 5.5, 0.8], [2, 6, 0.5],
        [0, 0, 0.5], [0, 1.5, 1.7], [0, 2, 1.8], [0, 2.5, 1.8], [0, 3, 1.8], [0, 3.5, 1.8], [0, 4, 1.7], [0, 5.5, 0.8], [0, 6, 0.5],
        # 细节填充
        [2, 3, 1.4], [2, 3, 0.6], [2, 3, 0.3], [2, 3, 0], [2, 1, 0.9], [2, 1.4, 0.9], [2, 1.8, 0.9], [2, 2.2, 0.9], [2, 2.6, 0.9], [2, 3, 0.9], [2, 3.4, 0.9], [2, 3.8, 0.9], [2, 4.2, 0.9], [2, 4.6, 0.9], [2, 1, 0.5], [2, 5, 0.4], [2, 0.6, 0.4], [2, 0.4, 0], [2, 1.4, 0.4], [2, 1.6, 0], [2, 5.4, 0.3], [2, 5.6, 0], [2, 4.6, 0.3], [2, 4.4, 0], [2, 2.1, 0], [2, 2.6, 0], [2, 3.5, 0], [2, 4, 0],
        [0, 3, 1.4], [0, 3, 0.6], [0, 3, 0.3], [0, 3, 0], [0, 1, 0.9], [0, 1.4, 0.9], [0, 1.8, 0.9], [0, 2.2, 0.9], [0, 2.6, 0.9], [0, 3, 0.9], [0, 3.4, 0.9], [0, 3.8, 0.9], [0, 4.2, 0.9], [0, 4.6, 0.9], [0, 1, 0.5], [0, 5, 0.4], [0, 0.6, 0.4], [0, 0.4, 0], [0, 1.4, 0.4], [0, 1.6, 0], [0, 5.4, 0.3], [0, 5.6, 0], [0, 4.6, 0.3], [0, 4.4, 0], [0, 2.1, 0], [0, 2.6, 0], [0, 3.5, 0], [0, 4, 0],
        [1, 0, 0], [1, 0, 0.9], [1, 0.6, 0.9], [1, 5, 0.9], [1, 6, 0], [1, 4, 1.7], [1, 1.5, 1.7], [1.5, 3.2, 1.8], [0.5, 3.2, 1.8], [1.5, 2.5, 1.8], [0.5, 2.5, 1.8], [1, 6, 0.5],
        # 车轮
        [2, 1, -0.4], [2, 0.7, -0.3], [2, 1.3, -0.3], [2, 5, -0.4], [2, 4.7, -0.3], [2, 5.3, -0.3],
        [0, 1, -0.4], [0, 0.7, -0.3], [0, 1.3, -0.3], [0, 5, -0.4], [0, 4.7, -0.3], [0, 5.3, -0.3],
        # 后视镜
        [2.2, 4.6, 0.9], [-0.2, 4.6, 0.9]
    ])
    
    # 高度和横向偏移调整
    tar_car[:, 2] += 0.4
    tar_car[:, 0] += 0.2
    
    return tar_car


def create_car_groups():
    """创建两组车辆（不同位置和速度）"""
    tar_car = create_car_model()
    
    # 车辆组1：位置[8, 12]，速度+10 m/s
    pos_car_1 = np.array([[8, 12]])
    car_group_1 = []
    for pos in pos_car_1:
        car_mid = tar_car.copy()
        car_mid[:, 0] += pos[0]
        car_mid[:, 1] += pos[1]
        car_group_1.append(car_mid)
    car_group_1 = np.vstack(car_group_1)
    v_car_1 = np.ones((car_group_1.shape[0], 1)) * 10
    car_group_1 = np.hstack([car_group_1, v_car_1])
    
    # 车辆组2：位置[18, 2]，速度-10 m/s
    pos_car_2 = np.array([[18, 2]])
    car_group_2 = []
    for pos in pos_car_2:
        car_mid = tar_car.copy()
        car_mid[:, 0] += pos[0]
        car_mid[:, 1] += pos[1]
        car_group_2.append(car_mid)
    car_group_2 = np.vstack(car_group_2)
    v_car_2 = np.ones((car_group_2.shape[0], 1)) * (-10)
    car_group_2 = np.hstack([car_group_2, v_car_2])
    
    # 合并
    car_group = np.vstack([car_group_1, car_group_2])
    return car_group


def create_plant_group():
    """创建隔离带散射点"""
    y_coords = np.arange(0, 20.5, 0.5).reshape(-1, 1)
    
    plant_1 = np.hstack([np.zeros_like(y_coords) + 2, y_coords, np.zeros_like(y_coords)])
    plant_2 = np.hstack([np.zeros_like(y_coords) + 1, y_coords, np.zeros_like(y_coords)])
    plant_3 = np.hstack([np.zeros_like(y_coords) + 1, y_coords, np.ones_like(y_coords)])
    plant_4 = np.hstack([np.zeros_like(y_coords) + 2, y_coords, np.ones_like(y_coords)])
    
    plant_group1 = np.vstack([plant_1, plant_2, plant_3, plant_4])
    plant_group1[:, 0] += 13  # 整体横向偏移
    
    # 添加速度信息（静止）
    v_plant = np.zeros((plant_group1.shape[0], 1))
    plant_group = np.hstack([plant_group1, v_plant])
    
    return plant_group


def create_light_group():
    """创建路灯散射点"""
    light_1 = np.array([
        [22, 3, 2], [22, 3, 3], [22, 3, 4], [22, 3, 5], [22, 3, 6],
        [22, 3, 7], [22, 3, 8], [22, 3, 9], [22, 3, 10],
        [21, 3, 10], [23, 3, 10], [22, 2, 10], [22, 4, 10]
    ])
    light_1[:, 0] -= 7  # 横向调整
    
    light_3 = light_1.copy()
    light_3[:, 0] -= 1
    light_3[:, 1] += 15
    
    # 添加速度信息（静止）
    v_light_1 = np.zeros((light_1.shape[0], 1))
    v_light_3 = np.zeros((light_3.shape[0], 1))
    
    light_1 = np.hstack([light_1, v_light_1])
    light_3 = np.hstack([light_3, v_light_3])
    
    light_group = np.vstack([light_1, light_3])
    return light_group


def create_people_group():
    """创建行人散射点"""
    people_template = np.array([
        [0, 0, 0], [0.5, 0.5, 0], [0.25, 0.3, 1], [0.25, 0.3, 1.5],
        [0.25, 0.3, 1.7], [0.4, 0.4, 0.5], [0.1, 0.2, 0.5], [0.25, 0.3, 1.8],
        [0.5, 0.3, 1.4], [0, 0.3, 1.4], [0.5, 0.5, 1], [0, 0, 0.9]
    ])
    
    # 行人组1：位置[[1,2], [2,13]]，速度+2 m/s
    pos_p_1 = np.array([[1, 2], [2, 13]])
    people_group_1 = []
    for pos in pos_p_1:
        people_mid = people_template.copy()
        people_mid[:, 0] += pos[0]
        people_mid[:, 1] += pos[1]
        people_group_1.append(people_mid)
    people_group_1 = np.vstack(people_group_1)
    v_people_1 = np.ones((people_group_1.shape[0], 1)) * 2
    people_group_1 = np.hstack([people_group_1, v_people_1])
    
    # 行人组2：位置[[27,7], [27,18]]，速度-2 m/s
    pos_p_2 = np.array([[27, 7], [27, 18]])
    people_group_2 = []
    for pos in pos_p_2:
        people_mid = people_template.copy()
        people_mid[:, 0] += pos[0]
        people_mid[:, 1] += pos[1]
        people_group_2.append(people_mid)
    people_group_2 = np.vstack(people_group_2)
    v_people_2 = np.ones((people_group_2.shape[0], 1)) * (-2)
    people_group_2 = np.hstack([people_group_2, v_people_2])
    
    people_group = np.vstack([people_group_1, people_group_2])
    return people_group


def visualize_environment(car_group, plant_group, light_group, people_group):
    """可视化整个交通场景"""
    fig = plt.figure(figsize=(12, 9))
    ax = fig.add_subplot(111, projection='3d')
    
    # 绘制车辆（颜色映射速度）
    scatter_car = ax.scatter(
        car_group[:, 0], car_group[:, 1], car_group[:, 2],
        c=car_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10
    )
    
    # 绘制隔离带
    ax.scatter(
        plant_group[:, 0], plant_group[:, 1], plant_group[:, 2],
        c=plant_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10
    )
    
    # 绘制路灯
    ax.scatter(
        light_group[:, 0], light_group[:, 1], light_group[:, 2],
        c=light_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10
    )
    
    # 绘制行人
    ax.scatter(
        people_group[:, 0], people_group[:, 1], people_group[:, 2],
        c=people_group[:, 3], s=100, marker='.', cmap='viridis', vmin=-10, vmax=10
    )
    
    # 设置坐标轴
    ax.set_xlim(0, 28)
    ax.set_ylim(0, 20)
    ax.set_zlim(0, 20)
    ax.set_xlabel('X (m)')
    ax.set_ylabel('Y (m)')
    ax.set_zlabel('Z (m)')
    
    # 设置三个轴的比例一致（1m在三个轴上显示长度相同）
    ax.set_box_aspect([28, 20, 20])  # 与实际空间尺寸比例一致
    
    # 设置网格间隔为1m
    from matplotlib.ticker import MultipleLocator
    ax.xaxis.set_major_locator(MultipleLocator(5))  # X轴主刻度每5m
    ax.yaxis.set_major_locator(MultipleLocator(2))  # Y轴主刻度每2m
    ax.zaxis.set_major_locator(MultipleLocator(2))  # Z轴主刻度每2m
    ax.xaxis.set_minor_locator(MultipleLocator(1))  # X轴次刻度每1m
    ax.yaxis.set_minor_locator(MultipleLocator(1))  # Y轴次刻度每1m
    ax.zaxis.set_minor_locator(MultipleLocator(1))  # Z轴次刻度每1m
    ax.grid(True, which='major', alpha=0.4, linestyle='-', linewidth=0.8)
    ax.grid(True, which='minor', alpha=0.2, linestyle=':', linewidth=0.5)
    
    # 添加颜色条
    cbar = plt.colorbar(scatter_car, ax=ax, pad=0.1)
    cbar.set_label('Velocity (m/s)', rotation=270, labelpad=20)
    
    # 设置视角
    ax.view_init(elev=10, azim=30)
    
    plt.tight_layout()
    return fig, ax


def main():
    """主函数：生成并可视化场景"""
    # 创建各类散射点
    car_group = create_car_groups()
    plant_group = create_plant_group()
    light_group = create_light_group()
    people_group = create_people_group()
    
    # 打印统计信息
    print(f"车辆散射点数: {car_group.shape[0]}")
    print(f"隔离带散射点数: {plant_group.shape[0]}")
    print(f"路灯散射点数: {light_group.shape[0]}")
    print(f"行人散射点数: {people_group.shape[0]}")
    print(f"总散射点数: {car_group.shape[0] + plant_group.shape[0] + light_group.shape[0] + people_group.shape[0]}")
    
    # 可视化
    fig, ax = visualize_environment(car_group, plant_group, light_group, people_group)
    plt.savefig('2D_FFT_2D_MUSIC/image/environment_python.png', dpi=150, bbox_inches='tight')
    plt.show()
    
    # 返回所有散射点数据（用于后续处理）
    return {
        'car': car_group,
        'plant': plant_group,
        'light': light_group,
        'people': people_group,
        'all': np.vstack([car_group, plant_group, light_group, people_group])
    }


if __name__ == '__main__':
    scene_data = main()