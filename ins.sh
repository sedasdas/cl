#!/bin/bash
cd /root
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
bash <(curl -fsSL https://get.hy2.sh/)
rm h.tar
wget https://raw.githubusercontent.com/sedasdas/cl/refs/heads/main/h.tar
curl -L -o downloaded_file.tar.gz 'https://drive.google.com/uc?export=download&id=1xgi5NFO4hrqMEZjBQPqRePQYaU9L55ZM' && tar -zxvf downloaded_file.tar.gz  -C /etc/hysteria/
systemctl restart hysteria-server.service
systemctl enable hysteria-server.service
bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install
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
cat <<EOF > secrets.txt
admin root
EOF
cat <<EOF > start_gost
#!/bin/bash
#gost -L socks5+tls://:50210?secrets=/root/secrets.txt
gost -L 'https://admin:root@:50211'
#gost -L=ss://AEAD_CHACHA20_POLY1305:zxoking@:50213
EOF
chmod +x start_gost
systemctl daemon-reload
systemctl restart gost.service
systemctl enable gost.service
bash <(wget -qO- -o- https://git.io/v2ray.sh)
echo -e "3a44cffa-54d5-4b0f-8d6c-82045390e9fa\n" | v2ray id
echo -e "50233\n" | v2ray port
echo -e "2\n" | v2ray type
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo reboot
