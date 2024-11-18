import random
import os

def generate_gcp_commands(project_name, region, password, network_tier):
    regions = {
        "香港": {
            "zone": "asia-east2-c",
            "instance_names": ["hk1", "hk2", "hk3", "hk4"],
            "subnet_choice": "default"
        },
        "台湾": {
            "zone": "asia-east1-c",
            "instance_names": ["tw1", "tw2", "tw3", "tw4"],
            "subnet_choice": "default"
        },
        "东京": {
            "zone": "asia-northeast1-b",
            "instance_names": ["dj1", "dj2", "dj3", "dj4"],
            "subnet_choice": "default"
        }
    }

    # Validate region
    if region not in regions:
        raise ValueError("不支持的区域。请选择香港、台湾或东京。")

    region_info = regions[region]

    # Create virtual machine instance commands with random suffix for each instance name
    instance_commands = ""
    for instance_name in region_info["instance_names"]:
        # Add random suffix to instance name
        random_instance_number = random.randint(1000, 9999)
        instance_name_with_suffix = f"{instance_name}-{random_instance_number}"

        instance_commands += f'''
gcloud compute instances create {instance_name_with_suffix} \\
    --machine-type=e2-micro \\
    --network-interface=network=default,network-tier={network_tier},subnet={region_info["subnet_choice"]} \\
    --tags=http-server,https-server \\
    --image-family=debian-11 \\
    --image-project=debian-cloud \\
    --boot-disk-size=10GB \\
    --boot-disk-type=pd-balanced \\
    --boot-disk-auto-delete \\
    --labels=goog-ec-src=vm_add-gcloud \\
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p {password} && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \\
    --zone={region_info["zone"]} \\
    --project={project_name}
'''
    return instance_commands

# Get project name, region, password, and network tier
project_name = input("请输入项目名称：")  # 例如 famous-cursor-441805-n8
region = input("请输入区域（香港/台湾/东京）：")
password = input("请输入自定义密码：")
network_tier = input("请选择网络类型（普通/高级）：").strip()

# Validate network tier input
if network_tier not in ["普通", "高级"]:
    raise ValueError("不支持的网络类型。请使用'普通'或'高级'。")
network_tier_value = 'STANDARD' if network_tier == '普通' else 'PREMIUM'

try:
    commands = generate_gcp_commands(project_name, region, password, network_tier_value)

    # Save commands to a shell script file
    script_filename = "create_instances.sh"
    with open(script_filename, "w") as f:
        f.write("#!/bin/bash\n\n")
        f.write(commands)

    # Make the script executable
    os.chmod(script_filename, 0o755)

    print(f"生成的GCP命令已保存到 {script_filename} 文件中。")
    print(f"您可以使用以下命令执行该脚本：\n./{script_filename}")
except ValueError as e:
    print(e)
