"""
批量生成蒙特卡洛场景 - Scenario 1
支持保存为 MATLAB 可读的 .mat 文件
"""

import numpy as np
import matplotlib.pyplot as plt
from monte_carlo_generator_scenario1 import MonteCarloSceneGenerator, visualize_scene
import os
from tqdm import tqdm
import scipy.io as sio


def save_scene_to_mat(scene_data, mat_path, scene_id):
    """
    将场景数据保存为 MATLAB 可读的 .mat 文件
    
    参数：
    - scene_data: 场景数据字典
    - mat_path: .mat 文件保存路径
    - scene_id: 场景编号
    """
    # 提取散射点数据
    scatterers = scene_data['scatterers']
    
    # 构建 MATLAB 结构
    mat_data = {
        'scene_id': scene_id,
        'scatterers': {
            'all': scatterers['all'],  # [N, 4] - (x, y, z, RCS)
            'vehicles': scatterers['vehicles'],
            'barrier': scatterers['barrier'],
            'lights': scatterers['lights'],
            'pedestrians': scatterers['pedestrians']
        },
        'object_counts': {
            'num_vehicles': len(scene_data['objects']['vehicles']),
            'num_pedestrians': len(scene_data['objects']['pedestrians']),
            'num_lights': len(scene_data['objects']['lights']),
            'num_scatterers': scatterers['all'].shape[0]
        }
    }
    
    # 添加车辆详细信息
    vehicles = scene_data['objects']['vehicles']
    if len(vehicles) > 0:
        vehicle_info = {
            'centers': np.array([v.center for v in vehicles]),  # [N, 3]
            'directions': np.array([v.direction for v in vehicles]),  # [N]
            'velocities': np.array([v.velocity for v in vehicles]),  # [N]
            'scatterers': scatterers['vehicles']  # [M, 4]
        }
        mat_data['vehicles'] = vehicle_info
    else:
        mat_data['vehicles'] = {
            'centers': np.empty((0, 3)),
            'directions': np.empty(0),
            'velocities': np.empty(0),
            'scatterers': np.empty((0, 4))
        }
    
    # 添加行人详细信息
    pedestrians = scene_data['objects']['pedestrians']
    if len(pedestrians) > 0:
        pedestrian_info = {
            'centers': np.array([p.center for p in pedestrians]),  # [N, 3]
            'directions': np.array([p.direction for p in pedestrians]),  # [N]
            'velocities': np.array([p.velocity for p in pedestrians]),  # [N]
            'scatterers': scatterers['pedestrians']  # [M, 4]
        }
        mat_data['pedestrians'] = pedestrian_info
    else:
        mat_data['pedestrians'] = {
            'centers': np.empty((0, 3)),
            'directions': np.empty(0),
            'velocities': np.empty(0),
            'scatterers': np.empty((0, 4))
        }
    
    # 添加固定对象信息
    barrier = scene_data['objects']['barrier']
    lights = scene_data['objects']['lights']
    
    mat_data['barrier'] = {
        'start': barrier.requested_start,
        'center': barrier.center,
        'length': barrier.length,
        'direction': barrier.direction,
        'scatterers': scatterers['barrier']
    }
    
    mat_data['lights'] = {
        'centers': np.array([l.center for l in lights]),  # [N, 3]
        'scatterers': scatterers['lights']
    }
    
    # 添加场景配置信息
    mat_data['config'] = {
        'space_x_range': [0, 28],
        'space_y_range': [0, 28],
        'space_z_range': [0, 20],
        'barrier_x': 14.0,
        'description': 'Scenario 1: Fixed barrier at center with random vehicles and pedestrians'
    }
    
    # 保存为 .mat 文件
    sio.savemat(mat_path, mat_data, oned_as='row')


