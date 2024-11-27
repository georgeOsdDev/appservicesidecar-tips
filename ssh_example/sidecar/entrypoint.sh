#!/bin/sh
set -e

cat >/etc/motd <<EOL
_________________

Sidecar container
_________________

EOL
cat /etc/motd
# start sshd
/usr/sbin/sshd
# start nginx
nginx -g "daemon off;"
