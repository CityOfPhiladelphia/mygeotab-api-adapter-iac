#!/bin/bash
export APP_NAME=$1
export ENV_NAME=$2
# Load secrets and parameters
export RDS_HOST=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_host" --query "Parameter.Value" --output text)
export RDS_DB=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_service_db_name" --query "Parameter.Value" --output text)
export RDS_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_service_user" --with-decryption --query "Parameter.Value" --output text)
export RDS_PW=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/rds_service_pw" --with-decryption --query "Parameter.Value" --output text)
export GEOTAB_DB=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/geotab_db" --query "Parameter.Value" --output text)
export GEOTAB_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/geotab_user" --with-decryption --query "Parameter.Value" --output text)
export GEOTAB_PW=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/geotab_pw" --with-decryption --query "Parameter.Value" --output text)
export AUTOMATIC_START=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/enable_auto_start" --query "Parameter.Value" --output text)
export APP_VERSION=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/app_version" --query "Parameter.Value" --output text)
# Set hostname to `app-env-{old hostname}`
sudo hostnamectl hostname "${APP_NAME}.${ENV_NAME}-$(hostnamectl hostname)"
sudo timedatectl set-timezone America/New_York
# Update DNS server (don't know why I need to do this manually)
# Otherwise can't resolve phila.city domains
sudo resolvectl domain ens5 city.phila.local
sudo resolvectl dns ens5 170.115.97.22 170.115.97.23
# Install dependencies
sudo dnf install -y libicu postgresql15 cronie
# Create geotab user
sudo useradd geotab-api-adapter
sudo mkdir /opt/geotab
cd /opt/geotab || exit
sudo chown -R geotab-api-adapter:geotab-api-adapter /opt/geotab
# Download geotab
sudo -u geotab-api-adapter wget "https://github.com/Geotab/mygeotab-api-adapter/releases/download/$APP_VERSION/MyGeotabAPIAdapter_SCD_linux-x64.zip"
sudo -u geotab-api-adapter unzip MyGeotabAPIAdapter_SCD_linux-x64
sudo -u geotab-api-adapter chmod +x ./MyGeotabAPIAdapter_SCD_linux-x64/MyGeotabAPIAdapter
envsubst <"/home/ec2-user/${APP_NAME}-iac/server/templates/appsettings.json" | sudo -u geotab-api-adapter tee ./MyGeotabAPIAdapter_SCD_linux-x64/appsettings.json >/dev/null
sudo cp "/home/ec2-user/${APP_NAME}-iac/server/templates/mygeotabadapter.service" /etc/systemd/system/mygeotabadapter.service

# Enable and start geotab service
sudo systemctl enable mygeotabadapter
if [[ "$AUTOMATIC_START" == "yes" ]]; then
  sudo systemctl start mygeotabadapter
fi

# Create .pgpass file for easy psql
echo "$RDS_HOST:5432:$RDS_DB:$RDS_USER:$RDS_PW" >/home/ec2-user/.pgpass
chmod 600 /home/ec2-user/.pgpass
echo "psql -h $RDS_HOST -d $RDS_DB -U $RDS_USER" >/home/ec2-user/connect-db.sh
chmod +x /home/ec2-user/connect-db.sh
sudo cp /home/ec2-user/.pgpass /root/.pgpass
sudo cp /home/ec2-user/connect-db.sh /root/connect-db.sh

# Setup auto restarter
# shellcheck disable=SC2016
envsubst '$RDS_HOST $RDS_DB $RDS_USER' <"/home/ec2-user/${APP_NAME}-iac/server/templates/auto_restarter.sh" | sudo tee /root/auto_restarter.sh
sudo chmod u+x /root/auto_restarter.sh
echo "* * * * * root /root/auto_restarter.sh" | sudo tee /etc/cron.d/geotab_auto_restarter
sudo systemctl start crond
sudo systemctl enable crond

# Limit journal size to 1gb (default is 4gb which is probably fine)
echo "SystemMaxFileSize=1G" | sudo tee -a /etc/systemd/journald.conf
echo "SystemMaxUse=1G" | sudo tee -a /etc/systemd/journald.conf
sudo systemctl restart systemd-journald

# Install alloy for monitoring
# Alloy cannot be installed until its gpg key is imported
cd "/home/ec2-user/${APP_NAME}-iac/server" || exit
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key
echo -e '[grafana]\nname=grafana\nbaseurl=https://rpm.grafana.com\nrepo_gpgcheck=1\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.grafana.com/gpg.key\nsslverify=1\nsslcacert=/etc/pki/tls/certs/ca-bundle.crt' | sudo tee /etc/yum.repos.d/grafana.repo
# Install alloy
sudo yum update -y
sudo dnf install -y alloy
# Copy our config into the right file
sudo cp alloy/config.alloy.hcl /etc/alloy/config.alloy
# Get environment variables for alloy
export LOKI_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/loki_user" --with-decryption --query "Parameter.Value" --output text)
export LOKI_PASSWORD=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/loki_pw" --with-decryption --query "Parameter.Value" --output text)
export PROMETHEUS_USER=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/prometheus_user" --with-decryption --query "Parameter.Value" --output text)
export PROMETHEUS_PASSWORD=$(aws ssm get-parameter --name "/$APP_NAME/$ENV_NAME/prometheus_pw" --with-decryption --query "Parameter.Value" --output text)
# Write them to alloy's env file
echo "LOKI_USER=$LOKI_USER" | sudo tee -a /etc/sysconfig/alloy >/dev/null
echo "LOKI_PASSWORD=$LOKI_PASSWORD" | sudo tee -a /etc/sysconfig/alloy >/dev/null
echo "PROMETHEUS_USER=$PROMETHEUS_USER" | sudo tee -a /etc/sysconfig/alloy >/dev/null
echo "PROMETHEUS_PASSWORD=$PROMETHEUS_PASSWORD" | sudo tee -a /etc/sysconfig/alloy >/dev/null
echo "APP_NAME=$APP_NAME" | sudo tee -a /etc/sysconfig/alloy >/dev/null
echo "ENV_NAME=$ENV_NAME" | sudo tee -a /etc/sysconfig/alloy >/dev/null
# Start alloy!
sudo systemctl start alloy
sudo systemctl enable alloy.service
