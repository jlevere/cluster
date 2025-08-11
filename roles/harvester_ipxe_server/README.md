## Harvester iPXE Server (Ansible Role)

This role provisions a self-contained network-boot server for installing a Harvester cluster via iPXE. It sets up a ProxyDHCP/TFTP service (dnsmasq) and an HTTP server (nginx) to deliver Harvester kernel/initrd/rootfs, per-host Harvester installation configs, and iPXE boot scripts. It supports both UEFI and BIOS clients, and orchestrates the first node in CREATE mode with subsequent nodes in JOIN mode.

References:

- PXE install flow and required kernel params: [Harvester PXE Boot Installation](https://docs.harvesterhci.io/v1.5/install/pxe-boot-install)
- Harvester config schema and options: [Harvester Configuration](https://docs.harvesterhci.io/v1.5/install/harvester-configuration)

### What this role does

- Runs dnsmasq in ProxyDHCP mode (coexists with your existing DHCP server) and TFTP for the initial NBP fetch
- Serves Harvester artifacts over HTTP: kernel, initrd, rootfs squashfs, ISO, iPXE scripts, and per-host Harvester config YAMLs
- Detects client firmware (BIOS vs UEFI) and delivers the appropriate iPXE NBP
- After iPXE is running, chains to HTTP-hosted scripts that pass correct kernel parameters and a per-host `config_url`
- Generates CREATE config for the first N hosts and JOIN configs for the rest
- Downloads artifacts for the configured Harvester version from the official releases
- Manages services with Docker Compose using host networking

### Supported boot flows

- UEFI x86_64
  - NBP via TFTP: `ipxe.efi`
  - DHCP user-class check prevents iPXE→iPXE loops
  - iPXE loads kernel/initrd via HTTP and boots Harvester live rootfs
- BIOS/CSM
  - NBP via TFTP: `undionly.kpxe`
  - iPXE then proceeds as above

Minimal PXE prompt/menu is enabled by default to avoid PXE-E74 on some Intel ROMs. You can disable it via variables (see below).

### Directory layout (on target host)

- `{{ harvester_ipxe_server_working_dir }}/`
  - `configs/dnsmasq.conf` (templated)
  - `tftp/` (NBPs): `ipxe.efi`, `undionly.kpxe`, `autoexec.ipxe`
  - `http/` (HTTP root):
    - Artifacts: `harvester-<version>-vmlinuz-amd64`, `harvester-<version>-initrd-amd64`, `harvester-<version>-rootfs-amd64.squashfs`, `harvester-<version>-amd64.iso`
    - iPXE scripts: `ipxe-create-efi`, `ipxe-join-efi`, `autoexec.ipxe`
    - Per-host configs: `config-create-<mac>.yaml`, `config-join-<mac>.yaml` where `<mac>` is colon-separated lower-case MAC (e.g., `18:60:24:...`)
  - `docker-compose.yaml` (from role files)

### Role variables (defaults)

Networking and placement

- `harvester_ipxe_server_working_dir` (string): Install root, default `/opt/harvester-ipxe`
- `harvester_ipxe_server_proxy_dhcp` (bool): Use ProxyDHCP (recommended), default `true`
- `harvester_ipxe_server_listen_interface` (string): Interface dnsmasq binds to. Defaults to Ansible’s detected interface.

Harvester release and artifacts

- `harvester_ipxe_server_version` (string): Harvester version (e.g., `v1.5.0`)
- `harvester_ipxe_server_release_base_url` (string): Release base URL
- Derived filenames: `harvester_ipxe_server_kernel_name`, `..._initrd_name`, `..._rootfs_name`, `..._iso_name`

Cluster settings

- `harvester_ipxe_server_vip` (string): Cluster VIP
- `harvester_ipxe_server_vip_mode` (string): `static` or `dhcp`
- `harvester_ipxe_server_vip_hw_addr` (string): Required when `vip_mode: dhcp`
- `harvester_ipxe_server_token` (string): Cluster secret / node token

Installer options

- `harvester_ipxe_server_install_device` (string): Target OS disk (e.g., `/dev/sda`)
- Optional: `harvester_ipxe_server_install_data_disk`, `..._force_efi`, `..._force_mbr`, `..._silent`, `..._poweroff`, `..._no_format`, `..._debug`, `..._tty`, `..._role`, `..._persistent_partition_size`, `..._wipe_all_disks`, `..._wipe_disks_list`, `..._with_net_images`
- Optional overrides: `harvester_ipxe_server_cluster_pod_cidr`, `..._cluster_service_cidr`, `..._cluster_dns`
- Installer webhooks: `harvester_ipxe_server_install_webhooks` (list)

OS settings for Harvester config `os.*`

- `harvester_ipxe_server_password` (string): UI/OS password
- `harvester_ipxe_server_ssh_authorized_keys` (list)
- Optional: `harvester_ipxe_server_os_write_files` (list), `..._os_modules` (list), `..._os_sysctls` (dict), `..._os_environment` (dict), `..._os_labels` (dict)
- DNS/NTP: `harvester_ipxe_server_dns_nameservers` (list), `harvester_ipxe_server_ntp_servers` (list)

System settings (CREATE mode only)

- `harvester_ipxe_server_system_settings` (dict): Rendered as JSON strings, as required by Harvester

Management networking in Harvester config

- `harvester_ipxe_server_mgmt_interfaces` (list of interface names)
- `harvester_ipxe_server_mgmt_interfaces_def` (list of dicts `{name, hwAddr}`)
- Bonding: `harvester_ipxe_server_bond_options: { mode, miimon }`

CREATE/JOIN selection

- `harvester_ipxe_server_create_hosts_count` (int): First N hosts (by sorted group) get CREATE configs; remainder get JOIN

PXE/iPXE binaries and menu

- `harvester_ipxe_server_ipxe_efi_binary` (default `ipxe.efi`)
- `harvester_ipxe_server_ipxe_bios_binary` (default `undionly.kpxe`)
- Prompt/menu: `harvester_ipxe_server_pxe_menu_enabled` (bool), `harvester_ipxe_server_pxe_prompt_text`, `harvester_ipxe_server_pxe_prompt_timeout`, `harvester_ipxe_server_pxe_localboot_entry`
- Serial console (kernel param in iPXE): `harvester_ipxe_server_serial_console` (e.g., `ttyS1,115200n8`)
- Skip installer hardware checks (kernel param): `harvester_ipxe_server_skip_checks` (bool)

### Inventory expectations

- Group your target hosts in `group: cluster`
- Each host should have a `mac` hostvar for per-MAC config naming and dnsmasq tagging

Example inventory snippet:

```yaml
all:
  children:
    cluster:
      hosts:
        node1:
          mac: "18:60:24:88:21:44"
          ansible_host: 192.168.1.101
        node2:
          mac: "40:b0:34:43:a8:b3"
          ansible_host: 192.168.1.102
        node3:
          mac: "54:bf:64:76:26:7e"
          ansible_host: 192.168.1.103
```

### Example playbook

```yaml
- hosts: harvester_ipxe_server
  become: true
  roles:
    - role: harvester_ipxe_server
```

### How it decides CREATE vs JOIN

The role collects `groups['cluster']`, sorts hosts, and uses `harvester_ipxe_server_create_hosts_count` to mark the first N as CREATE. It templates per-host configs named `config-create-<mac>.yaml` or `config-join-<mac>.yaml` and serves them over HTTP. iPXE scripts pass `harvester.install.config_url=http://<server>/<file>` to Harvester.

### iPXE scripts and kernel params

- `ipxe-create-efi`, `ipxe-join-efi`:
  - Always provide `initrd=<initrd-name>` to satisfy UEFI
  - Robust network bring-up: `ip=dhcp rd.neednet=1 rd.net.dhcp.retry=20 net.ifnames=1`
  - Live rootfs over HTTP: `root=live:http://<server>/<rootfs.squashfs>`
  - Harvester flags: `harvester.install.automatic=true`, `harvester.install.mode=<create|join>`, `harvester.install.config_url=<url>`
  - Optional: `harvester.install.skipchecks=true` when enabled by variable

### dnsmasq behavior

- ProxyDHCP responder on the bind interface
- Arch detection via DHCP option 93: BIOS (0) vs UEFI x64 (7/9/11)
- Avoids iPXE loops by checking DHCP user class `iPXE`
- BIOS chainload: `undionly.kpxe`; UEFI chainload: `ipxe.efi`
- After iPXE, `dhcp-boot` sends the HTTP iPXE scripts for CREATE/JOIN
- Optional PXE prompt and local boot entries (Intel PXE-E74 workaround)

### Ports and network requirements

- DHCP server (existing): UDP 67/68 to clients
- ProxyDHCP (dnsmasq): UDP 4011 to clients
- TFTP (dnsmasq): UDP 69 to clients
- HTTP (nginx): TCP 80 to clients
- If using L3 relays/helpers, forward both DHCP and ProxyDHCP to this host

### Logs and troubleshooting

- dnsmasq (in container): forwarded to stdout; check with `docker logs` or system logs
- HTTP access log is visible via container logs; you should see, per boot:
  1. GET `/ipxe-*-efi` 2) GET initrd/kernel 3) GET rootfs.squashfs 4) GET `config-*.yaml` 5) GET ISO
