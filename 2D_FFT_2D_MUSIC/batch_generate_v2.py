"""
批量生成蒙特卡洛场景
测试新的圆形碰撞检测生成器
"""

import numpy as np
import matplotlib.pyplot as plt
from monte_carlo_generator_scenario1 import MonteCarloSceneGenerator, visualize_scene
import os
from tqdm import tqdm


def generate_batch_scenes(num_scenes=10, output_dir='monte_carlo_scenes_v2', seed_start=0):
    """
    批量生成场景
    
    参数：
    - num_scenes: 要生成的场景数量
    - output_dir: 输出目录
    - seed_start: 起始随机种子
    """
    print("=" * 70)
    print(f"批量生成蒙特卡洛场景 V2")
    print(f"场景数量: {num_scenes}")
    print(f"输出目录: {output_dir}")
    print("=" * 70)
    
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    
    # 统计信息
    stats = {
        'vehicle_counts': [],
        'pedestrian_counts': [],
        'total_scatterers': []
    }
    
    # 生成场景
    for i in tqdm(range(num_scenes), desc="生成场景"):
        seed = seed_start + i
        
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
        
        # 保存可视化
        save_path = os.path.join(output_dir, f'scene_{i+1:03d}.png')
        fig, ax = visualize_scene(scene_data, save_path=save_path)
        plt.close(fig)
    
    # 打印统计结果
    print("\n" + "=" * 70)
    print("生成统计")
    print("=" * 70)
    print(f"车辆数量:")
    print(f"  - 平均: {np.mean(stats['vehicle_counts']):.2f} 辆/场景")
    print(f"  - 范围: [{np.min(stats['vehicle_counts'])}, {np.max(stats['vehicle_counts'])}] 辆")
    print(f"  - 成功率: {np.sum(stats['vehicle_counts']) / (num_scenes * 5) * 100:.1f}%")  # 假设目标5辆
    
    print(f"\n行人数量:")
    print(f"  - 平均: {np.mean(stats['pedestrian_counts']):.2f} 人/场景")
    print(f"  - 范围: [{np.min(stats['pedestrian_counts'])}, {np.max(stats['pedestrian_counts'])}] 人")
    print(f"  - 成功率: {np.sum(stats['pedestrian_counts']) / (num_scenes * 7) * 100:.1f}%")  # 假设目标7人
    
    print(f"\n总散射点数:")
    print(f"  - 平均: {np.mean(stats['total_scatterers']):.0f} 个/场景")
    print(f"  - 范围: [{np.min(stats['total_scatterers'])}, {np.max(stats['total_scatterers'])}] 个")
    
    print("\n" + "=" * 70)
    print(f"✓ 所有场景已保存到: {output_dir}")
    print("=" * 70)
    
    return stats


def plot_statistics(stats, output_path='monte_carlo_scenes_v2/statistics.png'):
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
    
    parser = argparse.ArgumentParser(description='批量生成蒙特卡洛场景')
    parser.add_argument('--num-scenes', type=int, default=10, help='场景数量')
    parser.add_argument('--output-dir', type=str, default='scenario_1', help='输出目录')
    parser.add_argument('--seed', type=int, default=0, help='起始随机种子')
    
    args = parser.parse_args()
    
    # 生成场景
    stats = generate_batch_scenes(
        num_scenes=args.num_scenes,
        output_dir=args.output_dir,
        seed_start=args.seed
    )
    
    # 绘制统计图表
    plot_statistics(stats, output_path=os.path.join(args.output_dir, 'statistics.png'))


if __name__ == '__main__':
    main()
