#!/usr/bin/env sh

HOST_KEYS_PATH_PREFIX="${HOST_KEYS_PATH_PREFIX:='/'}"
HOST_KEYS_PATH="${HOST_KEYS_PATH:='/etc/ssh'}"

if [ "$PUBKEY_AUTHENTICATION" == "false" ]; then
    CONFIG_PUBKEY_AUTHENTICATION="-o PubkeyAuthentication=no"
else
    CONFIG_PUBKEY_AUTHENTICATION="-o PubkeyAuthentication=yes"
fi

if [ -n "$AUTHORIZED_KEYS" ]; then
    CONFIG_AUTHORIZED_KEYS="-o AuthorizedKeysFile=$AUTHORIZED_KEYS"
else
    CONFIG_AUTHORIZED_KEYS="-o AuthorizedKeysFile=authorized_keys"
fi

if [ -n "$TRUSTED_USER_CA_KEYS" ]; then
    CONFIG_TRUSTED_USER_CA_KEYS="-o TrustedUserCAKeys=$TRUSTED_USER_CA_KEYS"
    CONFIG_AUTHORIZED_PRINCIPALS_FILE="-o AuthorizedPrincipalsFile=/etc/ssh/auth_principals/%u"
fi

if [ "$GATEWAY_PORTS" == "true" ]; then
    CONFIG_GATEWAY_PORTS="-o GatewayPorts=yes"
else
    CONFIG_GATEWAY_PORTS="-o GatewayPorts=no"
fi

if [ "$PERMIT_TUNNEL" == "true" ]; then
    CONFIG_PERMIT_TUNNEL="-o PermitTunnel=yes"
else
    CONFIG_PERMIT_TUNNEL="-o PermitTunnel=no"
fi

if [ "$X11_FORWARDING" == "true" ]; then
    CONFIG_X11_FORWARDING="-o X11Forwarding=yes"
else
    CONFIG_X11_FORWARDING="-o X11Forwarding=no"
fi

if [ "$TCP_FORWARDING" == "false" ]; then
    CONFIG_TCP_FORWARDING="-o AllowTcpForwarding=no"
else
    CONFIG_TCP_FORWARDING="-o AllowTcpForwarding=yes"
fi

if [ "$AGENT_FORWARDING" == "false" ]; then
    CONFIG_AGENT_FORWARDING="-o AllowAgentForwarding=no"
else
    CONFIG_AGENT_FORWARDING="-o AllowAgentForwarding=yes"
fi

if [ ! -f "$HOST_KEYS_PATH/ssh_host_rsa_key" ]; then
    /usr/bin/ssh-keygen -A -f "$HOST_KEYS_PATH_PREFIX"
fi

if [ -n "$LISTEN_ADDRESS" ]; then
    CONFIG_LISTEN_ADDRESS="-o ListenAddress=$LISTEN_ADDRESS"
else
    CONFIG_LISTEN_ADDRESS="-o ListenAddress=0.0.0.0"
fi

if [ -n "$LISTEN_PORT" ]; then
    CONFIG_LISTEN_PORT="-o Port=$LISTEN_PORT"
else
    CONFIG_LISTEN_PORT="-o Port=22"
fi

/usr/sbin/sshd -D -e -4 \
    -o "HostKey=$HOST_KEYS_PATH/ssh_host_rsa_key" \
    -o "HostKey=$HOST_KEYS_PATH/ssh_host_dsa_key" \
    -o "HostKey=$HOST_KEYS_PATH/ssh_host_ecdsa_key" \
    -o "HostKey=$HOST_KEYS_PATH/ssh_host_ed25519_key" \
    -o "PasswordAuthentication=no" \
    -o "PermitEmptyPasswords=no" \
    -o "PermitRootLogin=no" \
    $CONFIG_PUBKEY_AUTHENTICATION \
    $CONFIG_AUTHORIZED_KEYS \
    $CONFIG_GATEWAY_PORTS \
    $CONFIG_PERMIT_TUNNEL \
    $CONFIG_X11_FORWARDING \
    $CONFIG_AGENT_FORWARDING \
    $CONFIG_TCP_FORWARDING \
    $CONFIG_TRUSTED_USER_CA_KEYS \
    $CONFIG_AUTHORIZED_PRINCIPALS_FILE \
    $CONFIG_LISTEN_ADDRESS \
    $CONFIG_LISTEN_PORT
