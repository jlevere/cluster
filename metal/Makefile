export ANSIBLE_HOST_KEY_CHECKING=False
.POSIX:

all: help

SSH_KEY := ./keys/cluster_key
PASS_FILE := ./keys/pass
CRYPT_PASS := ./keys/cryptpass

help:
	@echo "Available targets:"
	@echo "pxe_server:      Run Ansible playbook for PXE server configuration"
	@echo "base_prov:       Run Ansible playbook for base Debian provisioning"
	@echo "install_k3s:     Run Ansible playbook for installing K3s"
	@echo "install_proxmox: Run Ansible playbook for installing Proxmox VE"
	@echo "ping:            Ping all hosts in the cluster"
	@echo "shutdown:        Shutdown machines using Ansible playbook"

gen_ssh_keys:
	@if [ ! -f "$(SSH_KEY)" ]; then \
		ssh-keygen -t ed25519 -P '' -f "$(SSH_KEY)"; \
	else \
		echo "SSH key already exists. Skipping generation."; \
	fi

gen_user_pass:
	@if [ ! -f "$(PASS_FILE)" ]; then \
		openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 16 > $(PASS_FILE); \
	else \
		echo "User password already exists. Skipping generation."; \
	fi

crypt_pass: gen_user_pass
	cat $(PASS_FILE) | mkpasswd --method=bcrypt-a -R 12 -s > $(CRYPT_PASS)

pxe_server: gen_ssh_keys crypt_pass
	ansible-playbook \
		--inventory inventories/cluster.yaml \
		pxe_server.yaml -vvv

base_prov:
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			base_debian.yaml -v

install_k3s:
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			base_k3s.yaml -vv

kubevirt:
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			kubevirt.yaml

start_vm:
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			start_vm.yaml -vvv

install_proxmox:
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			install_proxmox.yaml

ping:
	ansible cluster -m ping \
		--inventory inventories/cluster.yaml

shutdown:
	@echo -n "Shutdown machines? [y/N] " && read ans && [ $${ans:-N} = y ]
	ansible-playbook \
		--inventory inventories/cluster.yaml \
			shutdown.yaml -vvv
