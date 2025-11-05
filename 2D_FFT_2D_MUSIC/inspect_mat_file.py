"""
检查 .mat 文件内容的工具脚本
用于验证保存的场景数据是否正确
"""

import scipy.io as sio
import numpy as np
import sys


def inspect_mat_file(mat_path):
    """
    检查 .mat 文件内容
    
    参数：
    - mat_path: .mat 文件路径
    """
    print("=" * 70)
    print(f"检查 MAT 文件: {mat_path}")
    print("=" * 70)
    
    # 加载 .mat 文件
    data = sio.loadmat(mat_path)
    
    # 过滤掉 MATLAB 内部变量
    keys = [k for k in data.keys() if not k.startswith('__')]
    
    print(f"\n顶层键 ({len(keys)}):")
    for key in keys:
        print(f"  - {key}")
    
    # 显示场景信息
    if 'scene_id' in data:
        print(f"\n场景 ID: {data['scene_id'][0][0]}")
    
    # 显示对象计数
    if 'object_counts' in data:
        counts = data['object_counts']
        print(f"\n对象计数:")
        for field in counts.dtype.names:
            print(f"  - {field}: {counts[field][0][0][0][0]}")
    
    # 显示散射点信息
    if 'scatterers' in data:
        scatterers = data['scatterers']
        print(f"\n散射点信息:")
        for field in scatterers.dtype.names:
            arr = scatterers[field][0][0]
            print(f"  - {field}: shape={arr.shape}, dtype={arr.dtype}")
            if arr.shape[0] > 0:
                print(f"    示例数据: {arr[0]}")
    
    # 显示车辆信息
    if 'vehicles' in data:
        vehicles = data['vehicles']
        print(f"\n车辆信息:")
        for field in vehicles.dtype.names:
            arr = vehicles[field][0][0]
            print(f"  - {field}: shape={arr.shape}, dtype={arr.dtype}")
    
    # 显示行人信息
    if 'pedestrians' in data:
        pedestrians = data['pedestrians']
        print(f"\n行人信息:")
        for field in pedestrians.dtype.names:
            arr = pedestrians[field][0][0]
            print(f"  - {field}: shape={arr.shape}, dtype={arr.dtype}")
    
    # 显示隔离带信息
    if 'barrier' in data:
        barrier = data['barrier']
        print(f"\n隔离带信息:")
        for field in barrier.dtype.names:
            val = barrier[field][0][0]
            if isinstance(val, np.ndarray):
                if val.size <= 3:
                    print(f"  - {field}: {val.flatten()}")
                else:
                    print(f"  - {field}: shape={val.shape}")
            else:
                print(f"  - {field}: {val}")
    
    # 显示路灯信息
    if 'lights' in data:
        lights = data['lights']
        print(f"\n路灯信息:")
        for field in lights.dtype.names:
            arr = lights[field][0][0]
            print(f"  - {field}: shape={arr.shape}")
            if arr.shape[0] <= 3:
                print(f"    数据: {arr}")
    
    # 显示配置信息
    if 'config' in data:
        config = data['config']
        print(f"\n配置信息:")
        for field in config.dtype.names:
            val = config[field][0][0]
            if isinstance(val, np.ndarray):
                print(f"  - {field}: {val.flatten()}")
            else:
                print(f"  - {field}: {val}")
    
    print("\n" + "=" * 70)


def inspect_summary_file(mat_path):
    """
    检查汇总 .mat 文件
    
    参数：
    - mat_path: summary.mat 文件路径
    """
    print("=" * 70)
    print(f"检查汇总 MAT 文件: {mat_path}")
    print("=" * 70)
    
    data = sio.loadmat(mat_path)
    
    # 过滤掉 MATLAB 内部变量
    keys = [k for k in data.keys() if not k.startswith('__')]
    
    print(f"\n顶层键 ({len(keys)}):")
    for key in keys:
        val = data[key]
        if isinstance(val, np.ndarray):
            print(f"  - {key}: shape={val.shape}, dtype={val.dtype}")
            if val.shape[0] <= 20 and val.ndim == 1:
                print(f"    数据: {val}")
        else:
            print(f"  - {key}: {val}")
    
    print("\n" + "=" * 70)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='检查 .mat 文件内容')
    parser.add_argument('mat_file', type=str, help='.mat 文件路径')
    parser.add_argument('--summary', action='store_true', help='是否为汇总文件')
    
    args = parser.parse_args()
    
    if args.summary:
        inspect_summary_file(args.mat_file)
    else:
        inspect_mat_file(args.mat_file)


if __name__ == '__main__':
    main()