- Common issues:
  - PXE-E74 on Intel ROMs: keep PXE prompt/menu enabled; if persistent, try using only `dhcp-boot=...,<file>,,<server>` lines for the affected arch
  - No `rootfs.squashfs` request: add/keep `rd.neednet=1` and increase `rd.net.dhcp.retry`; verify VLANs/DHCP reachability
  - Config YAML rejected: check indentation; `ssh_authorized_keys` must be a list; verify rendered files under HTTP root
  - Firmware freezes on `ipxe.efi`: try `snponly.efi` instead by overriding the EFI binary variable

### Extending the role

- To add more Harvester config knobs, extend defaults and templates under `templates/config-*.yaml.j2`
- To customize kernel params, edit `templates/ipxe-*.j2`
- To adjust ProxyDHCP behavior, update `templates/dnsmasq.conf.j2`

### Collections/dependencies

- Requires Docker and the `community.docker` collection for `docker_compose_v2`
- The role installs the `docker-compose` CLI and `python3-docker` on the target

### Security notes

- The generated per-host Harvester configs contain credentials and tokens; keep the HTTP server on a trusted network
- Consider restricting access at the network layer to intended PXE subnets

### Version compatibility

- Defaults target Harvester `{{ harvester_ipxe_server_version }}`; update the variable when a new Harvester release is desired

### License

This role is provided as-is; use under your project’s license policy.
