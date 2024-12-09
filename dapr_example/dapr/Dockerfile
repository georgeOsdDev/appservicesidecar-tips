FROM alpine:latest
RUN apk add --no-cache wget bash
RUN wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash


# Install daprd
RUN dapr init --slim

COPY components/ /root/.dapr/components/
COPY sshd_config /etc/ssh/
COPY entrypoint.sh ./

# Start and enable SSH
RUN apk add openssh \
    && echo "root:Docker!" | chpasswd \
    && chmod +x ./entrypoint.sh \
    && cd /etc/ssh/ \
    && ssh-keygen -A

# 3500: Dapr HTTP port, 50001: Dapr gRPC port, 2223: SSH port, 9999: Dapr dashboard port
EXPOSE 3500 50001 2223

ENTRYPOINT [ "./entrypoint.sh" ]
