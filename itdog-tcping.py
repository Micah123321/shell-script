import hashlib

def generate_task_token(task_id: str) -> str:
    """
    正确的task token生成算法:
    1. 使用task_id + 固定salt字符串"spm00yo5"
    2. 计算md5值并取前16位
    """
    # 固定的salt值
    salt = "spm00yo5"

    # 拼接原始字符串
    message = f"{task_id}{salt}"

    # 计算MD5值并取前16位
    md5_hash = hashlib.md5(message.encode()).hexdigest()[:16]

    return md5_hash

# 使用示例
task_id = "202411160309001tupqrrgonop56bkod"
token = generate_task_token(task_id)
print(f"Generated token: {token}")  # 输出: 4f03ae8d0af64134
