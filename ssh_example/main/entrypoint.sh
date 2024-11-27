#!/bin/sh
set -e

cat >/etc/motd <<EOL
_________________

main container
_________________

EOL
cat /etc/motd
# start sshd
/usr/sbin/sshd
# start nginx
nginx -g "daemon off;"
