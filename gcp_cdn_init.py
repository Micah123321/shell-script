def generate_gcp_commands(project_name, region, password):
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

    # 根据传入的区域生成命令
    if region not in regions:
        raise ValueError("不支持的区域。")

    region_info = regions[region]

    # 创建实例模板命令
    template_command = f'''
gcloud compute instance-templates create {region_info["template_name"]} \\
    --machine-type=e2-micro \\
    --network=default \\
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

    # 创建虚拟机实例命令
    instance_commands = ""
    for instance_name in region_info["instance_names"]:
        instance_commands += f'''
gcloud compute instances create {instance_name} \\
    --source-instance-template={region_info["template_name"]} \\
    --zone={region_info["zone"]} \\
    --project={project_name} \\
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p {password}'
'''

    return template_command + instance_commands


# 获取项目名称、区域和密码
project_name = input("请输入项目名称：")
region = input("请输入区域（香港/台湾/东京）：")
password = input("请输入自定义密码：")

try:
    commands = generate_gcp_commands(project_name, region, password)
    print(commands)
except ValueError as e:
    print(e)
