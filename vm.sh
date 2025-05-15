#!/bin/bash -x
chown -R tss:tss /var/lib/swtpm-localca
grml_espeakup_test=1 ./mk.sh
virt-install --virt-type kvm --name vm1 --osinfo debian12 --memory 4096 --vcpus 2 --boot uefi,loader_secure=no --boot cdrom --nodisks --cdrom espeakup.iso --livecd --graphics vnc,listen=0.0.0.0,port=5901 --noautoconsole --network bridge=br0 --host-device pci_0000_06_00_6
expect -c 'set timeout -1; spawn -noecho -open [open '"$(virsh ttyconsole vm1)"' r+]; expect "@grml "; send -- "pkill dhcpcd; ip a add 10.10.10.2/24 dev eth0; ip r add default via 10.10.10.1; echo nameserver 1.1.1.1 >> /etc/resolvconf/resolv.conf.d/head; echo nameserver 8.8.8.8 >> /etc/resolvconf/resolv.conf.d/head; resolvconf -u; echo ksd\\one\n"; expect "ksdone"'
reset
echo sshpass -p live ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@10.10.10.2
