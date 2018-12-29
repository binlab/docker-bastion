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

![AWS Bastion](https://dmhnzl5mp9mj6.cloudfront.net/security_awsblog/images/NM_diagram_061316_a.png)

## Useful cases

[Bastion](https://hub.docker.com/r/binlab/bastion) is an isolated
`Docker` image that can work as a link between `Public` and `Private`
network. It can be also useful for reverse `SSH` tunneling for a host
behind a `NAT`. This image based on `Alpine Linux` last version.

## Usage

###  Run Bastion and `expose` port `22222` to outside a host machine

The container assumes your `authorized_keys` file with `644` permissions and mounted under `/var/lib/bastion/authorized_keys`.

Docker example:

```shell
$ docker volume create bastion
$ docker run -d \
    --name bastion \
    --hostname bastion \
    --restart unless-stopped \
    -v ./bastion_keys:/var/lib/bastion/authorized_keys:ro \
    -v bastion:/etc/ssh:rw
    --add-host dockerhost:172.17.0.1
    -p 22222:22/tcp \
    binlab/bastion
```

Docker-compose example:

```yaml
version: '3.3'
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
    volumes:
      - ./bastion_keys:/var/lib/bastion/authorized_keys:ro
      - bastion:/etc/ssh:rw
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

* Add `rsa` public key to `bastion_keys` file

```shell
$ cat $HOME/.ssh/id_rsa.pub > ./bastion_keys
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

### 2. Connect to `Host` through `Bastion`. 

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

### 3. Connect to another container with `SSH` through `Bastion`. 

---

```shell
$ ssh -A -J bastion@127.0.0.1:22222 bastion@docker-ssh
```
