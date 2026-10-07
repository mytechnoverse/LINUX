
# Configuration :

| Component          | Configuration |
|--------------------|---------------|
| **Linux Distro**   | Ubuntu        |
| **Distro Version** | 26 LTS        |
| **Memory**         | 2 GB          |
| **Processor**      | 2 Core        |
| **Storage**        | 16 GB         | 
| **User Name**      | Root          |
| **IP Protocol**    | IPv4          |
| **Firewall**       | Nftables      |
| **Proxy**          | Xray          |







# Xray Server :



### Nginx Setup :









Create `/etc/systemd/system/nginx.service.d/xyz.internal.conf` :

```ini
[Service]
LoadCredentialEncrypted=xyz.internal:/etc/nginx/xyz.internal/tls/xyz.internal.cred
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
    ssl_certificate_key /etc/nginx/xyz.internal/tls/xyz.internal.enc.key;
    ssl_password_file /run/credentials/nginx.service/xyz.internal;
    ssl_protocols TLSv1.2 TLSv1.3;
    include /etc/nginx/xyz.internal/conf.d/*.conf;
}
```



    location / {
        root /usr/share/nginx/html;
        index index.html;
    }


```bash
systemctl daemon-reload
systemctl status nginx
systemctl start nginx
systemctl status nginx
systemctl restart nginx
systemctl status nginx
systemctl enable nginx
systemctl status nginx
ss -lntup
```