def generate_batch_scenes(num_scenes=10, output_dir='scenario_1', seed_start=0, save_mat=True):
    """
    批量生成场景
    
    参数：
    - num_scenes: 要生成的场景数量
    - output_dir: 输出目录
    - seed_start: 起始随机种子
    - save_mat: 是否保存为 .mat 文件
    """
    print("=" * 70)
    print(f"批量生成蒙特卡洛场景 - Scenario 1")
    print(f"场景数量: {num_scenes}")
    print(f"输出目录: {output_dir}")
    print(f"保存 .mat 文件: {'是' if save_mat else '否'}")
    print("=" * 70)
    
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    if save_mat:
        mat_dir = os.path.join(output_dir, 'mat_files')
        os.makedirs(mat_dir, exist_ok=True)
    
    # 统计信息
    stats = {
        'vehicle_counts': [],
        'pedestrian_counts': [],
        'total_scatterers': [],
        'scene_data_list': []  # 保存所有场景数据用于后续分析
    }
    
    # 生成场景
    for i in tqdm(range(num_scenes), desc="生成场景"):
        seed = seed_start + i
        scene_id = i + 1
        
        # 生成场景
        generator = MonteCarloSceneGenerator(seed=seed)
        scene_data = generator.generate_scene()
        
        # 统计
        num_vehicles = len(scene_data['objects']['vehicles'])
        num_pedestrians = len(scene_data['objects']['pedestrians'])
        num_scatterers = scene_data['scatterers']['all'].shape[0]
        
        stats['vehicle_counts'].append(num_vehicles)
        stats['pedestrian_counts'].append(num_pedestrians)
        stats['total_scatterers'].append(num_scatterers)
        stats['scene_data_list'].append({
            'id': scene_id,
            'seed': seed,
            'num_vehicles': num_vehicles,
            'num_pedestrians': num_pedestrians,
            'num_scatterers': num_scatterers
        })
        
        # 保存可视化
        save_path = os.path.join(output_dir, f'scene_{scene_id:03d}.png')
        fig, ax = visualize_scene(scene_data, save_path=save_path)
        plt.close(fig)
        
        # 保存为 .mat 文件
        if save_mat:
            mat_path = os.path.join(mat_dir, f'scene_{scene_id:03d}.mat')
            save_scene_to_mat(scene_data, mat_path, scene_id)
    
    # 保存汇总的 .mat 文件（包含所有场景的统计信息）
    if save_mat:
        summary_data = {
            'num_scenes': num_scenes,
            'seed_start': seed_start,
            'vehicle_counts': np.array(stats['vehicle_counts']),
            'pedestrian_counts': np.array(stats['pedestrian_counts']),
            'total_scatterers': np.array(stats['total_scatterers']),
            'scene_info': stats['scene_data_list']
        }
        summary_path = os.path.join(output_dir, 'summary.mat')
        sio.savemat(summary_path, summary_data, oned_as='row')
        print(f"\n✓ 汇总文件已保存: {summary_path}")
    
    # 打印统计结果
    print("\n" + "=" * 70)
    print("生成统计")
    print("=" * 70)
    print(f"车辆数量:")
    print(f"  - 平均: {np.mean(stats['vehicle_counts']):.2f} 辆/场景")
    print(f"  - 范围: [{np.min(stats['vehicle_counts'])}, {np.max(stats['vehicle_counts'])}] 辆")
    print(f"  - 成功率: {np.sum(stats['vehicle_counts']) / (num_scenes * 5) * 100:.1f}%")
    
    print(f"\n行人数量:")
    print(f"  - 平均: {np.mean(stats['pedestrian_counts']):.2f} 人/场景")
    print(f"  - 范围: [{np.min(stats['pedestrian_counts'])}, {np.max(stats['pedestrian_counts'])}] 人")
    print(f"  - 成功率: {np.sum(stats['pedestrian_counts']) / (num_scenes * 7) * 100:.1f}%")
    
    print(f"\n总散射点数:")
    print(f"  - 平均: {np.mean(stats['total_scatterers']):.0f} 个/场景")
    print(f"  - 范围: [{np.min(stats['total_scatterers'])}, {np.max(stats['total_scatterers'])}] 个")
    
    print("\n" + "=" * 70)
    print(f"✓ 所有场景已保存到: {output_dir}")
    if save_mat:
        print(f"✓ MATLAB 文件已保存到: {mat_dir}")
    print("=" * 70)
    
    return stats


def plot_statistics(stats, output_path='scenario_1/statistics.png'):
    """
    绘制统计图表
    
    参数：
    - stats: 统计数据
    - output_path: 保存路径
    """
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
     
    # 车辆数量分布
    axes[0, 0].hist(stats['vehicle_counts'], bins=range(0, 8), alpha=0.7, color='red', edgecolor='black')
    axes[0, 0].set_xlabel('Number of Vehicles', fontsize=12)
    axes[0, 0].set_ylabel('Number of Scenes', fontsize=12)
    axes[0, 0].set_title('Vehicle Count Distribution', fontsize=14, fontweight='bold')
    axes[0, 0].grid(True, alpha=0.3)
    
    # 行人数量分布
    axes[0, 1].hist(stats['pedestrian_counts'], bins=range(0, 10), alpha=0.7, color='blue', edgecolor='black')
    axes[0, 1].set_xlabel('Number of Pedestrians', fontsize=12)
    axes[0, 1].set_ylabel('Number of Scenes', fontsize=12)
    axes[0, 1].set_title('Pedestrian Count Distribution', fontsize=14, fontweight='bold')
    axes[0, 1].grid(True, alpha=0.3)
    
    # 总散射点数分布
    axes[1, 0].hist(stats['total_scatterers'], bins=20, alpha=0.7, color='green', edgecolor='black')
    axes[1, 0].set_xlabel('Total Scatterers', fontsize=12)
    axes[1, 0].set_ylabel('Number of Scenes', fontsize=12)
    axes[1, 0].set_title('Total Scatterer Distribution', fontsize=14, fontweight='bold')
    axes[1, 0].grid(True, alpha=0.3)
    
    # 车辆vs行人散点图
    axes[1, 1].scatter(stats['vehicle_counts'], stats['pedestrian_counts'], 
                       s=100, alpha=0.6, c=stats['total_scatterers'], cmap='viridis')
    axes[1, 1].set_xlabel('Number of Vehicles', fontsize=12)
    axes[1, 1].set_ylabel('Number of Pedestrians', fontsize=12)
    axes[1, 1].set_title('Vehicles vs Pedestrians', fontsize=14, fontweight='bold')
    axes[1, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"\n✓ 统计图表已保存: {output_path}")
    plt.close()


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='批量生成蒙特卡洛场景 - Scenario 1')
    parser.add_argument('--num-scenes', type=int, default=500, help='场景数量')
    parser.add_argument('--output-dir', type=str, default='scenario_3', help='输出目录')
    parser.add_argument('--seed', type=int, default=0, help='起始随机种子')
    parser.add_argument('--no-mat', action='store_true', help='不保存 .mat 文件')
    
    args = parser.parse_args()
    
    # 生成场景
    stats = generate_batch_scenes(
        num_scenes=args.num_scenes,
        output_dir=args.output_dir,
        seed_start=args.seed,
        save_mat=not args.no_mat
    )
    
    # 绘制统计图表
    plot_statistics(stats, output_path=os.path.join(args.output_dir, 'statistics.png'))


if __name__ == '__main__':
    main()
