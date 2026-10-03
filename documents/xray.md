
# Xray Install :

```bash
apt install curl ca-certificates file unzip
mkdir -p /root/downloads/
curl -L -o /root/downloads/xray.zip https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip
file /root/downloads/xray.zip
unzip /root/downloads/xray.zip xray -d /root/downloads/
file /root/downloads/xray
mv /root/downloads/xray /usr/local/bin/xray
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

# Xray Server :


### Xray Nginx Config :

```bash
mkdir -p /usr/local/etc/xray/nginx/
```

Create `/usr/local/etc/xray/nginx/xray-websocket.conf` :

```nginx
location = /xray_path/websocket {
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
location = /xray_path/httpupgrade {
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
location /xray_path/grpc/ {
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
location /xray_path/xhttp-stream-one/ {
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
location /xray_path/xhttp-stream-up/ {
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
location /xray_path/xhttp-packet-up/ {
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size 0;
    client_body_timeout 3600s;
    grpc_read_timeout 3600s;
    grpc_send_timeout 3600s;
    grpc_pass grpc://127.0.0.1:3000;
}
```

```bash
cp /usr/local/etc/xray/nginx/xray-xhttp-stream-up.conf /etc/nginx/xyz.internal/conf.d/
xray_path=$(openssl rand -hex 16)
```

Edit `/etc/nginx/xyz.internal/conf.d/xray-xhttp-stream-up.conf` :

Replace :

- `xray_path` : echo $xray_path 

```bash
systemctl restart nginx
systemctl status nginx
```

### Xray Josn Config :

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
                    "path": "/xray_path/websocket"
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
                    "path": "/xray_path/httpupgrade"
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
                    "serviceName": "xray_path/grpc"
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
                    "path": "/xray_path/xhttp-stream-one",
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
                    "path": "/xray_path/xhttp-stream-up",
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
                    "path": "/xray_path/xhttp-packet-up",
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
cp /usr/local/etc/xray/transports/20-inbound-server-xhttp-stream-up.json /usr/local/etc/xray/conf.d/
xray_id=$(xray uuid)
mkdir /root/xray-client/

```

Edit `/usr/local/etc/xray/conf.d/20-inbound-server-xhttp-stream-up.json` :

Place :

- `settings.clients.id`

```bash
xray run --confdir /usr/local/etc/xray/conf.d/ --test
systemctl status xray 
systemctl start xray
systemctl status xray 
systemctl enable xray
ss -lntup
tar -c -f /root/xray-client.tar -C /root/xray-client/ xray-id.txt -C /root/tls/internal-ca/ internal-ca.crt
```

# Xray Client :

Create `/etc/nftables/conf.d/11-xray-client.nft` :

```text
add rule inet filter input tcp dport 8080 accept
```

Append `/etc/hosts` :

```text
xray_server_ip xyz.internal
```

Replace :

- `xray_server_ip`

```bash
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
cat /root/xray-client/xray-id.txt
```

Edit `/usr/local/etc/xray/conf.d/30-outbound-client-websocket.json` :

Place :

- `settings.id`

Edit `/usr/local/etc/xray/conf.d/40-routing-client-split-tunneling.json` :

Replace :

- `regexp`

```bash
xray run --confdir /usr/local/etc/xray/conf.d/ --test
systemctl status xray 
systemctl start xray
systemctl status xray 
systemctl enable xray
ss -lntup
curl -v -x http://user2:222@127.0.0.1:8080 https://api.ipify.org
```

# Further Reading : 

- <https://github.com/XTLS/Xray-examples/tree/main/VLESS-WSS-Nginx>
- <https://github.com/XTLS/Xray-examples/tree/main/VLESS-TLS-SplitHTTP-CaddyNginx>
- <https://github.com/XTLS/Xray-examples/tree/main/VLESS-XHTTP3-Nginx>
- <https://github.com/XTLS/Xray-examples/tree/main/VLESS-GRPC>
- <https://github.com/XTLS/Xray-examples/tree/main/All-in-One-fallbacks-Nginx>
- <https://github.com/XTLS/Xray-examples/tree/main/Trojan-gRPC-Caddy2%EF%BC%8FNginx>
- <https://github.com/lxhao61/integrated-examples/tree/main/Xray(VLESS%2BXHTTP)%2BNginx%5CCaddy>
- <https://github.com/lxhao61/integrated-examples/tree/main/Xray(M%2BH%2BK%2BA)%2BNginx>
- <https://github.com/lxhao61/integrated-examples/tree/main/Xray(M%2BF%2BH%2BK%2BA)%2BNginx>
- <https://github.com/lxhao61/integrated-examples/blob/main/Xray(E%2BH%2BA)%2BNginx/>
- <https://github.com/lxhao61/integrated-examples/blob/main/Xray(E%2BF%2BH%2BA)%2BNginx/>
- <https://github.com/chika0801/Xray-examples/tree/main/VLESS-WebSocket_or_HTTPUpgrade-TLS>
- <https://github.com/chika0801/Xray-examples/tree/main/VLESS-gRPC-TLS>