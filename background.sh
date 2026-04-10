#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Base tools
apt-get update -qq >/dev/null
apt-get install -y -qq procps psmisc tree nano cron >/dev/null

# Create learner user
id -u analyst >/dev/null 2>&1 || useradd -m -s /bin/bash analyst
mkdir -p /home/analyst/{Desktop,Downloads,scripts,projects,investigation}
chown -R analyst:analyst /home/analyst

# Normal-looking clutter
cat > /home/analyst/Desktop/todo.txt <<'EOF'
- check backup script
- clean downloads
- review nginx notes later
EOF

echo "meeting moved to friday" > /home/analyst/Downloads/notes-old.txt
cat > /home/analyst/scripts/backup.sh <<'EOF'
#!/bin/bash
tar -czf /var/backups/analyst-home.tgz /home/analyst
EOF
cp /home/analyst/scripts/backup.sh /home/analyst/scripts/backup.sh.bak
chmod +x /home/analyst/scripts/backup.sh /home/analyst/scripts/backup.sh.bak
mkdir -p /srv/app /opt/tools /var/backups /var/tmp /etc/nginx

echo "server started" > /srv/app/app.log
cat > /opt/tools/cleanup-helper.sh <<'EOF'
#!/bin/bash
echo "cleaning temporary files"
EOF
chmod +x /opt/tools/cleanup-helper.sh
cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
events { worker_connections 768; }
http { include /etc/nginx/mime.types; default_type application/octet-stream; }
EOF

# Suspicious user and artifacts
id -u hacker >/dev/null 2>&1 || useradd -m -s /bin/bash hacker
mkdir -p /home/hacker/.cache
cat > /home/hacker/.note.txt <<'EOF'
cleanup script runs from tmp...
EOF
cat > /home/hacker/.cache/readme.md <<'EOF'
Remember to check shell startup files if the process comes back.
EOF

# Malicious script and persistence
cat > /tmp/.miner.sh <<'EOF'
#!/bin/bash
while true; do
  sleep 1000
done
EOF
chmod +x /tmp/.miner.sh
if ! grep -q '/tmp/.miner.sh' /home/analyst/.bashrc 2>/dev/null; then
  echo 'bash /tmp/.miner.sh >/dev/null 2>&1 &' >> /home/analyst/.bashrc
fi

# Red herring hidden file
cat > /home/analyst/.cache_cleaner.sh <<'EOF'
#!/bin/bash
find /tmp -type f -mtime +7 -delete
EOF
chmod +x /home/analyst/.cache_cleaner.sh

# Weak permission file
cat > /home/analyst/finance.txt <<'EOF'
Q2 provisional budget
do not share outside finance
EOF
chmod 777 /home/analyst/finance.txt

# Extra junk / red herrings
for f in install.log update.cache session.tmp app.tmp old.conf report.old notes.bak; do
  touch "/tmp/$f"
done
mkdir -p /home/analyst/projects/demo-app/{src,logs,tmp}
for i in $(seq 1 25); do echo "INFO boot message $i" >> /home/analyst/projects/demo-app/logs/app.log; done
for i in $(seq 1 10); do touch "/home/analyst/projects/demo-app/tmp/file$i.tmp"; done

# Suspicious process with believable name
cp /bin/sleep /tmp/crypto_miner
chmod +x /tmp/crypto_miner
pkill -f '/tmp/crypto_miner 1000' >/dev/null 2>&1 || true
nohup /tmp/crypto_miner 1000 >/dev/null 2>&1 &

# Command history
cat > /home/analyst/.bash_history <<'EOF'
ls
cd /tmp
cat /var/tmp/readme.txt
ps aux | grep miner
nano ~/.bashrc
find /tmp -type f
EOF

# Clue trail
cat > /var/tmp/readme.txt <<'EOF'
Noise is everywhere. Check tmp, hidden files, and shell startup files.
EOF

# Logs: auth and syslog style noise with one useful clue
mkdir -p /var/log/nginx
cat > /var/log/auth.log <<'EOF'
Apr 10 08:12:11 lab sshd[1001]: Accepted password for analyst from 10.0.2.2 port 55220 ssh2
Apr 10 08:14:02 lab sudo:   analyst : TTY=pts/0 ; PWD=/home/analyst ; USER=root ; COMMAND=/usr/bin/apt update
Apr 10 08:20:31 lab sshd[1099]: Failed password for invalid user admin from 185.22.44.10 port 44012 ssh2
Apr 10 08:21:01 lab sshd[1102]: Failed password for invalid user test from 185.22.44.10 port 44018 ssh2
Apr 10 08:24:55 lab useradd[1200]: new user: name=hacker, UID=1001, GID=1001, home=/home/hacker, shell=/bin/bash
EOF

: > /var/log/syslog
for i in $(seq 1 180); do
  printf 'Apr 10 09:%02d:00 lab systemd[1]: Started harmless-service-%d.\n' $((i % 60)) "$i" >> /var/log/syslog
 done
printf 'Apr 10 10:31:00 lab analyst-shell[4555]: startup command sourced from /home/analyst/.bashrc\n' >> /var/log/syslog

: > /var/log/nginx/access.log
for i in $(seq 1 120); do
  printf '10.0.2.2 - - [10/Apr/2026:10:%02d:12 +0000] "GET /index.html HTTP/1.1" 200 612\n' $((i % 60)) >> /var/log/nginx/access.log
 done
: > /var/log/nginx/error.log
for i in $(seq 1 20); do echo "2026/04/10 10:00:$i [notice] worker cycle complete" >> /var/log/nginx/error.log; done

# Ownership
chown -R analyst:analyst /home/analyst
chown -R hacker:hacker /home/hacker
chmod 644 /var/log/auth.log /var/log/syslog /var/log/nginx/access.log /var/log/nginx/error.log

# Friendly MOTD clue
cat > /etc/motd <<'EOF'
Incident response drill.
Separate noise from signal.
Document what matters.
EOF
