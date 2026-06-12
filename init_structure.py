import os

def list_files_tree(startpath, indent=""):
    """以树状结构递归列举目录和文件"""
    if not os.path.exists(startpath):
        print(f"路径不存在: {startpath}")
        return

    # 获取当前目录下的所有文件和文件夹，并排序（让输出更有序）
    try:
        items = sorted(os.listdir(startpath))
    except PermissionError:
        # 遇到没有权限访问的文件夹时跳过
        return

    # 过滤掉隐藏文件/文件夹（以 . 开头的）
    items = [item for item in items if not item.startswith('.')]

    for i, item in enumerate(items):
        path = os.path.join(startpath, item)
        is_last = (i == len(items) - 1)
        
        # 分支符号：最后一个元素用 └──，其余用 ├──
        marker = "└── " if is_last else "├── "
        print(f"{indent}{marker}{item}")
        
        # 如果是文件夹，则递归进入
        if os.path.isdir(path):
            next_indent = indent + ("    " if is_last else "│   ")
            list_files_tree(path, next_indent)

# ─── 使用方法 ───
# 将下面的路径替换为您想要查看的本地电脑文件夹路径（例如 'D:\\Projects' 或 '/Users/username/Documents'）
target_directory = "."  # "." 代表当前运行代码的目录
print(f"📂 正在列举目录: {os.path.abspath(target_directory)}")
list_files_tree(target_directory)