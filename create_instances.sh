#!/bin/bash


gcloud compute instances create hk1-2577 \
    --machine-type=e2-micro \
    --network-interface=network=default,network-tier=PREMIUM,subnet=default \
    --tags=http-server,https-server \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-auto-delete \
    --labels=goog-ec-src=vm_add-gcloud \
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p @Micah.666 && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \
    --zone=asia-east2-c \
    --project=bubbly-operator-441502-u3

gcloud compute instances create hk2-9669 \
    --machine-type=e2-micro \
    --network-interface=network=default,network-tier=PREMIUM,subnet=default \
    --tags=http-server,https-server \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-auto-delete \
    --labels=goog-ec-src=vm_add-gcloud \
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p @Micah.666 && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \
    --zone=asia-east2-c \
    --project=bubbly-operator-441502-u3

gcloud compute instances create hk3-9981 \
    --machine-type=e2-micro \
    --network-interface=network=default,network-tier=PREMIUM,subnet=default \
    --tags=http-server,https-server \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-auto-delete \
    --labels=goog-ec-src=vm_add-gcloud \
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p @Micah.666 && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \
    --zone=asia-east2-c \
    --project=bubbly-operator-441502-u3

gcloud compute instances create hk4-3743 \
    --machine-type=e2-micro \
    --network-interface=network=default,network-tier=PREMIUM,subnet=default \
    --tags=http-server,https-server \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-auto-delete \
    --labels=goog-ec-src=vm_add-gcloud \
    --metadata=startup-script='sudo apt install -y curl && bash <(curl -sSL https://raw.githubusercontent.com/micah123321/shell-script/main/root_password.sh) -p @Micah.666 && bash <(curl -sL https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh) --non-interactive' \
    --zone=asia-east2-c \
    --project=bubbly-operator-441502-u3
