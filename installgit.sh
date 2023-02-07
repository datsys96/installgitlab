#!/bin/bash
cd /tmp
# apt install -y curl policycoreutils-python postfix ca-certificates wget curl openssl
# curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
# wget https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh

sudo apt-get update
sudo apt-get install -y curl  ca-certificates tzdata perl 
curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
bash script.deb.sh
apt -y install gitlab-ce

openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/ C = CN / ST = GD / L = SZ / O = Acme, Inc./CN=Acme Root CA " -out ca.crt
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/ C = CN / ST = GD / L = SZ / O = Acme, Inc./CN=*.gitlab.ltdat.store" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName = DNS: gitlab.ltdat.store, DNS: www.gitlab.ltdat.store, DNS: registry.gitlab.ltdat.store") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

mkdir -p /etc/gitlab/cert
cp /tmp/ca.* /etc/gitlab/cert
cp /tmp/server.* /etc/gitlab/cert
# cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak

EOF
cat <<EOF > /etc/gitlab/gitlab.rb
external_url 'https://gitlab.ltdat.store'
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
nginx['ssl_prefer_server_ciphers'] = "on"
nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"
registry_nginx['enable'] = true
registry_nginx['listen_port'] = 5050
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
# letsencrypt['enable'] = trueyesas contacts
# letsencrypt['auto_renew'] = true
# letsencrypt['auto_renew_hour'] = "12"
# letsencrypt['auto_renew_minute'] = "30" # Should be a number or cron expression, if specified.
# letsencrypt['auto_renew_day_of_month'] = "*/7"
EOF

gitlab-ctl reconfigure

