#!/bin/bash

# Function to configure system settings
configure_system() {
  echo "Configuring system settings..."
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  sysctl -p || { echo "Failed to apply sysctl settings"; exit 1; }
}

# Function to install hysteria server
install_hysteria() {
  echo "Installing Hysteria server..."
  bash <(curl -fsSL https://get.hy2.sh/) 
  rm -f h.tar
  wget -q https://raw.githubusercontent.com/sedasdas/cl/refs/heads/main/h.tar || { echo "Failed to download h.tar"; exit 1; }
  curl -L -o downloaded_file.tar.gz 'https://drive.google.com/uc?export=download&id=1xgi5NFO4hrqMEZjBQPqRePQYaU9L55ZM' || { echo "Failed to download Hysteria config"; exit 1; }
  tar -zxvf downloaded_file.tar.gz -C /etc/hysteria/ || { echo "Failed to extract Hysteria files"; exit 1; }
  systemctl restart hysteria-server.service
  systemctl enable hysteria-server.service
}

# Function to install GOST and configure its service
install_gost() {
  echo "Installing GOST..."
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install 

  echo "Creating GOST systemd service file..."
  cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=GOST
After=network.target

[Service]
ExecStart=/root/start_gost
User=root
LimitNOFILE=105536
Restart=always
#Type=forking

[Install]
WantedBy=multi-user.target
EOF

  echo "Creating GOST secrets file and start script..."
  cat <<EOF > /root/secrets.txt
admin root
EOF

  cat <<EOF > /root/start_gost
#!/bin/bash
#gost -L socks5+tls://:50210?secrets=/root/secrets.txt
gost -L 'https://admin:root@:50211'
#gost -L=ss://AEAD_CHACHA20_POLY1305:zxoking@:50213
EOF

  chmod +x /root/start_gost
  systemctl daemon-reload
  systemctl restart gost.service
  systemctl enable gost.service
}

# Function to install V2Ray
install_v2ray() {
  echo "Installing V2Ray..."
  bash <(wget -qO- -o- https://git.io/v2ray.sh) 

  echo "Configuring V2Ray..."
  echo -e "2\n" | v2ray type
  echo -e "3a44cffa-54d5-4b0f-8d6c-82045390e9fa\n" | v2ray id
   
  local port=50233
  if ss -tuln | grep -q ":$port"; then
    echo "Port $port is already in use. Skipping port configuration."
  else
    echo -e "$port\n" | v2ray port
  fi
  sed -i 's/IPOnDemand/AsIs/g'  /etc/v2ray/bin/config.json
  sed -i 's/IPIfNonMatch/AsIs/g' /etc/v2ray/config.json
  systemctl daemon-reload
  systemctl restart v2ray.service
}

# Function to create and enable swap
setup_swap() {
  echo "Setting up swap space..."
  sudo fallocate -l 1G /swapfile || { echo "Failed to create swapfile"; exit 1; }
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

# Main script execution
main() {
  echo "Starting setup script..."
  cd /root || { echo "Failed to change directory to /root"; exit 1; }
  setup_swap
  configure_system
  install_hysteria
  install_gost
  install_v2ray
  

  echo "Rebooting system..."
  
}

main
