Debian Base Provision
=========

TODO:
  [] Non free firmware check


Runs on debian machines after they are created but before other roles.
Helps ensure that everything is prepared for further provisioning.

Based on:
  - [completing-installed-system](https://www.debian.org/releases/bullseye/amd64/ch06s04.en.html#completing-installed-system)



Requirements
------------

Must be run with becomes to run as root

Role Variables
--------------

...
Dependencies
------------

...
Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- name: Post install base provisioning
  hosts: cluster
  become: true
  roles:
    - base_debian_provision
```
License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
