"""
ISAC 场景对象类库
提供车辆、隔离带、路灯、行人等交通场景元素的建模

作者: AI Assistant
日期: 2025-11-04
版本: 1.0
"""

import numpy as np


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


# 模块信息
__all__ = ['Vehicle', 'StraightBarrier', 'CurveBarrier', 'StreetLight', 'Pedestrian']
__version__ = '1.0.0'
__author__ = 'AI Assistant'
