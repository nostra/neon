FROM alpine:3.19.0
MAINTAINER erlend <nossum@gmail.com>

RUN apk add --no-cache \
  bash \
  openssh \
  openssh-sftp-server \
  gettext \
  linux-pam \
  mosh \
  git \
  curl

RUN addgroup fluxpres \
  && adduser -D -G fluxpres -s /bin/bash -h /home/fluxpres fluxpres \
  && sed -i 's|fluxpres:!:|fluxpres:*:|g' /etc/shadow
COPY fluxpres.pub /home/fluxpres/.ssh/authorized_keys
RUN chown -R fluxpres:users /home/fluxpres/

RUN ssh-keygen -A \
    && mkdir /var/run/sshd \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config \
    && echo "AllowGroups fluxpres" >> /etc/ssh/sshd_config \
    && echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config \
    && echo "X11Forwarding yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" \
    && echo "PermitTunnel yes" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

EXPOSE 22 2220
ENTRYPOINT ["/usr/sbin/sshd","-D","-e","-p","2220"]
CMD []

# Build with version, to make kind more happy:
# docker build -t flux_sshd:v1 .
# kind load docker-image flux_sshd:v1
