
```bash
dpkg-query --show --showformat='${Status}' openssh-server
apt install openssh-server
```

/etc/ssh/sshd_config :

/etc/ssh/sshd_config.d/00-hardening.conf :

AddressFamily inet
AllowGroups ssh_users
AuthenticationMethods password
PermitRootLogin no
DisableForwarding yes
DebianBanner no
PrintMotd no
ChannelTimeout session=15m
UnusedConnectionTimeout 1m
ClientAliveInterval 20
ClientAliveCountMax 3
Ciphers aes128-gcm@openssh.com
HostKeyAlgorithms ssh-ed25519
KexAlgorithms curve25519-sha256
MACs hmac-sha2-256-etm@openssh.com
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 1
MaxStartups 100:100:100
PerSourceMaxStartups 1
PerSourcePenalties authfail:15m noauth:15m grace-exceeded:15m refuseconnection:15m
Match Group *,!ssh_users
    RefuseConnection yes





https://wiki.nftables.org/wiki-nftables/index.php/Synproxy



tcp flooding , icmp flooding , http flooding




/etc/sysctl.d/10-syn-proxy.conf

net.netfilter.nf_conntrack_tcp_loose = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 1


sysctl --system




syn proxy for 22 , 80 , 443

table ip syn_proxy {
    chain prerouting {
        type filter hook prerouting priority -300; policy accept;
        tcp dport 22 tcp flags syn notrack
    }
    chain input {
        type filter hook input priority 0; policy accept;
        tcp dport 22 ct state invalid,untracked synproxy mss 1460 wscale 7 timestamp sack-perm
        ct state invalid drop
    }
}


use ( ct count ) with per source limiting new connections
limit number of simultaneous tcp connenctions from each source ip to port 22 , 80 , 443 tcp
1 simultaneous tcp connection to ssh
8 simultaneous connections to same http Host header for http
8 simultaneous connections to same sni for https

also define per source limit for icmp and icmpv6

tcp flags '& (fin|syn|rst|psh|ack|urg) == fin|psh|urg' drop



tcp flags & (fin|syn) == (fin|syn) drop
tcp flags & (syn|rst) == (syn|rst) drop
tcp flags & (fin|rst) == (fin|rst) drop
tcp flags & (fin|syn|rst|ack) == 0 drop







sshd -t
systemctl restart ssh










