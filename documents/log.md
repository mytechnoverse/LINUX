


```bash
dpkg-query --show --showformat='${Status}' systemd
apt install systemd
dpkg-query --show --showformat='${Status}' rsyslog
apt install rsyslog
dpkg-query --show --showformat='${Status}' socat
apt install socat
```

systemctl status systemd-journald
systemctl start systemd-journald
systemctl status systemd-journald
systemctl enable systemd-journald

Create `/etc/systemd/journald.conf.d/00-persistent-logs.conf` :

[Journal]
Storage=persistent
SystemMaxUse=1G
SystemMaxFileSize=128M
SplitMode=none
MaxFileSec=0
SystemKeepFree=0
ForwardToWall=no

mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald
journalctl --flush

ls -lha /var/log/journal/
journalctl --disk-usage


https://manpages.debian.org/trixie/systemd/journalctl.1.en.html#FORWARD_SECURE_SEALING_(FSS)_OPTIONS
https://manpages.debian.org/trixie/systemd/journald@.conf.5.en.html ( Seal= )


















use rsyslog to send encrypted logs ( syslog over tcp over tls ) or ( RELP over TLS )
xray forwards them to the rsyslog server . rsyslog server pushes them to loki and wazuh manager

generate a CA and sign a certificate for rsyslog server for connection between client and rsyslog be encrypted 

each application like ssh , nginx , ... should be checked for log collection
either through specific file , ...
check that a single log is not sent twice through both systemd and rsyslog 

remote vps sending tcp logs through http proxy :
socat TCP-LISTEN:6514,bind=127.0.0.1,reuseaddr,fork PROXY:127.0.0.1:rsyslog.internal:6514,proxyport=8080


/etc/systemd/system/syslog-proxy-tunnel.service

[Unit]
Description=syslog proxy tunnel
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:6514,bind=127.0.0.1,reuseaddr,fork PROXY:127.0.0.1:rsyslog.internal:6514,proxyport=8080
Restart=always
RestartSec=5s

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable --now syslog-proxy-tunnel
sudo systemctl status syslog-proxy-tunnel

/etc/rsyslog.d/00-remote-forward.conf :

global(
workDirectory="/var/spool/rsyslog"
)

action(
type="omfwd"
target="127.0.0.1"
port="6514"
protocol="tcp"

```
StreamDriver="ossl"
StreamDriverMode="1"
StreamDriverAuthMode="x509/name"
StreamDriverPermittedPeers="rsyslog.internal"
StreamDriver.CAFile="/etc/ssl/certs/ca-certificates.crt"

action.resumeRetryCount="-1"
action.resumeInterval="10"

queue.type="LinkedList"
queue.filename="remote-syslog"
queue.maxDiskSpace="1g"
queue.saveOnShutdown="on"
```

)

rsyslogd -N1
systemctl restart rsyslog
logger -t tunnel-test "Testing remote syslog forwarding"









socks is more efficient maybe ???




systemctl status rsyslog
systemctl start rsyslog
systemctl status rsyslog
systemctl enable rsyslog









Forward Secure Sealing (FSS) ???