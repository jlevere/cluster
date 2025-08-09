## install_proxmox

Installs Proxmox VE on Debian hosts, prepares SSH keys across nodes, and optionally forms a Proxmox cluster.

### Requirements

- Debian Bookworm hosts with network access to `download.proxmox.com`.
- SSH access with privilege escalation.

### What it does

- Adds Proxmox APT repository and GPG key
- Installs Proxmox kernel, reboots, installs core packages
- Removes Debian kernel and `os-prober`
- Ensures `/etc/hosts` contains the host's management IP and hostname
- Distributes SSH keys across nodes and populates `known_hosts`
- (Optional) Creates/joins a Proxmox cluster via `cluster_create.yml`

### Variables

- `config_proxmox_cluster_name`: Name of the cluster to create (used by `cluster_create.yml`).

### Example Play

```yaml
- name: Install Proxmox
  hosts: kube
  become: true
  roles:
    - install_proxmox
```

### Notes

- The role tags tasks with `hosts`, `proxmox`, and `ssh` for selective runs.
