import random
import os
from datetime import datetime

def generate_gcp_commands(project_name, region, password, network_tier):
    regions = {
        # 美国区域
        "us-central1": { # 美国中部 (爱荷华州)
            "zone_prefix": "us-central1",
            "instance_names": ["usc1", "usc2", "usc3", "usc4"],
            "subnet_choice": "default"
        },
        "us-central2": { # 美国中部 (伊利诺伊州)
            "zone_prefix": "us-central2",
            "instance_names": ["usc21", "usc22", "usc23", "usc24"],
            "subnet_choice": "default"
        },
        "us-east1": { # 美国东部 (南卡罗来纳州)
            "zone_prefix": "us-east1",
            "instance_names": ["use1", "use2", "use3", "use4"],
            "subnet_choice": "default"
        },
        "us-east4": {
            "zone_prefix": "us-east4",
            "instance_names": ["use41", "use42", "use43", "use44"],
            "subnet_choice": "default"
        },
        "us-west1": { # 美国西部 (俄勒冈州)
            "zone_prefix": "us-west1",
            "instance_names": ["usw1", "usw2", "usw3", "usw4"],
            "subnet_choice": "default"
        },
        "us-west2": { # 美国西部 (洛杉矶)
            "zone_prefix": "us-west2",
            "instance_names": ["usw21", "usw22", "usw23", "usw24"],
            "subnet_choice": "default"
        },
        "us-west3": {
            "zone_prefix": "us-west3",
            "instance_names": ["usw31", "usw32", "usw33", "usw34"],
            "subnet_choice": "default"
        },
        "us-west4": {
            "zone_prefix": "us-west4",
            "instance_names": ["usw41", "usw42", "usw43", "usw44"],
            "subnet_choice": "default"
        },
        "us-northeast1": {
            "zone_prefix": "us-northeast1",
            "instance_names": ["usne1", "usne2", "usne3", "usne4"],
            "subnet_choice": "default"
        },
        "us-south1": {
            "zone_prefix": "us-south1",
            "instance_names": ["uss1", "uss2", "uss3", "uss4"],
            "subnet_choice": "default"
        },
        "us-south2": {
            "zone_prefix": "us-south2",
            "instance_names": ["uss21", "uss22", "uss23", "uss24"],
            "subnet_choice": "default"
        },

        # 欧洲区域
        "europe-west1": {
            "zone_prefix": "europe-west1",
            "instance_names": ["ew1", "ew2", "ew3", "ew4"],
            "subnet_choice": "default"
        },
        "europe-west2": {
            "zone_prefix": "europe-west2",
            "instance_names": ["ew21", "ew22", "ew23", "ew24"],
            "subnet_choice": "default"
        },
        "europe-west3": {
            "zone_prefix": "europe-west3",
            "instance_names": ["ew31", "ew32", "ew33", "ew34"],
            "subnet_choice": "default"
        },
        "europe-west4": {
            "zone_prefix": "europe-west4",
            "instance_names": ["ew41", "ew42", "ew43", "ew44"],
            "subnet_choice": "default"
        },
        "europe-west6": {
            "zone_prefix": "europe-west6",
            "instance_names": ["ew61", "ew62", "ew63", "ew64"],
            "subnet_choice": "default"
        },
        "europe-north1": {
            "zone_prefix": "europe-north1",
            "instance_names": ["en1", "en2", "en3", "en4"],
            "subnet_choice": "default"
        },

        # 亚太区域
        "asia-east1": { # 台湾
            "zone_prefix": "asia-east1",
            "instance_names": ["ae1", "ae2", "ae3", "ae4"],
            "subnet_choice": "default"
        },
        "asia-east2": { # 香港
            "zone_prefix": "asia-east2",
            "instance_names": ["ae21", "ae22", "ae23", "ae24"],
            "subnet_choice": "default"
        },
        "asia-northeast1": { # 日本 (东京)
            "zone_prefix": "asia-northeast1",
            "instance_names": ["ane1", "ane2", "ane3", "ane4"],
            "subnet_choice": "default"
        },
        "asia-northeast2": { # 日本 (大阪)
            "zone_prefix": "asia-northeast2",
            "instance_names": ["ane21", "ane22", "ane23", "ane24"],
            "subnet_choice": "default"
        },
        "asia-northeast3": { # 韩国
            "zone_prefix": "asia-northeast3",
            "instance_names": ["ane31", "ane32", "ane33", "ane34"],
            "subnet_choice": "default"
        },
        "asia-south1": { # 孟加拉国
            "zone_prefix": "asia-south1",
            "instance_names": ["as1", "as2", "as3", "as4"],
            "subnet_choice": "default"
        },
        "asia-southeast1": { # 新加坡
            "zone_prefix": "asia-southeast1",
            "instance_names": ["ase1", "ase2", "ase3", "ase4"],
            "subnet_choice": "default"
        },
        "asia-southeast2": { # 印尼
            "zone_prefix": "asia-southeast2",
            "instance_names": ["ase21", "ase22", "ase23", "ase24"],
            "subnet_choice": "default"
        },
        "australia-southeast1": { # 澳大利亚
            "zone_prefix": "australia-southeast1",
            "instance_names": ["aus1", "aus2", "aus3", "aus4"],
            "subnet_choice": "default"
        },

        # 南美区域
        "southamerica-east1": { # 巴西
            "zone_prefix": "southamerica-east1",
            "instance_names": ["sae1", "sae2", "sae3", "sae4"],
            "subnet_choice": "default"
        },

        # 北美区域
        "northamerica-northeast1": { # 加拿大
            "zone_prefix": "northamerica-northeast1",
            "instance_names": ["nan1", "nan2", "nan3", "nan4"],
            "subnet_choice": "default"
        },

        # 其他区域（如有）
        # 例如：asia-south2, europe-west5, etc.
    }

    zone_suffix_choices = ['a', 'b', 'c']

    # Validate region
    if region not in regions:
        raise ValueError("不支持的区域。请选择有效的GCP区域。")

    region_info = regions[region]

    # Create virtual machine instance commands with random suffix for each instance name
    instance_commands = ""
    for instance_name in region_info["instance_names"]:
        # Add random suffix to instance name
        random_instance_number = random.randint(1000, 9999)
        instance_name_with_suffix = f"{instance_name}-{random_instance_number}"

        # Randomly select a zone suffix
        zone_suffix = random.choice(zone_suffix_choices)
        full_zone = f"{region_info['zone_prefix']}-{zone_suffix}"

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
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p {password} && bash <(curl -sL https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \\
    --zone={full_zone} \\
    --project={project_name}
'''

    return instance_commands


def generate_script_filename():
    # 使用当前日期和时间生成唯一编号
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return f"create_instances_{timestamp}.sh"


# Get project name, region, password, and network tier
project_name = input("请输入项目名称：")  # 例如 famous-cursor-441805-n8
region = input("请输入区域（如 us-central1、asia-east1 等）：")
password = input("请输入自定义密码：")
network_tier = input("请选择网络类型（普通/高级）：").strip()

# Validate network tier input
if network_tier not in ["普通", "高级"]:
    raise ValueError("不支持的网络类型。请使用'普通'或'高级'。")
network_tier_value = 'STANDARD' if network_tier == '普通' else 'PREMIUM'

try:
    commands = generate_gcp_commands(project_name, region, password, network_tier_value)

    # Generate a unique script filename with timestamp
    script_filename = generate_script_filename()

    # Save commands to a shell script file
    with open(script_filename, "w") as f:
        f.write("#!/bin/bash\n\n")
        f.write(commands)

    # Make the script executable
    os.chmod(script_filename, 0o755)

    print(f"生成的GCP命令已保存到 {script_filename} 文件中。")
    print(f"您可以使用以下命令执行该脚本：\n./{script_filename}")
except ValueError as e:
    print(e)
