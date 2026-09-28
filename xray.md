
# PPTP Setup :

### Ubuntu 26 ( Resolute ) Packages : 

- https://archive.ubuntu.com/ubuntu/pool/main/p/ppp/ppp_2.5.2-1+1.2_amd64.deb
- https://archive.ubuntu.com/ubuntu/pool/main/p/pptp-linux/pptp-linux_1.10.0-2build1_amd64.deb

### Ubuntu 24 ( Noble ) Packages :

- https://archive.ubuntu.com/ubuntu/pool/main/p/ppp/ppp_2.4.9-1+1.1ubuntu4_amd64.deb
- https://archive.ubuntu.com/ubuntu/pool/main/p/pptp-linux/pptp-linux_1.10.0-1build4_amd64.deb

```bash
sudo su root --login
mkdir -p /root/downloads/

```

```bash
dpkg-query --show --showformat='${Status}' ppp
dpkg --install /root/downloads/ppp*.deb
dpkg-query --show --showformat='${Status}' pptp-linux
dpkg --install /root/downloads/pptp-linux*.deb
```

Edit `/etc/ufw/before.rules` :

Place above `COMMIT` line :

```bash
-A ufw-before-input -p 47 -s pptp_server_ip -j ACCEPT
```

Replace :

- `pptp_server_ip`

Create `/etc/ppp/peers/pptp-vpn` :

```text
pty "pptp pptp_server_ip --nolaunchpppd"
name pptp_username
password pptp_password
require-mschap-v2
refuse-mschap
refuse-chap
refuse-pap
refuse-eap
defaultroute
replacedefaultroute
usepeerdns
noauth
nodetach
```

Replace :

- `pptp_server_ip`
- `pptp_username`
- `pptp_password`

Create `/etc/systemd/system/pptp-vpn.service` :

```ini
[Unit]
Description=PPTP VPN
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/pppd call pptp-vpn
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl status pptp-vpn
systemctl start pptp-vpn
systemctl status pptp-vpn
systemctl enable pptp-vpn
```

# Ubuntu Setup :

Check `/etc/apt/sources.list.d/ubuntu.sources` :

