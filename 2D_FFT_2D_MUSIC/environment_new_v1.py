"""
弯道场景仿真：50×20×20区域
新增特性：
1. X轴扩展到50m（原28m）
2. 保留原始直线隔离带
3. 新增1/4圆弧形隔离带，模拟弯道
4. 面向对象设计：车辆、隔离带、路灯、行人类，支持自定义位置、方向、速度
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D


# ============================================================
# 场景对象类定义
# ============================================================

class Vehicle:
    """
    车辆类
    默认属性：
    - 中心点：(0, 0, 0)
    - 方向：沿Y轴正向（0°）
    - 速度：10 m/s
    - 尺寸：约 6m(长) × 2m(宽) × 2m(高)
    """
    def __init__(self, center=(0, 0, 0), direction=0, velocity=10):
        """
        参数：
        - center: (x, y, z) 车辆中心点坐标
        - direction: 车辆朝向角度（度），0°为Y轴正向，逆时针为正
        - velocity: 车辆速度 (m/s)，正值为前进方向
        """
        self.center = np.array(center)
        self.direction = np.radians(direction)  # 转为弧度
        self.velocity = velocity
        self.scatterers = self._create_model()
    
    def _create_model(self):
        """创建车辆的散射点模板（相对坐标）"""
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
    
    def get_scatterers(self):
        """返回带位置、方向、速度的散射点数组 [N, 4]"""
        # 旋转变换
        cos_theta = np.cos(self.direction)
        sin_theta = np.sin(self.direction)
        rotation_matrix = np.array([
            [cos_theta, -sin_theta, 0],
            [sin_theta, cos_theta, 0],
            [0, 0, 1]
        ])
        
        # 应用旋转和平移
        rotated = self.scatterers @ rotation_matrix.T
        translated = rotated + self.center
        
        # 添加速度信息
        velocity_column = np.ones((translated.shape[0], 1)) * self.velocity
        return np.hstack([translated, velocity_column])


class StraightBarrier:
    """
    直线隔离带类
    默认属性：
    - 起点：(0, 0, 0)
    - 方向：沿Y轴正向
    - 长度：20m
    - 宽度：1m（4层结构）
    - 速度：0 m/s（静止）
    """
    def __init__(self, start=(0, 0, 0), direction=0, length=20, spacing=0.5):
        """
        参数：
        - start: (x, y, z) 起点坐标
        - direction: 延伸方向角度（度），0°为Y轴正向
        - length: 隔离带长度 (m)
        - spacing: 散射点间隔 (m)
        """
        self.start = np.array(start)
        self.direction = np.radians(direction)
        self.length = length
        self.spacing = spacing
        self.velocity = 0  # 静止
    
    def get_scatterers(self):
        """返回散射点数组 [N, 4]"""
        y_coords = np.arange(0, self.length + self.spacing, self.spacing).reshape(-1, 1)
        
        # 4层结构（相对坐标）
        plant_1 = np.hstack([np.zeros_like(y_coords) + 2, y_coords, np.zeros_like(y_coords)])
        plant_2 = np.hstack([np.zeros_like(y_coords) + 1, y_coords, np.zeros_like(y_coords)])
        plant_3 = np.hstack([np.zeros_like(y_coords) + 1, y_coords, np.ones_like(y_coords)])
        plant_4 = np.hstack([np.zeros_like(y_coords) + 2, y_coords, np.ones_like(y_coords)])
        
        plant_group = np.vstack([plant_1, plant_2, plant_3, plant_4])
        
        # 旋转变换
        cos_theta = np.cos(self.direction)
        sin_theta = np.sin(self.direction)
        rotation_matrix = np.array([
            [cos_theta, -sin_theta, 0],
            [sin_theta, cos_theta, 0],
            [0, 0, 1]
        ])
        
        rotated = plant_group @ rotation_matrix.T
        translated = rotated + self.start
        
        # 添加速度信息
        velocity_column = np.zeros((translated.shape[0], 1))
        return np.hstack([translated, velocity_column])


class CurveBarrier:
    """
    圆弧隔离带类
    默认属性：
    - 圆心：(35, 0, 0)
    - 半径：15m
    - 起始角度：0°（X轴正向）
    - 扫掠角度：90°（逆时针）
    - 速度：0 m/s（静止）
    """
    def __init__(self, center=(35, 0, 0), radius=15, start_angle=0, sweep_angle=90, angle_step=2.86):
        """
        参数：
        - center: (x, y, z) 圆心坐标
        - radius: 圆弧半径 (m)
        - start_angle: 起始角度（度），0°为X轴正向
        - sweep_angle: 扫掠角度（度），正值为逆时针
        - angle_step: 角度采样步长（度）
        """
        self.center = np.array(center)
        self.radius = radius
        self.start_angle = np.radians(start_angle)
        self.sweep_angle = np.radians(sweep_angle)
        self.angle_step = np.radians(angle_step)
        self.velocity = 0  # 静止
    
    def get_scatterers(self):
        """返回散射点数组 [N, 4]"""
        # 角度范围
        theta = np.arange(self.start_angle, 
                         self.start_angle + self.sweep_angle + self.angle_step, 
                         self.angle_step)
        
        # 创建4条圆弧线（类似直线隔离带的4层结构）
        curve_layers = []
        
        for r_offset, z_offset in [(0, 0), (-1, 0), (-1, 1), (0, 1)]:
            r = self.radius + r_offset
            x = self.center[0] + r * np.cos(theta)
            y = self.center[1] + r * np.sin(theta)
            z = np.ones_like(theta) * (self.center[2] + z_offset)
            curve_layers.append(np.column_stack([x, y, z]))
        
        plant_curve = np.vstack(curve_layers)
        
        # 添加速度信息
        velocity_column = np.zeros((plant_curve.shape[0], 1))
        return np.hstack([plant_curve, velocity_column])


class StreetLight:
    """
    路灯类
    默认属性：
    - 底座位置：(0, 0, 0)
    - 高度：10m
    - 速度：0 m/s（静止）
    """
    def __init__(self, position=(0, 0, 0)):
        """
        参数：
        - position: (x, y, z) 路灯底座坐标
        """
        self.position = np.array(position)
        self.velocity = 0  # 静止
    
    def get_scatterers(self):
        """返回散射点数组 [N, 4]"""
        # 路灯模板（相对坐标）
        light_template = np.array([
            [0, 0, 2], [0, 0, 3], [0, 0, 4], [0, 0, 5], [0, 0, 6],
            [0, 0, 7], [0, 0, 8], [0, 0, 9], [0, 0, 10],  # 灯杆
            [-1, 0, 10], [1, 0, 10], [0, -1, 10], [0, 1, 10]  # 灯头
        ])
        
        # 平移到指定位置
        translated = light_template + self.position
        
        # 添加速度信息
        velocity_column = np.zeros((translated.shape[0], 1))
        return np.hstack([translated, velocity_column])


class Pedestrian:
    """
    行人类
    默认属性：
    - 中心点：(0, 0, 0)
    - 方向：沿Y轴正向（0°）
    - 速度：2 m/s
    - 尺寸：约 0.5m × 0.5m × 1.8m
    """
    def __init__(self, center=(0, 0, 0), direction=0, velocity=2):
        """
        参数：
        - center: (x, y, z) 行人中心点坐标
        - direction: 行人朝向角度（度），0°为Y轴正向
        - velocity: 行人速度 (m/s)
        """
        self.center = np.array(center)
        self.direction = np.radians(direction)
        self.velocity = velocity
        self.scatterers = self._create_model()
    
    def _create_model(self):
        """创建行人的散射点模板（相对坐标）"""
        people_template = np.array([
            [0, 0, 0], [0.5, 0.5, 0], [0.25, 0.3, 1], [0.25, 0.3, 1.5],
            [0.25, 0.3, 1.7], [0.4, 0.4, 0.5], [0.1, 0.2, 0.5], [0.25, 0.3, 1.8],
            [0.5, 0.3, 1.4], [0, 0.3, 1.4], [0.5, 0.5, 1], [0, 0, 0.9]
        ])
        return people_template
    
    def get_scatterers(self):
        """返回散射点数组 [N, 4]"""
        # 旋转变换
        cos_theta = np.cos(self.direction)
        sin_theta = np.sin(self.direction)
        rotation_matrix = np.array([
            [cos_theta, -sin_theta, 0],
            [sin_theta, cos_theta, 0],
            [0, 0, 1]
        ])
        
        rotated = self.scatterers @ rotation_matrix.T
        translated = rotated + self.center
        
        # 添加速度信息
        velocity_column = np.ones((translated.shape[0], 1)) * self.velocity
        return np.hstack([translated, velocity_column])


# ============================================================
# 兼容旧接口的辅助函数（保持向后兼容）
# ============================================================

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
    """创建两组车辆（不同位置和速度）- 兼容旧接口"""
    # 使用新的Vehicle类
    car1 = Vehicle(center=(8, 12, 0), direction=0, velocity=10)
    car2 = Vehicle(center=(18, 2, 0), direction=0, velocity=-10)
    
    car_group = np.vstack([car1.get_scatterers(), car2.get_scatterers()])
    return car_group


def create_plant_group_straight():
    """创建直线隔离带散射点（原始风格）- 兼容旧接口"""
    barrier = StraightBarrier(start=(13, 0, 0), direction=0, length=20, spacing=0.5)
    return barrier.get_scatterers()


def create_plant_group_curve():
    """创建1/4圆弧形隔离带，模拟弯道 - 兼容旧接口"""
    curve = CurveBarrier(center=(35, 0, 0), radius=15, start_angle=0, sweep_angle=90, angle_step=2.86)
    return curve.get_scatterers()


def create_light_group():
    """创建路灯散射点 - 兼容旧接口"""
    light1 = StreetLight(position=(15, 3, 0))
    light2 = StreetLight(position=(14, 18, 0))
    
    light_group = np.vstack([light1.get_scatterers(), light2.get_scatterers()])
    return light_group


def create_people_group():
    """创建行人散射点 - 兼容旧接口"""
    # 4个行人，不同位置和速度
    person1 = Pedestrian(center=(1, 2, 0), direction=0, velocity=2)
    person2 = Pedestrian(center=(2, 13, 0), direction=0, velocity=2)
    person3 = Pedestrian(center=(27, 7, 0), direction=180, velocity=-2)
    person4 = Pedestrian(center=(27, 18, 0), direction=180, velocity=-2)
    
    people_group = np.vstack([
        person1.get_scatterers(),
        person2.get_scatterers(),
        person3.get_scatterers(),
        person4.get_scatterers()
    ])
    return people_group


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
    ax.set_title('Curved Road Scenario (50m × 20m × 20m)', fontsize=14, fontweight='bold')
    
    # 设置三个轴的比例一致（1m在三个轴上显示长度相同）
    ax.set_box_aspect([50, 20, 20])  # 与实际空间尺寸比例一致
    
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
    cbar = plt.colorbar(scatter_car, ax=ax, pad=0.1, shrink=0.8)
    cbar.set_label('Velocity (m/s)', rotation=270, labelpad=20, fontsize=11)
    
    # 添加图例
    ax.legend(loc='upper left', fontsize=9)
    
    # 设置视角
    ax.view_init(elev=15, azim=45)
    
    plt.tight_layout()
    return fig, ax


def main():
    """主函数：生成并可视化弯道场景"""
    print("=" * 60)
    print("弯道场景仿真 - Environment New V1 (面向对象版本)")
    print("场景尺寸: 50m × 20m × 20m")
    print("=" * 60)
    
    # 创建各类散射点
    car_group = create_car_groups()
    plant_straight = create_plant_group_straight()  # 直线隔离带
    plant_curve = create_plant_group_curve()        # 圆弧隔离带（新增）
    light_group = create_light_group()
    people_group = create_people_group()
    
    # 打印统计信息
    print(f"\n散射点统计:")
    print(f"  车辆散射点数: {car_group.shape[0]}")
    print(f"  直线隔离带散射点数: {plant_straight.shape[0]}")
    print(f"  圆弧隔离带散射点数: {plant_curve.shape[0]} (新增)")
    print(f"  路灯散射点数: {light_group.shape[0]}")
    print(f"  行人散射点数: {people_group.shape[0]}")
    total_points = (car_group.shape[0] + plant_straight.shape[0] + 
                   plant_curve.shape[0] + light_group.shape[0] + people_group.shape[0])
    print(f"  总散射点数: {total_points}")
    
    # 打印圆弧参数
    print(f"\n圆弧隔离带参数:")
    print(f"  圆心位置: (35, 0)")
    print(f"  半径范围: 14-15m")
    print(f"  角度范围: 0° ~ 90°")
    print(f"  高度层数: 2层 (z=0, z=1)")
    
    # 可视化
    fig, ax = visualize_environment(car_group, plant_straight, plant_curve, 
                                   light_group, people_group)
    
    # 保存图像
    output_path = '2D_FFT_2D_MUSIC/image/environment_new_v1.png'
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"\n✓ 图像已保存: {output_path}")
    
    plt.show()
    
    # 返回所有散射点数据（用于后续处理）
    return {
        'car': car_group,
        'plant_straight': plant_straight,
        'plant_curve': plant_curve,
        'light': light_group,
        'people': people_group,
        'all': np.vstack([car_group, plant_straight, plant_curve, 
                         light_group, people_group])
    }


def demo_custom_scene():
    """演示：如何使用类快速创建自定义场景"""
    print("\n" + "=" * 60)
    print("自定义场景演示")
    print("=" * 60)
    
    # 创建自定义对象
    vehicles = [
        Vehicle(center=(10, 5, 0), direction=0, velocity=15),    # 车辆1：Y轴正向
        Vehicle(center=(20, 15, 0), direction=90, velocity=12),  # 车辆2：X轴正向（转向）
        Vehicle(center=(30, 10, 0), direction=180, velocity=-8), # 车辆3：Y轴负向（倒车）
    ]
    
    barriers = [
        StraightBarrier(start=(5, 0, 0), direction=0, length=20),   # 垂直隔离带
        StraightBarrier(start=(25, 0, 0), direction=45, length=15), # 45度斜向隔离带
        CurveBarrier(center=(40, 5, 0), radius=10, start_angle=0, sweep_angle=180),  # 半圆弧
    ]
    
    lights = [
        StreetLight(position=(i*10, 2, 0)) for i in range(1, 5)  # 一排路灯
    ]
    
    pedestrians = [
        Pedestrian(center=(8, i*5, 0), direction=0, velocity=1.5) for i in range(1, 4)
    ]
    
    # 合并所有散射点
    all_scatterers = []
    for obj_list in [vehicles, barriers, lights, pedestrians]:
        for obj in obj_list:
            all_scatterers.append(obj.get_scatterers())
    
    scene_data = np.vstack(all_scatterers)
    
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
