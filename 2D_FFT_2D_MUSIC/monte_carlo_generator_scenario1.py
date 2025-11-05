"""
蒙特卡洛场景生成器 V2
- 简化的碰撞检测：以物体中心画圆判断
- 固定布局：直线隔离带在场景中间
- 考虑与静止物体（隔离带、路灯）的碰撞
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from scene_objects import Vehicle, StraightBarrier, StreetLight, Pedestrian


class SceneConfig:
    """场景配置参数"""
    # 空间范围
    SPACE_X_MIN = 0
    SPACE_X_MAX = 28
    SPACE_Y_MIN = 0
    SPACE_Y_MAX = 20
    SPACE_Z_MIN = 0
    SPACE_Z_MAX = 20
    
    # 碰撞检测半径（以物体中心为圆心）
    # 车辆实测外接圆半径: 3.18m，加20%安全余量 = 3.82m
    # 使用4.0m确保任意旋转角度都不会重叠
    VEHICLE_RADIUS = 3.5      # 车辆碰撞半径 (基于实测值3.18m + 余量)
    PEDESTRIAN_RADIUS = 0.6   # 行人碰撞半径
    BARRIER_RADIUS = 0.75      # 隔离带碰撞半径
    LIGHT_RADIUS = 1.5        # 路灯碰撞半径
    
    # 安全距离缓冲
    SAFETY_BUFFER = 0.5       # 额外的安全距离 (确保物体间有足够间隙)
    
    # 数量范围
    NUM_VEHICLES = (3, 4)     # 车辆数量范围
    NUM_PEDESTRIANS = (4, 6)  # 行人数量范围
    NUM_LIGHTS = 2            # 路灯数量（固定）
    
    # 速度范围
    VEHICLE_SPEED_RANGE = (-10, 10)      # 车辆速度范围 (m/s)
    PEDESTRIAN_SPEED_RANGE = (-2, 2)    # 行人速度范围 (m/s)


class MonteCarloSceneGenerator:
    """蒙特卡洛场景生成器"""
    
    def __init__(self, seed=None):
        """
        初始化生成器
        
        参数：
        - seed: 随机种子，用于可复现性
        """
        if seed is not None:
            np.random.seed(seed)
        
        self.config = SceneConfig()
        
        # 存储生成的对象
        self.vehicles = []
        self.pedestrians = []
        self.barrier = None
        self.lights = []
        
        # 存储对象的碰撞圆信息 (center_x, center_y, radius)
        self.static_obstacles = []  # 静止障碍物（隔离带、路灯）
    
    def generate_scene(self):
        """
        生成完整的交通场景
        
        返回：
        - dict: 包含所有对象和散射点数据
        """
        print("\n" + "=" * 60)
        print("开始生成蒙特卡洛场景")
        print("=" * 60)
        
        # 1. 生成固定布局（隔离带和路灯）
        self._generate_fixed_layout()
        
        # 2. 生成随机车辆
        self._generate_vehicles()
        
        # 3. 生成随机行人
        self._generate_pedestrians()
        
        # 4. 收集所有散射点
        scene_data = self._collect_scatterers()
        
        print("\n" + "=" * 60)
        print("场景生成完成")
        print("=" * 60)
        self._print_statistics()
        
        return scene_data
    
    def _generate_fixed_layout(self):
        """生成固定布局：隔离带在场景中间，两侧各一个路灯"""
        print("\n[1/3] 生成固定布局...")
        
        # 1. 直线隔离带：在场景中间（X=14），从Y=0到Y=20
        barrier_x = (self.config.SPACE_X_MIN + self.config.SPACE_X_MAX) / 2
        self.barrier = StraightBarrier(
            start=(barrier_x, self.config.SPACE_Y_MIN, 0),
            direction=0,  # 沿Y轴
            length=self.config.SPACE_Y_MAX
        )
        
        # 添加到静止障碍物列表（用直线段表示）
        # 隔离带是一条线，我们用多个圆来近似
        num_segments = 20
        for i in range(num_segments):
            y_pos = self.config.SPACE_Y_MIN + (i + 0.5) * self.config.SPACE_Y_MAX / num_segments
            self.static_obstacles.append({
                'center': (barrier_x, y_pos),
                'radius': self.config.BARRIER_RADIUS,
                'type': 'barrier'
            })
        
        print(f"  ✓ 隔离带: X={barrier_x:.1f}, 长度={self.config.SPACE_Y_MAX}m")
        
        # 2. 路灯：隔离带两侧
        light_positions = [
            (barrier_x + 1, 3, 0),   # 左侧
            (barrier_x , 17, 0)   # 右侧
        ]
        
        for i, pos in enumerate(light_positions, 1):
            light = StreetLight(position=pos)
            self.lights.append(light)
            
            # 添加到静止障碍物列表
            self.static_obstacles.append({
                'center': (pos[0], pos[1]),
                'radius': self.config.LIGHT_RADIUS,
                'type': 'light'
            })
            
            print(f"  ✓ 路灯 {i}: ({pos[0]:.1f}, {pos[1]:.1f})")
    
    def _generate_vehicles(self):
        """生成随机车辆"""
        num_vehicles = np.random.randint(*self.config.NUM_VEHICLES)
        print(f"\n[2/3] 生成随机车辆（目标: {num_vehicles} 辆）...")
        
        max_attempts = 100
        
        for i in range(num_vehicles):
            for attempt in range(max_attempts):
                # 随机位置（Z固定为0）
                x = np.random.uniform(
                    self.config.SPACE_X_MIN + self.config.VEHICLE_RADIUS,
                    self.config.SPACE_X_MAX - self.config.VEHICLE_RADIUS
                )
                y = np.random.uniform(
                    self.config.SPACE_Y_MIN + self.config.VEHICLE_RADIUS,
                    self.config.SPACE_Y_MAX - self.config.VEHICLE_RADIUS
                )
                center = (x, y, 0)
                
                # 方向：0° 或 180°
                direction = np.random.choice([0, 180])
                
                # 速度：10 或 -10 m/s
                velocity = np.random.choice([10, -10])
                
                # 先创建车辆对象以获取实际的几何中心
                vehicle = Vehicle(center=center, direction=direction, velocity=velocity)
                # 获取实际散射点的XY平面中心
                actual_center = vehicle.get_scatterers()[:, :2].mean(axis=0)
                actual_center_3d = (actual_center[0], actual_center[1], 0)
                
                # 使用实际中心进行碰撞检测
                if self._check_collision_free(actual_center_3d, self.config.VEHICLE_RADIUS, 'vehicle'):
                    self.vehicles.append({
                        'object': vehicle,
                        'center': actual_center_3d,  # 使用实际中心
                        'radius': self.config.VEHICLE_RADIUS
                    })
                    print(f"  ✓ 车辆 {i+1}: 位置 ({x:.1f}, {y:.1f}), 实际中心 ({actual_center[0]:.1f}, {actual_center[1]:.1f}), 朝向 {direction:.0f}°, 速度 {velocity:.1f} m/s")
                    break
            else:
                print(f"  ✗ 车辆 {i+1}: 生成失败（{max_attempts}次尝试后空间不足）")
    
    def _generate_pedestrians(self):
        """生成随机行人"""
        num_pedestrians = np.random.randint(*self.config.NUM_PEDESTRIANS)
        print(f"\n[3/3] 生成随机行人（目标: {num_pedestrians} 人）...")
        
        max_attempts = 100
        
        for i in range(num_pedestrians):
            for attempt in range(max_attempts):
                # 随机位置（Z固定为0）
                x = np.random.uniform(
                    self.config.SPACE_X_MIN + self.config.PEDESTRIAN_RADIUS,
                    self.config.SPACE_X_MAX - self.config.PEDESTRIAN_RADIUS
                )
                y = np.random.uniform(
                    self.config.SPACE_Y_MIN + self.config.PEDESTRIAN_RADIUS,
                    self.config.SPACE_Y_MAX - self.config.PEDESTRIAN_RADIUS
                )
                center = (x, y, 0)
                
                # 方向：0° 或 180°
                direction = np.random.choice([0, 180])
                
                # 速度：2 或 -2 m/s
                velocity = np.random.choice([2, -2])
                
                # 先创建行人对象以获取实际的几何中心
                pedestrian = Pedestrian(center=center, direction=direction, velocity=velocity)
                # 获取实际散射点的XY平面中心
                actual_center = pedestrian.get_scatterers()[:, :2].mean(axis=0)
                actual_center_3d = (actual_center[0], actual_center[1], 0)
                
                # 使用实际中心进行碰撞检测
                if self._check_collision_free(actual_center_3d, self.config.PEDESTRIAN_RADIUS, 'pedestrian'):
                    self.pedestrians.append({
                        'object': pedestrian,
                        'center': actual_center_3d,  # 使用实际中心
                        'radius': self.config.PEDESTRIAN_RADIUS
                    })
                    print(f"  ✓ 行人 {i+1}: 位置 ({x:.1f}, {y:.1f}), 实际中心 ({actual_center[0]:.1f}, {actual_center[1]:.1f}), 朝向 {direction:.0f}°, 速度 {velocity:.1f} m/s")
                    break
            else:
                print(f"  ✗ 行人 {i+1}: 生成失败（{max_attempts}次尝试后空间不足）")
    
    def _check_collision_free(self, center, radius, obj_type):
        """
        检查位置是否无碰撞（圆形碰撞检测）
        
        参数：
        - center: (x, y, z) 物体中心
        - radius: 物体碰撞半径
        - obj_type: 物体类型 ('vehicle' 或 'pedestrian')
        
        返回：
        - bool: True=无碰撞, False=有碰撞
        """
        x, y, z = center
        
        # 1. 检查边界
        if (x - radius < self.config.SPACE_X_MIN or
            x + radius > self.config.SPACE_X_MAX or
            y - radius < self.config.SPACE_Y_MIN or
            y + radius > self.config.SPACE_Y_MAX):
            return False
        
        # 2. 检查与静止障碍物的碰撞（隔离带、路灯）
        for obstacle in self.static_obstacles:
            distance = np.sqrt(
                (x - obstacle['center'][0])**2 + 
                (y - obstacle['center'][1])**2
            )
            min_distance = radius + obstacle['radius'] + self.config.SAFETY_BUFFER
            if distance < min_distance:
                return False
        
        # 3. 检查与已有车辆的碰撞
        for vehicle_info in self.vehicles:
            distance = np.sqrt(
                (x - vehicle_info['center'][0])**2 + 
                (y - vehicle_info['center'][1])**2
            )
            min_distance = radius + vehicle_info['radius'] + self.config.SAFETY_BUFFER
            if distance < min_distance:
                return False
        
        # 4. 检查与已有行人的碰撞
        for pedestrian_info in self.pedestrians:
            distance = np.sqrt(
                (x - pedestrian_info['center'][0])**2 + 
                (y - pedestrian_info['center'][1])**2
            )
            min_distance = radius + pedestrian_info['radius'] + self.config.SAFETY_BUFFER
            if distance < min_distance:
                return False
        
        return True
    
    def _collect_scatterers(self):
        """收集所有散射点"""
        vehicle_scatterers = np.vstack([v['object'].get_scatterers() for v in self.vehicles]) if self.vehicles else np.empty((0, 4))
        barrier_scatterers = self.barrier.get_scatterers()
        light_scatterers = np.vstack([l.get_scatterers() for l in self.lights])
        pedestrian_scatterers = np.vstack([p['object'].get_scatterers() for p in self.pedestrians]) if self.pedestrians else np.empty((0, 4))
        
        all_scatterers = np.vstack([
            vehicle_scatterers,
            barrier_scatterers,
            light_scatterers,
            pedestrian_scatterers
        ])
        
        return {
            'objects': {
                'vehicles': [v['object'] for v in self.vehicles],
                'barrier': self.barrier,
                'lights': self.lights,
                'pedestrians': [p['object'] for p in self.pedestrians]
            },
            'scatterers': {
                'vehicles': vehicle_scatterers,
                'barrier': barrier_scatterers,
                'lights': light_scatterers,
                'pedestrians': pedestrian_scatterers,
                'all': all_scatterers
            }
        }
    
    def _print_statistics(self):
        """打印场景统计信息"""
        print(f"\n固定对象:")
        print(f"  - 隔离带: 1 段 (直线)")
        print(f"  - 路灯: {len(self.lights)} 个")
        print(f"可移动对象:")
        print(f"  - 车辆: {len(self.vehicles)} 辆")
        print(f"  - 行人: {len(self.pedestrians)} 人")


def visualize_scene(scene_data, save_path=None):
    """
    可视化场景（俯视图）
    
    参数：
    - scene_data: 场景数据
    - save_path: 保存路径（可选）
    """
    scatterers = scene_data['scatterers']
    
    fig = plt.figure(figsize=(14, 10))
    ax = fig.add_subplot(111)
    
    # 绘制车辆（根据速度着色）- 只使用XY坐标
    if scatterers['vehicles'].shape[0] > 0:
        vehicle_data = scatterers['vehicles']
        scatter_vehicle = ax.scatter(
            vehicle_data[:, 0], vehicle_data[:, 1],
            c=vehicle_data[:, 3], s=80, marker='.', cmap='RdYlGn',
            vmin=0, vmax=20, label='Vehicles', alpha=0.8
        )
        cbar = plt.colorbar(scatter_vehicle, ax=ax, pad=0.02, shrink=0.8)
        cbar.set_label('Vehicle Velocity (m/s)', rotation=270, labelpad=20)
    
    # 绘制隔离带（绿色）- 只使用XY坐标
    barrier_data = scatterers['barrier']
    ax.scatter(
        barrier_data[:, 0], barrier_data[:, 1],
        c='darkgreen', s=60, marker='.', alpha=0.7, label='Barrier'
    )
    
    # 绘制路灯（黄色）- 只使用XY坐标
    light_data = scatterers['lights']
    ax.scatter(
        light_data[:, 0], light_data[:, 1],
        c='gold', s=150, marker='^', label='Street Lights', edgecolors='orange', linewidths=1.5
    )
    
    # 绘制行人（蓝色系）- 只使用XY坐标
    if scatterers['pedestrians'].shape[0] > 0:
        pedestrian_data = scatterers['pedestrians']
        ax.scatter(
            pedestrian_data[:, 0], pedestrian_data[:, 1],
            c=pedestrian_data[:, 3], s=80, marker='o', cmap='Blues',
            vmin=0, vmax=3, label='Pedestrians', alpha=0.8, edgecolors='navy'
        )
    
    # 设置坐标轴 - 统一为28m×28m
    ax.set_xlim(0, 28)
    ax.set_ylim(0, 28)
    ax.set_xlabel('X (m)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Y (m)', fontsize=12, fontweight='bold')
    ax.set_title('Monte Carlo Traffic Scene (Top View)', fontsize=14, fontweight='bold')
    
    # 设置等比例显示
    ax.set_aspect('equal', adjustable='box')
    
    # 设置网格
    from matplotlib.ticker import MultipleLocator
    ax.xaxis.set_major_locator(MultipleLocator(5))
    ax.yaxis.set_major_locator(MultipleLocator(5))
    ax.grid(True, alpha=0.3, linestyle='--')
    
    # 添加图例
    ax.legend(loc='upper left', fontsize=10)
    
    plt.tight_layout()
    
    if save_path:
        import os
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"\n✓ 图片已保存: {save_path}")
    
    return fig, ax


def main():
    """主函数"""
    # 创建生成器
    generator = MonteCarloSceneGenerator(seed=42)
    
    # 生成场景
    scene_data = generator.generate_scene()
    
    # 可视化
    fig, ax = visualize_scene(scene_data, save_path='image/monte_carlo_scene_v2.png')
    
    plt.show()
    
    return scene_data


if __name__ == '__main__':
    scene_data = main()