```text
Types: deb
URIs: https://archive.ubuntu.com/ubuntu/
Suites: resolute resolute-updates
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://security.ubuntu.com/ubuntu/
Suites: resolute-security
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

```bash
apt update
apt upgrade
apt install curl ca-certificates
```

# Firewall Setup : 

### UFW :

```bash
systemctl status nftables
systemctl stop nftables
systemctl disable nftables
systemctl status nftables
nft flush ruleset
apt install ufw
ufw status verbose
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw enable
ufw status verbose
```

### Nftables :

```bash
ufw disable
systemctl status ufw
systemctl stop ufw
systemctl disable ufw
systemctl status ufw
ufw reset
apt install nftables
```

Edit `/etc/nftables.conf` :

```nft
#!/usr/sbin/nft --file
flush ruleset
include "/etc/nftables/conf.d/*.nft"
```

```bash
mkdir -p /etc/nftables/conf.d/
```

Create `/etc/nftables/conf.d/00-base.nft` :

```nft
table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        iifname "lo" accept
        ct state established,related accept
        ct state invalid drop
        ip protocol icmp icmp type echo-request limit rate 2/second burst 5 packets accept
        meta nfproto ipv6 drop
    }
    chain output {
        type filter hook output priority filter; policy accept;
        meta nfproto ipv6 drop
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
}
```

Create `/etc/nftables/conf.d/10-ssh.nft` :

```nft
add rule inet filter input tcp dport 22 accept
```

```bash
nft --check --file /etc/nftables.conf 
nft --file /etc/nftables.conf
nft list ruleset
systemctl status nftables
systemctl start nftables
systemctl status nftables
systemctl enable nftables
```

# Nginx Setup :

### UFW :

```bash
ufw status verbose
ufw allow 80/tcp
ufw allow 443/tcp
ufw status verbose
```

### Nftables :

Create `/etc/nftables/conf.d/11-nginx.nft` :

```nft
add rule inet filter input tcp dport 80 accept
add rule inet filter input tcp dport 443 accept
```

```bash
nft --check --file /etc/nftables.conf 
nft --file /etc/nftables.conf
nft list ruleset
```

### Ubuntu Repository :

```bash
apt install nginx
rm -rf /etc/nginx/sites-available/
rm -rf /etc/nginx/sites-enabled/
```

Remove below line from `/etc/nginx/nginx.conf` :

```nginx
include /etc/nginx/sites-enabled/*;
```

### Nginx Repository :

```bash
apt install --no-install-recommends gpg
mkdir -p /root/downloads/
curl -o /root/downloads/nginx.key https://nginx.org/keys/nginx_signing.key
file /root/downloads/nginx.key
gpg --dearmor --output /root/downloads/nginx-archive-keyring.pgp /root/downloads/nginx.key
rm /root/downloads/nginx.key
mv /root/downloads/nginx-archive-keyring.pgp /etc/apt/keyrings/nginx-archive-keyring.pgp
```

Create `/etc/apt/sources.list.d/nginx.sources` :

```text
Types: deb
URIs: https://nginx.org/packages/ubuntu
Suites: resolute
Components: nginx
Signed-By: /etc/apt/keyrings/nginx-archive-keyring.pgp
```

Create `/etc/apt/preferences.d/nginx.pref` :

```text
Package: *
Pin: release o=nginx
Pin-Priority: 900
```

```bash
dpkg-query --show --showformat='${Status}' nginx
apt purge nginx
apt autoremove --purge
```

```bash
apt update
apt install nginx
rm -f /etc/nginx/conf.d/default.conf
```

# TLS Setup :

```bash
apt install openssl
mkdir -p /root/tls/xyz.internal/
```

```bash
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out /root/tls/xyz.internal/internal-ca.key
certificate_serial=$(openssl rand -hex 16)
openssl req -new -sha256 -x509 -days 3650 -key /root/tls/xyz.internal/internal-ca.key -out /root/tls/xyz.internal/internal-ca.crt -subj "/CN=internal-ca" \
-set_serial "0x${certificate_serial}" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -addext "subjectKeyIdentifier=hash"
```

```bash
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out /root/tls/xyz.internal/xyz.internal.key
openssl req -new -sha256 -key /root/tls/xyz.internal/xyz.internal.key -out /root/tls/xyz.internal/xyz.internal.csr -subj "/CN=xyz.internal"
certificate_serial=$(openssl rand -hex 16)
cert_extensions=$(cat <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=serverAuth
subjectAltName=DNS:xyz.internal
EOF
)
openssl x509 -req -sha256 -days 3650 -CA /root/tls/xyz.internal/internal-ca.crt -CAkey /root/tls/xyz.internal/internal-ca.key -in /root/tls/xyz.internal/xyz.internal.csr \
-out /root/tls/xyz.internal/xyz.internal.crt -set_serial "0x${certificate_serial}" -extfile <(printf '%s' "$cert_extensions")
rm /root/tls/xyz.internal/xyz.internal.csr
```

```bash
openssl verify -CAfile /root/tls/xyz.internal/internal-ca.crt /root/tls/xyz.internal/xyz.internal.crt
cat /root/tls/xyz.internal/xyz.internal.crt /root/tls/xyz.internal/internal-ca.crt > /root/tls/xyz.internal/xyz.internal-fullchain.crt
mkdir -p /etc/nginx/xyz.internal/tls/
cp /root/tls/xyz.internal/xyz.internal.key /etc/nginx/xyz.internal/tls/xyz.internal.key
cp /root/tls/xyz.internal/xyz.internal-fullchain.crt /etc/nginx/xyz.internal/tls/xyz.internal-fullchain.crt
```

# Xray Install :

```bash
apt install unzip
curl -L -o xray-26.3.27.zip https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip
unzip xray-26.3.27.zip xray -d /usr/local/bin/
mkdir -p /var/log/xray/
touch /var/log/xray/access.log
chown nobody:nogroup /var/log/xray/access.log
chmod 600 /var/log/xray/access.log
touch /var/log/xray/error.log
chown nobody:nogroup /var/log/xray/error.log
chmod 600 /var/log/xray/error.log
mkdir -p /usr/local/etc/xray/conf.d/
mkdir -p /usr/local/etc/xray/transports/
```

Create `/usr/local/etc/xray/conf.d/00-log.json` :

```json
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    }
}
```

Create `/etc/systemd/system/xray.service` :

```ini
[Unit]
Description=xray
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run --confdir /usr/local/etc/xray/conf.d/
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
RuntimeDirectory=xray
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
```

# Dnscrypt Setup :

```bash
apt install dnscrypt-proxy bind9-dnsutils
```

Edit `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` :

Add below lines on top :

```toml
server_names = ['cloudflare']
listen_addresses = ['127.0.0.1:53']
ipv4_servers = true
doh_servers = true
require_dnssec = true
require_nofilter = true
ignore_system_dns = true
ipv6_servers = false
dnscrypt_servers = false
odoh_servers = false
block_ipv6 = true
cache = true
cache_size = 4096
```

```bash
dnscrypt-proxy -check -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
mkdir -p /etc/systemd/system/dnscrypt-proxy.service.d/
```

Create `/etc/systemd/system/dnscrypt-proxy.service.d/override.conf` :

```ini
[Service]
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

```bash
systemctl daemon-reload
systemctl restart dnscrypt-proxy
systemctl status dnscrypt-proxy
systemctl enable dnscrypt-proxy
dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml -resolve google.com
ss -lntup
dig @127.0.0.1 whoami.cloudflare ch txt +short
```

# Xray Server :

```bash
mkdir -p /etc/nginx/xyz.internal/conf.d/
mkdir -p /usr/local/etc/xray/nginx/
```

Create `/etc/nginx/conf.d/xyz.internal.conf` :

```nginx
server {
    listen 80;
    server_name xyz.internal;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    http2 on;
    server_name xyz.internal;
    ssl_certificate /etc/nginx/xyz.internal/tls/xyz.internal-fullchain.crt;
    ssl_certificate_key /etc/nginx/xyz.internal/tls/xyz.internal.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    include /etc/nginx/xyz.internal/conf.d/*.conf;
}
```

Create `/usr/local/etc/xray/nginx/xray-websocket.conf` :

```nginx
location = /xray/websocket {
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
    proxy_buffering off;
    proxy_request_buffering off;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:3000;
}
```

Create `/usr/local/etc/xray/nginx/xray-httpupgrade.conf` :

```nginx
location = /xray/httpupgrade {
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
    proxy_buffering off;
    proxy_request_buffering off;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:3000;
}
```

Create `/usr/local/etc/xray/nginx/xray-grpc.conf` :

```nginx
location /xray/grpc/ {
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size 0;
    client_body_timeout 3600s;
    grpc_read_timeout 3600s;
    grpc_send_timeout 3600s;
    grpc_pass grpc://127.0.0.1:3000;
}
```

Create `/usr/local/etc/xray/nginx/xray-xhttp-stream-one.conf` :

```nginx
location /xray/xhttp-stream-one/ {
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size 0;
    client_body_timeout 3600s;
    grpc_read_timeout 3600s;
    grpc_send_timeout 3600s;
    grpc_pass grpc://127.0.0.1:3000;
}
```

Create `/usr/local/etc/xray/nginx/xray-xhttp-stream-up.conf` :

```nginx
location /xray/xhttp-stream-up/ {
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size 0;
    client_body_timeout 3600s;
    grpc_read_timeout 3600s;
    grpc_send_timeout 3600s;
    grpc_pass grpc://127.0.0.1:3000;
}
```

Create `/usr/local/etc/xray/nginx/xray-xhttp-packet-up.conf` :

```nginx
location /xray/xhttp-packet-up/ {
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size 0;
    client_body_timeout 3600s;
    grpc_read_timeout 3600s;
    grpc_send_timeout 3600s;
    grpc_pass grpc://127.0.0.1:3000;
}
```

```bash
cp /usr/local/etc/xray/nginx/xray-websocket.conf /etc/nginx/xyz.internal/conf.d/
nginx -t
systemctl restart nginx
systemctl status nginx
ss -lntup
```

Create `/usr/local/etc/xray/conf.d/10-dns-server.json` :

```json
{
    "dns": {
        "disableCache": true ,
        "servers": [
            {
                "address": "127.0.0.1",
                "port": 53
            }
        ]
    }
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-websocket.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/xray/websocket"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-httpupgrade.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "httpupgrade",
                "security": "none",
                "httpupgradeSettings": {
                    "path": "/xray/httpupgrade"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-grpc.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "xray/grpc"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-xhttp-stream-one.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "security": "none",
                "xhttpSettings": {
                    "path": "/xray/xhttp-stream-one",
                    "mode": "stream-one"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-xhttp-stream-up.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "security": "none",
                "xhttpSettings": {
                    "path": "/xray/xhttp-stream-up",
                    "mode": "stream-up"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/20-inbound-server-xhttp-packet-up.json` :

```json
{
    "inbounds": [
        {
            "tag": "tunnel",
            "listen": "127.0.0.1",
            "port": 3000 ,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "security": "none",
                "xhttpSettings": {
                    "path": "/xray/xhttp-packet-up",
                    "mode": "packet-up"
                },
                "sockopt": {
                    "trustedXForwardedFor": [
                        "127.0.0.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/conf.d/30-outbound-server.json` :

```json
{
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom",
            "streamSettings": {
                "sockopt": {
                    "domainStrategy": "UseIP"
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/conf.d/40-routing-server.json` :

```json
{
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "outboundTag": "direct" ,
                "inboundTag": "tunnel"
            }
        ]
    }
}
```

```bash
cp /usr/local/etc/xray/transports/20-inbound-server-websocket.json /usr/local/etc/xray/conf.d/
xray uuid > /usr/local/etc/xray/vless-uuid.txt
cat /usr/local/etc/xray/vless-uuid.txt
```

Edit `/usr/local/etc/xray/conf.d/20-inbound-server-websocket.json` :

Place :

- `id` field

```bash
xray run --confdir /usr/local/etc/xray/conf.d/ --test
systemctl status xray 
systemctl start xray
systemctl status xray 
systemctl enable xray
ss -lntup
tar -c -f /root/xray-client.tar -C /usr/local/etc/xray vless-uuid.txt -C /root/tls/xyz.internal internal-ca.crt
```

# Xray Client :

### UFW :

```bash
ufw allow 8080/tcp
ufw deny out 443/udp
ufw status
```

### Nftables :

Create `/etc/nftables/conf.d/12-xray-client.nft` :

```nft
add rule inet filter output udp dport 443 drop
add rule inet filter input tcp dport 8080 accept
```

Edit `/etc/hosts` :

Add below line after last line : 

```text
xray_server_ip xyz.internal
```

Replace :

- `xray_server_ip`

```bash
getent ahostsv4 xyz.internal
ping xyz.internal
sftp root@xyz.internal
get xray-client.tar
mkdir /root/xray-client/
tar -x -f xray-client.tar -C /root/xray-client/
cp /root/xray-client/internal-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
curl https://xyz.internal/index.html
```

Create `/usr/local/etc/xray/conf.d/20-inbound-client.json` :

```json
{
    "inbounds": [
        {
            "tag": "http-proxy",
            "protocol": "http",
            "port": 8080 ,
            "settings": {
                "allowTransparent": false ,
                "accounts": [
                    {
                        "user": "user2",
                        "pass": "222"
                    }
                ]
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-websocket.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "websocket",
                "wsSettings": {
                    "path": "/xray/websocket"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-httpupgrade.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "httpupgrade",
                "httpupgradeSettings": {
                    "path": "/xray/httpupgrade"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-grpc.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": {
                    "serviceName": "xray/grpc"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "h2" ,
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-xhttp-stream-one.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "xhttpSettings": {
                    "path": "/xray/xhttp-stream-one",
                    "mode": "stream-one"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "h2" ,
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-xhttp-stream-up.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "xhttpSettings": {
                    "path": "/xray/xhttp-stream-up",
                    "mode": "stream-up"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "h2" ,
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/transports/30-outbound-client-xhttp-packet-up.json` :

```json
{
    "outbounds": [
        {
            "tag": "tunnel",
            "protocol": "vless",
            "targetStrategy": "AsIs",
            "settings": {
                "address": "xyz.internal",
                "port": 443,
                "id": "",
                "encryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "xhttpSettings": {
                    "path": "/xray/xhttp-packet-up",
                    "mode": "packet-up"
                },
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xyz.internal",
                    "fingerprint": "chrome",
                    "allowInsecure": false ,
                    "minVersion": "1.2",
                    "maxVersion": "1.3",
                    "alpn": [
                        "h2" ,
                        "http/1.1"
                    ]
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/conf.d/31-outbound-client-direct.json` :

```json
{
    "outbounds": [
        {
            "tag": "direct" ,
            "protocol": "freedom",
            "streamSettings": {
                "sockopt": {
                    "domainStrategy": "AsIs"
                }
            }
        }
    ]
}
```

Create `/usr/local/etc/xray/conf.d/40-routing-client-split-tunneling.json` :

```json
{
    "routing": {
        "domainStrategy": "AsIs" ,
        "rules": [
            {
                "outboundTag": "direct" ,
                "domain": [
                    "regexp:^(.*\\.)?abc\\.com$"
                ]
            },
            {
                "outboundTag": "direct" ,
                "ip": [
                    "10.0.0.0/8" ,
                    "172.16.0.0/12" ,
                    "192.168.0.0/16" ,
                    "100.64.0.0/10" ,
                    "169.254.0.0/16"
                ]
            },
            {
                "outboundTag": "tunnel" ,
                "inboundTag": "http-proxy"
            }
        ]
    }
}
```

```bash
cp /usr/local/etc/xray/transports/30-outbound-client-websocket.json /usr/local/etc/xray/conf.d/
cat /root/xray-client/vless-uuid.txt
```



nano /usr/local/etc/xray/conf.d/30-outbound-client-websocket.json ( add id field )

nano /usr/local/etc/xray/conf.d/40-routing-client-split-tunneling.json ( add local domain )

xray run --confdir /usr/local/etc/xray/conf.d/ --test

systemctl status xray 
systemctl start xray
systemctl status xray 
systemctl enable xray

ss -lntup

curl -v -x http://user2:222@127.0.0.1:8080 https://api.ipify.org

===========================================================================================================================================================================

# HTTP Proxy Client :

ufw deny out 443/udp

============================================================================================================================================================================

https://github.com/XTLS/Xray-examples/tree/main/VLESS-WSS-Nginx
https://github.com/XTLS/Xray-examples/tree/main/VLESS-TLS-SplitHTTP-CaddyNginx
https://github.com/XTLS/Xray-examples/tree/main/VLESS-XHTTP3-Nginx
https://github.com/XTLS/Xray-examples/tree/main/VLESS-GRPC
https://github.com/XTLS/Xray-examples/tree/main/All-in-One-fallbacks-Nginx
https://github.com/XTLS/Xray-examples/tree/main/Trojan-gRPC-Caddy2%EF%BC%8FNginx
https://github.com/lxhao61/integrated-examples/tree/main/Xray(VLESS%2BXHTTP)%2BNginx%5CCaddy
https://github.com/lxhao61/integrated-examples/tree/main/Xray(M%2BH%2BK%2BA)%2BNginx
https://github.com/lxhao61/integrated-examples/tree/main/Xray(M%2BF%2BH%2BK%2BA)%2BNginx
https://github.com/lxhao61/integrated-examples/blob/main/Xray(E%2BH%2BA)%2BNginx/
https://github.com/lxhao61/integrated-examples/blob/main/Xray(E%2BF%2BH%2BA)%2BNginx/
https://github.com/chika0801/Xray-examples/tree/main/VLESS-WebSocket_or_HTTPUpgrade-TLS
https://github.com/chika0801/Xray-examples/tree/main/VLESS-gRPC-TLS


xray server dns traffic hijack :

outbound :

{
    "tag": "dns-hijack",
    "protocol": "dns",
    "settings": {
        "rules": [
            {
                "action": "hijack"
            }
        ]
    }
}

routing :

"rules": [
    {
        "port": 53,
        "network": "tcp,udp",
        "outboundTag": "dns-hijack"
    }
]

