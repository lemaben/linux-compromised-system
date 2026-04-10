#!/bin/bash
set -e

# Primary user assumptions for Ubuntu backend
MAIN_USER=ubuntu
id -u "$MAIN_USER" >/dev/null 2>&1 || MAIN_USER=$(awk -F: '$3==1000{print $1; exit}' /etc/passwd)
[ -n "$MAIN_USER" ] || MAIN_USER=root
MAIN_HOME=$(eval echo ~$MAIN_USER)

# Suspicious user
id -u hacker >/dev/null 2>&1 || useradd -m hacker
mkdir -p /home/hacker

# Realistic clutter
mkdir -p "$MAIN_HOME"/Downloads "$MAIN_HOME"/Desktop "$MAIN_HOME"/scripts "$MAIN_HOME"/projects/demo-app /opt/tools /srv/app /var/backups /var/log/nginx /var/tmp
printf 'buy milk
call ISP
finish report
' > "$MAIN_HOME"/Desktop/todo.txt
printf 'old notes
TODO: rotate keys later
' > "$MAIN_HOME"/Downloads/notes-old.txt
cat > "$MAIN_HOME"/scripts/backup.sh <<'EOF'
#!/bin/bash
tar -czf /var/backups/home.tgz /home/ubuntu
EOF
cp "$MAIN_HOME"/scripts/backup.sh "$MAIN_HOME"/scripts/backup.sh.bak
chmod +x "$MAIN_HOME"/scripts/backup.sh "$MAIN_HOME"/scripts/backup.sh.bak
printf 'server started
healthcheck ok
' > /srv/app/app.log
printf '#!/bin/bash
echo cleaning temp files
' > /opt/tools/cleanup-helper.sh
chmod +x /opt/tools/cleanup-helper.sh
touch /tmp/install.log /tmp/update.cache /tmp/session.tmp /var/tmp/archive.tmp

# Malicious script + persistence
cat > /tmp/.miner.sh <<'EOF'
#!/bin/bash
while true; do sleep 1000; done
EOF
chmod +x /tmp/.miner.sh
if ! grep -q '/tmp/.miner.sh' "$MAIN_HOME/.bashrc" 2>/dev/null; then
  echo 'bash /tmp/.miner.sh' >> "$MAIN_HOME/.bashrc"
fi

# Clues
printf 'cleanup script runs from tmp...
' > /home/hacker/.note.txt
printf 'check shell startup files
' > /var/tmp/readme.txt

# Weak permissions
printf 'bank data
' > "$MAIN_HOME/finance.txt"
chmod 777 "$MAIN_HOME/finance.txt"

# Fake suspicious process
cp /bin/sleep /tmp/crypto_miner
pkill -f '/tmp/crypto_miner 1000' >/dev/null 2>&1 || true
nohup /tmp/crypto_miner 1000 >/dev/null 2>&1 &

# Bash history
cat > "$MAIN_HOME/.bash_history" <<'EOF'
ls
cd /tmp
cat /var/tmp/readme.txt
ps aux | grep miner
nano ~/.bashrc
EOF

# Logs with noise + one clue
mkdir -p /var/log
cat > /var/log/auth.log <<'EOF'
Apr 10 08:12:11 lab sshd[1001]: Accepted password for ubuntu from 10.0.2.2 port 55220 ssh2
Apr 10 08:14:02 lab sudo:   ubuntu : TTY=pts/0 ; PWD=/home/ubuntu ; USER=root ; COMMAND=/usr/bin/apt update
Apr 10 08:20:31 lab sshd[1099]: Failed password for invalid user admin from 185.22.44.10 port 44012 ssh2
Apr 10 08:21:01 lab sshd[1102]: Failed password for invalid user test from 185.22.44.10 port 44018 ssh2
Apr 10 08:24:55 lab useradd[1200]: new user: name=hacker, UID=1001, GID=1001, home=/home/hacker, shell=/bin/sh
EOF
for i in $(seq 1 180); do echo "Apr 10 09:${i}:00 lab systemd[1]: Started harmless-service-${i}." >> /var/log/syslog; done
for i in $(seq 1 120); do echo "10.0.0.$i - - [10/Apr/2026:09:10:$i +0000] "GET /health HTTP/1.1" 200 12 "-" "curl/8.5"" >> /var/log/nginx/access.log; done
cat >> /var/log/nginx/error.log <<'EOF'
2026/04/10 09:22:01 [warn] 1001#1001: harmless warning example
2026/04/10 09:22:05 [error] 1001#1001: open() "/tmp/.miner.sh" failed (2: No such file or directory)
EOF

# Red herrings
mkdir -p "$MAIN_HOME"/.cache "$MAIN_HOME"/projects/demo-app/logs
printf 'temporary cache
' > "$MAIN_HOME"/.cache/session.db
printf '# suspicious name, harmless content
echo backup complete
' > "$MAIN_HOME"/projects/demo-app/logs/hack-report.txt
printf 'old test account notes
' > /var/backups/admin-old.txt

chown -R "$MAIN_USER":"$MAIN_USER" "$MAIN_HOME"
chown -R hacker:hacker /home/hacker
