# Bastion — jump host (gate) based on OpenSSH Server (sshd)

> A [bastion host](https://en.wikipedia.org/wiki/Bastion_host) is a
special purpose computer on a network specifically designed and
configured to withstand attacks. The computer generallyhosts a single
application, for example a proxy server, and all otherservices are
removed or limited to reduce the threat to the computer. It is hardened
in this manner primarily due to its location and purpose,which is
either on the outside of a firewall or in a demilitarized zone (`DMZ`)
and usually involves access from untrusted networks orcomputers. 

---

![AWS Bastion](docs/bastion_host.png)

## Useful cases

[Bastion](https://hub.docker.com/r/binlab/bastion) is an isolated
`Docker` image that can work as a link between `Public` and `Private`
network. It can be also useful for reverse `SSH` tunneling for a host
behind a `NAT`. This image based on `Alpine Linux` last version.

## Usage

###  Describing ENV variables

* `PUBKEY_AUTHENTICATION [true | false]` - Specifies whether public key authentication is allowed. The default is `true`. Note that this option applies to protocol version 2 only.

* `AUTHORIZED_KEYS [/relative/or/not/path/to/file]` - Specifies the file that contains the public keys that can be used for user authentication. `AUTHORIZED_KEYS` may contain tokens of the form `%T` which are substituted during connection setup. The following tokens are defined: `%%` is replaced by a literal `%`, `%h` is replaced by the home directory of the user being authenticated, and `%u` is replaced by the username of that user. After expansion, `AUTHORIZED_KEYS` is taken to be an absolute path or one relative to the user's home directory. The default file is `authorized_keys` and the default home directory is `/var/lib/bastion` and should be present by Docker volume mount by `-v $PWD/authorized_keys:/var/lib/bastion/authorized_keys:ro`.

* `TRUSTED_USER_CA_KEYS [/full/path/to/file]` - Specifies a file containing public keys of certificate authorities that are trusted to sign user certificates for authentication, or none to not use one. Keys are listed one per line; empty lines and comments starting with `#` are allowed. If a certificate is presented for authentication and has its signing CA key listed in this file, then it may be used for authentication for any user listed in the certificate's principals list. Note that certificates that lack a list of principals will not be permitted for authentication using `TRUSTED_USER_CA_KEYS`. Directive `AuthorizedPrincipalsFile` hardcoded to `/etc/ssh/auth_principals/%u` and in time of build and generated one principals file for presented user - `/etc/ssh/auth_principals/bastion` with the one row `bastion`, and this principal should be listed in the certificate's principals list.

* `GATEWAY_PORTS [true | false]` - Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, `sshd` binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. `GATEWAY_PORTS` can be used to specify that `sshd` should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect. The argument may be `false` to force remote port forwardings to be available to the local host only, `true` to force remote port forwardings to bind to the wildcard address. The default is `false`.

* `PERMIT_TUNNEL [true | false]` - Specifies whether `tun` device forwarding is allowed. The argument must be `true` or `false`. Specifying `true` permits both `point-to-point` (layer 3) and `ethernet` (layer 2). The default is `false`.

* `X11_FORWARDING [true | false]` - Specifies whether `X11` forwarding is permitted. The argument must be `true` or `false`. The default is `false`.

* `TCP_FORWARDING [true | false]` - Specifies whether `TCP` forwarding is permitted. The default is `true`. Note that disabling `TCP` forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.

* `AGENT_FORWARDING [true | false]` - Specifies whether `ssh-agent` forwarding is permitted. The default is `true`. Note that disabling agent forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.

* `LISTEN_ADDRESS [0.0.0.0]` - Specifies the local addresses should listen on. By default it **0.0.0.0**. Useful when Docker container runs in `Host mode`

* `LISTEN_PORT [22]` - Specifies the port number that listens on. The default is **22**. Useful when Docker container runs in `Host mode`

###  Run Bastion and `expose` port `22222` to outside a host machine

The container assumes your `authorized_keys` file with `644` permissions and mounted under `/var/lib/bastion/authorized_keys`.

Docker example:

```shell
$ docker volume create bastion
$ docker run -d \
    --name bastion \
    --hostname bastion \
    --restart unless-stopped \
    -v $PWD/authorized_keys:/var/lib/bastion/authorized_keys:ro \
    -v bastion:/usr/etc/ssh:rw \
    --add-host docker-host:172.17.0.1 \
    -p 22222:22/tcp \
    -e "PUBKEY_AUTHENTICATION=true" \
    -e "GATEWAY_PORTS=false" \
    -e "PERMIT_TUNNEL=false" \
    -e "X11_FORWARDING=false" \
    -e "TCP_FORWARDING=true" \
    -e "AGENT_FORWARDING=true" \
    binlab/bastion
```

Docker-compose example:

```yaml
version: "3.6"
services:
  bastion:
    image: binlab/bastion
    container_name: bastion
    hostname: bastion
    restart: unless-stopped
    expose:
      - 22/tcp
    ports:
      - 22222:22/tcp
    environment:
      PUBKEY_AUTHENTICATION: "true"
      GATEWAY_PORTS: "false"
      PERMIT_TUNNEL: "false"
      X11_FORWARDING: "false"
      TCP_FORWARDING: "true"
      AGENT_FORWARDING: "true"
    volumes:
      - $PWD/authorized_keys:/var/lib/bastion/authorized_keys:ro
      - bastion:/usr/etc/ssh:rw
    extra_hosts:
      - docker-host:172.17.0.1
    networks:
      - bastion

networks:
  bastion:
    driver: bridge
    
volumes:
  bastion:
```

_* When you are run `Bastion` container first time it generates `dsa`, `ecdsa`, `ed25519` and `rsa` key pair and saves them in permanent volume `bastion`, When you need to regenerate key pair, you should remove volume `bastion`._

### 1. Connect to  `Bastion`

---

* Add your user to group `docker` to have possibility run `docker-compose` and `docker` from your user without `sudo`. After you should re-login or open a new terminal window.

```shell
$ sudo usermod -aG docker <your_user>
```

* Create custom work dir e.g. `docker`, enter to it and clone repository

```shell
$ mkdir $HOME/docker 
$ cd $HOME/docker
$ git clone https://github.com/binlab/docker-bastion.git
$ cd docker-bastion
```

* Generate `rsa` pair (if you have one, skip this)

```shell
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f $HOME/.ssh/id_rsa
```

* Add `rsa` public key to `.bastion_keys` file

```shell
$ cat $HOME/.ssh/id_rsa.pub > $PWD/.bastion_keys
```

* Run [`docker-compose.yml`](docker-compose.yml) configuration - `bastion` & `docker-ssh`

```shell
$ docker-compose up
```

* And then you are can connect to it (in another terminal window)

```shell
$ ssh -i $HOME/.ssh/id_rsa -p 22222 bastion@127.0.0.1
```

* You should see like this:

```shell
user@localhost:~$ ssh -p 22222 bastion@127.0.0.1
The authenticity of host '[127.0.0.1]:22222 ([127.0.0.1]:22222)' can't be established.
ECDSA key fingerprint is 
SHA256:********************************************
ECDSA key fingerprint is MD5:**:**:**:**:**:**:**:**:**:**:**:**:**:**:**:**.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[127.0.0.1]:22222' (ECDSA) to the list of known hosts.
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

bastion:~$ 
```

### 2. Connect to `Host` through `Bastion`

---

To achieve this you should add your private key to `SSH` agent and turn on `ForwardAgent` in `~/.ssh/config` or from a command line via flag `-A`

> -A option enables forwarding of the authentication agent connection.
>
> It means that, it forwards your SSH auth schema to the remote host. > So you can use SSH over there as if you were on your local machine.

* Add private key to `SSH` agent

```shell
$ ssh-add $HOME/.ssh/id_rsa
```

* Test `Bastion` bridge in action

```shell
$ ssh -A -J bastion@127.0.0.1:22222 <your_user>@docker-host
```

### 3. Connect to another container with `SSH` through `Bastion`

---

```shell
$ ssh -A -J bastion@127.0.0.1:22222 bastion@docker-ssh
```
