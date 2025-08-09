# pxe_server

This role uses a debian based machine such as a raspberry pi as a pxe boot server for my cluster. It handles setting up the file structure for the pxe server and running the dhcp, tftp, and http servers, as well as preparing and preseeding the debian pxe boot machines.

TL:DR -> Makes pi into pxe server and makes debian preseed files for cluster.

#### TFTP file structure:

This role creates this directory structure by first moving config and associated boot files into a working directory on the pxe server, and then mounting them in a specific manner in the docker compose into the dnsmasq tftp root directory.

docker-compose file mappings `dnsmasq` container

```
Local File Tree                           Container File Tree
.                                         .
├── configs                               ├── /etc
│   └─── dnsmasq.conf           ------>   │   └── dnsmasq.conf
│                                         └── /tftp
└── debian-installer            ------>        ├── [contents of ./debian-installer]
    └── amd64                                  |
        ├── linux               ------>        ├── linux
        ├── initrd.gz           ------>        ├── initrd.gz
        └── grubx64.efi         ------>        └── grubx64.efi

```

These are the files that the booting machine requests via tftp during boot with my configs:

```
grubx64.efi
debian-installer/amd64/grub/x86_64-efi/command.lst
debian-installer/amd64/grub/x86_64-efi/fs.lst
debian-installer/amd64/grub/x86_64-efi/crypto.lst
debian-installer/amd64/grub/x86_64-efi/terminal.lst
debian-installer/amd64/grub/grub.cfg
linux
initrd.gz
```

It first pulls `grubx64.efi` because of this line in my dnsmasq config: `dhcp-boot=tag:efi-x86_64,grubx64.efi` which includes the path to look for.

The `preseed.cfg` file is served by http in the nginx container

## Requirements

Docker needs to be installed on the pxe server first. `geerlingguy.docker` is a convenient choice.

This role only sets up the services and files. It requires something else to wake the machines.

The inventory also needs to be set up correctly. It creates the required files to install debian on each of the machines listed under cluster in the inventory.

## Role Variables

In defaults:

- `pi_pxe_server_tar`: The tar.gz of a debian netboot image specifically. This is different than a netinstall image.
- `pi_pxe_server_tar_checksum`: The checksum for the netboot image
- `pi_pxe_server_working_dir`: The working directory on the pxe server. The actual dnsmasq, tftp etc run in containers and need to start from somewhere.

Required already present variables:

- `ssh_public_key`: The ssh key to add to allowed keys as a string
- `user_password_hash`: Password hash for the created user as a string

## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- name: Start pxe server
  hosts: pi0
  become: true
  gather_facts: true
  roles:
    - pi_pxe_server
```

### ProxyDHCP mode (coexist with an existing router DHCP)

If your router already provides DHCP and cannot be disabled, set `pi_pxe_proxy_dhcp: true` to make `dnsmasq` run in ProxyDHCP mode. In this mode, your router assigns IP addresses and this role only advertises PXE boot options (next-server and boot filename).

Variables:

- `pi_pxe_proxy_dhcp`: Enable ProxyDHCP. Default `false`.
- `pi_pxe_next_server_ip`: Optional. IP address to advertise as the TFTP/HTTP server. Defaults to the host's primary IPv4 address.

Notes:

- Ensure UDP 67/68 (DHCP) and 4011 (PXE) are reachable between clients and this server. With Docker `network_mode: host` this is already handled.
- Some BIOS/UEFI firmwares look for `next-server` and filename. This role sets `next-server` to `pi_pxe_next_server_ip` and filename to `grubx64.efi` for x86_64 UEFI clients.
