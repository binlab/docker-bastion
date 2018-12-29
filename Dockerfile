FROM alpine:3.8

LABEL maintainer="Mark <mark.binlab@gmail.com>"

ARG HOME=/var/lib/bastion

ARG USER=bastion
ARG GROUP=bastion
ARG UID=4096
ARG GID=4096

RUN addgroup -S -g ${GID} ${GROUP} \
    && adduser -D -h ${HOME} -s /bin/ash -g "${USER} service" \
           -u ${UID} -G ${GROUP} ${USER} \
    && sed -i "s/${USER}:!/${USER}:*/g" /etc/shadow \
    && set -x \
    && apk add --no-cache openssh-server

EXPOSE 22/tcp

VOLUME /etc/ssh

CMD /usr/bin/ssh-keygen -A \
    && /usr/sbin/sshd -D -e -4 \
        -o AuthorizedKeysFile=authorized_keys \
        -o PubkeyAuthentication=yes \
        -o PasswordAuthentication=no \
        -o PermitEmptyPasswords=no \
        -o PermitRootLogin=no \
        -o GatewayPorts=yes
