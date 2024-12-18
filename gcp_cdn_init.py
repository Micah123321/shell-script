import random
import os
from datetime import datetime
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 预设配置
PRESETS = {
    "1": {
        "name": "台湾高级网络",
        "region": "asia-east1",
        "network_tier": "PREMIUM",
    },
    "2": {
        "name": "香港普通网络",
        "region": "asia-east2", 
        "network_tier": "STANDARD",
    }
}

def get_country_code(region):
    """获取区域对应的国家编码"""
    country_codes = {
        # 亚洲
        "asia-east1": "tw",      # 台湾
        "asia-east2": "hk",      # 香港
        "asia-northeast1": "jp",  # 日本
        "asia-northeast2": "jp2", # 日本大阪
        "asia-northeast3": "kr",  # 韩国
        "asia-southeast1": "sg",  # 新加坡
        "asia-southeast2": "id",  # 印尼
        "asia-south1": "in",     # 印度
        
        # 美国
        "us-central1": "us-c1",  # 爱荷华
        "us-central2": "us-c2",  # 伊利诺伊
        "us-east1": "us-e1",     # 南卡罗来纳
        "us-east4": "us-e4",     # 弗吉尼亚
        "us-west1": "us-w1",     # 俄勒冈
        "us-west2": "us-w2",     # 洛杉矶
        "us-west3": "us-w3",     # 盐湖城
        "us-west4": "us-w4",     # 拉斯维加斯
        
        # 欧洲
        "europe-west1": "eu-w1", # 比利时
        "europe-west2": "eu-w2", # 伦敦
        "europe-west3": "eu-w3", # 法兰克福
        "europe-west4": "eu-w4", # 荷兰
        "europe-west6": "eu-w6", # 苏黎世
        "europe-north1": "eu-n1", # 芬兰
        
        # 其他地区
        "australia-southeast1": "au", # 澳大利亚
        "southamerica-east1": "br",  # 巴西
        "northamerica-northeast1": "ca", # 加拿大
    }
    return country_codes.get(region, region[:2])

def generate_instance_name(region, network_tier, instance_base):
    """生成新的实例名称格式"""
    # 获取国家/地区编码
    country = get_country_code(region)
    
    # 网络类型缩写
    net_type = "p" if network_tier == "PREMIUM" else "s"
    
    # 生成时间戳
    timestamp = datetime.now().strftime("%m%d%H%M")
    
    # 生成4位随机数
    random_suffix = str(random.randint(1000, 9999))
    
    # 组合新的实例名称: 国家-网络-日期时间-随机数
    return f"{country}-{net_type}-{timestamp}-{random_suffix}"

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
        "us-west2": { # 美国西部 (洛杉��)
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

    if region not in regions:
        raise ValueError("不支持的区域。请选择有效的GCP区域。")

    region_info = regions[region]

    instance_commands = ""
    for instance_name in region_info["instance_names"]:
        # 使用新的命名方式
        instance_name_with_suffix = generate_instance_name(region, network_tier, instance_name)
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

def generate_script_filename(region, network_tier):
    # 确保输出目录存在
    output_dir = "gcp_scripts"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 生成带时间戳��配置信息的文件名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    network_type = "premium" if network_tier == "PREMIUM" else "standard"
    return os.path.join(output_dir, f"{region}_{network_type}_{timestamp}.sh")

def show_menu():
    print("\n=== GCP 实例创建预设菜单 ===")
    print("预设选项:")
    for key, preset in PRESETS.items():
        print(f"{key}. {preset['name']}")
    print("3. 自定义区域和网络")
    return input("\n请选择预设选项 (1-3): ")

def main():
    # 获取项目名称
    project_name = input("请输入项目名称：")  # 例如 famous-cursor-441805-n8
    
    # 显示菜单并获取选择
    choice = show_menu()
    
    # 从环境变量获取默认密码，如果未设置则使用默认值
    password = os.getenv('GCP_DEFAULT_PASSWORD', 'Aa112211')
    
    if choice in PRESETS:
        # 使用预设配置
        preset = PRESETS[choice]
        region = preset["region"]
        network_tier = preset["network_tier"]
        print(f"\n使用预设: {preset['name']}")
        
    elif choice == "3":
        # 自定义配置
        region = input("请输入区域（如 us-central1、asia-east1 等）：")
        network_tier_input = input("请选择网络类型（普通/高级）：").strip()
        if network_tier_input not in ["普通", "高级"]:
            raise ValueError("不支持的网络类型。请使用'普通'或'高级'。")
        network_tier = 'STANDARD' if network_tier_input == '普通' else 'PREMIUM'
    else:
        print("无效的选择！")
        return

    try:
        commands = generate_gcp_commands(project_name, region, password, network_tier)
        script_filename = generate_script_filename(region, network_tier)

        # 保存命令到shell脚本文件
        with open(script_filename, "w") as f:
            f.write("#!/bin/bash\n\n")
            f.write(commands)

        # 设置脚本可执行权限
        os.chmod(script_filename, 0o755)

        # 显示相对路径
        relative_path = os.path.relpath(script_filename)
        print(f"\n生成的GCP命令已保存到 {relative_path} 文件中。")
        print(f"您可以使用以下命令执行该脚本：\n./{relative_path}")
        
    except ValueError as e:
        print(f"错误: {e}")
    except OSError as e:
        print(f"文件操作错误: {e}")

if __name__ == "__main__":
    main()
