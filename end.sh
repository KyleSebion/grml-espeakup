#!/bin/bash
sshpass -p live ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@10.10.10.2 poweroff
while virsh list | grep vm1; do sleep 1; done
virsh undefine --nvram vm1
rm espeakup.iso
