#!/bin/bash
chown -R tss:tss /var/lib/swtpm-localca
grml_espeakup_test=1 ./mk.sh "$1" "$2"
virt-install --virt-type kvm --name vm1 --osinfo debian12 --memory 4096 --vcpus 2 --boot uefi,loader_secure=no --boot cdrom --nodisks --cdrom espeakup.iso --livecd --graphics vnc,listen=0.0.0.0,port=5901 --noautoconsole --network bridge=br0 --host-device pci_0000_06_00_6 --serial file,path=/a/grml-espeakup/ser.bin
until nc -zvw5 10.10.10.2 22; do sleep 1; done; sshpass -p live ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@10.10.10.2
