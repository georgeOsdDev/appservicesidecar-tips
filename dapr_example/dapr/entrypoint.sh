#!/bin/sh
set -e

cat >/etc/motd <<EOL
_________________

Dapr container
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

logevent "Starting sshd"
/usr/sbin/sshd
logevent "Starting dapr process"

# APPID should come from environment variable, if it not set, use default value as "main"
APPID=${APPID:-main}
APPPORT=${APPPORT:-9000}
DAPR_LOGLEVEL=${DAPR_LOGLEVEL:-debug}

# nohup dapr dashboard -p 9999 &
/root/.dapr/bin/daprd --resources-path /root/.dapr/components/ --log-level ${DAPR_LOGLEVEL} --enable-api-logging --log-as-json --app-id ${APPID} --app-port ${APPPORT} #--enable-metrics --enable-app-health-check --app-health-check-path /.internal/healthz
