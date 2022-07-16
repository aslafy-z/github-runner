#!/bin/bash

set -e

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"systemd.unified_cgroup_hierarchy=1 cgroup_enable=memory swapaccount=1 /g' /etc/default/grub

update-initramfs -u -k all
update-grub
