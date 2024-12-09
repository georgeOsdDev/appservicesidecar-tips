#!/bin/sh
set -e

cat >/etc/motd <<EOL
_________________

Main container
_________________

EOL
cat /etc/motd

CONTAINER_INFO_FROM_CGROUP=$(cat /proc/self/cgroup | head -1| rev | cut -d "/" -f 1 | rev)
logevent() {
  echo $(date "+%Y-%m-%dT%H:%M:%S.%3N%z") "[EntryPoint.backend]  CONTAINER_INFO_FROM_CGROUP:${CONTAINER_INFO_FROM_CGROUP}, Message: $1"
}

handler15() {
  logevent "'SIGTERM received"
}
trap handler15 15 # SIGTERM

logevent "log environment vars with printenv"
printenv
# Get environment variables to show up in SSH session
# This will replace any \ (backslash), " (double quote), $ (dollar sign) and ` (back quote) symbol by its escaped character to not allow any bash substitution.
(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/\\/\\\\/g' | sed 's/"/\\\"/g' | sed 's/\$/\\\$/g' | sed 's/`/\\`/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

logevent "Starting sshd" "START"
/usr/sbin/sshd

# Wait dapr sidecar is up, if not wait for 5 seconds
logevent "Waiting for dapr container to be up..."
while ! nc -z localhost 3500; do
  logevent "Waiting for dapr container to be up... sleep 5 sec"
  sleep 5
done
logevent "dapr container is up"

logevent "Starting node process"
node /app/dist/index.js
