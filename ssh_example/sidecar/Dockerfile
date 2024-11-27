FROM docker.io/library/nginx:alpine

COPY ./default.conf /etc/nginx/conf.d
COPY sshd_config /etc/ssh/
COPY entrypoint.sh ./
# Start and enable SSH
RUN apk add openssh \
    && echo "root:Docker!" | chpasswd \
    && chmod +x ./entrypoint.sh \
    && cd /etc/ssh/ \
    && ssh-keygen -A

EXPOSE 9000 2223

ENTRYPOINT [ "./entrypoint.sh" ]
