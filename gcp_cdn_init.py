import random

def generate_gcp_commands(project_name, region, password, network_tier):
    regions = {
        "香港": {
            "template_name": "instance-template-hk",
            "zone": "asia-east2-c",
            "instance_names": ["hk1", "hk2", "hk3", "hk4"],
            "subnet_choice": "3"
        },
        "台湾": {
            "template_name": "instance-template-tw",
            "zone": "asia-east1-c",
            "instance_names": ["tw1", "tw2", "tw3", "tw4"],
            "subnet_choice": "2"
        },
        "东京": {
            "template_name": "instance-template-dj",
            "zone": "asia-northeast1-b",
            "instance_names": ["dj1", "dj2", "dj3", "dj4"],
            "subnet_choice": "4"
        }
    }

    # Validate region
    if region not in regions:
        raise ValueError("不支持的区域。")

    region_info = regions[region]

    # Generate a random number for the template name suffix
    random_number = random.randint(100000, 999999)
    template_name_with_suffix = f"{region_info['template_name']}-{random_number}"

    # Create instance template command with network tier option
    template_command = f'''
gcloud compute instance-templates create {template_name_with_suffix} \\
    --machine-type=e2-micro \\
    --network-interface=network=default,network-tier={network_tier} \\
    --subnet=default \\
    --tags=http-server,https-server \\
    --image-family=debian-11 \\
    --image-project=debian-cloud \\
    --boot-disk-size=10GB \\
    --boot-disk-type=pd-balanced \\
    --boot-disk-auto-delete \\
    --labels=goog-ec-src=vm_add-gcloud
# 输入n,选{region_info["subnet_choice"]}
'''

    # Create virtual machine instance commands
    instance_commands = ""
    for instance_name in region_info["instance_names"]:
        instance_commands += f'''
gcloud compute instances create {instance_name} \\
    --source-instance-template={template_name_with_suffix} \\
    --zone={region_info["zone"]} \\
    --project={project_name} \\
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p {password} && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive'
'''

    return template_command + instance_commands


# Get project name, region, password, and network tier
project_name = input("请输入项目名称：")
region = input("请输入区域（香港/台湾/东京）：")
password = input("请输入自定义密码：")
network_tier = input("请选择网络类型（普通/高级）：").strip()

# Validate network tier input
if network_tier not in ["普通", "高级"]:
    raise ValueError("不支持的网络类型。请使用'普通'或'高级'。")
network_tier_value = 'STANDARD' if network_tier == '普通' else 'PREMIUM'

try:
    commands = generate_gcp_commands(project_name, region, password, network_tier_value)
    print(commands)
except ValueError as e:
    print(e)
