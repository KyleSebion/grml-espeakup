#!/bin/bash -e
# .iso files that have been tested:
ISO=grml64-full_2024.02.iso      # wget https://download.grml.org/grml64-full_2024.02.iso
ISO=grml64-small_2024.02.iso     # wget https://download.grml.org/grml64-small_2024.02.iso
ISO=grml-full-2024.12-amd64.iso  # wget https://download.grml.org/grml-full-2024.12-amd64.iso
ISO=grml-small-2024.12-amd64.iso # wget https://download.grml.org/grml-small-2024.12-amd64.iso

test -n "$1" && ISO=$1
if test ! -r "$ISO"; then echo "'$ISO' is not readable or doesn't exist"; exit 1; fi

apt -y install xorriso arch-install-scripts squashfs-tools

xorriso -osirrox on -indev "$ISO" -extract / isofiles
test -n "$grml2espeak_test" && sed -i -re '/linux/s/$/ssh=live console=ttyS0/' -e '1i\set timeout=1' isofiles/boot/grub/grml*_default.cfg

mkdir isofiles/scripts
cat << 'EOF' > isofiles/scripts/grml.sh
#!/bin/bash

case $(dmidecode -t 1) in
  *'IdeaPad Gaming 3 15ACH6'*);&
  *'some other model xxxxxx'*)
    printf 'defaults.%s.card 1\n' pcm ctl > /etc/asound.conf
  ;;
esac

if grep -Pq 'grml-(small|full)-amd64 2024.12' /etc/issue; then
  cat << '  SND' | sed -re 's/^ +//' > /etc/modprobe.d/snd-hd-intel.conf
    options snd-hda-intel single_cmd=1
    options snd-hda-intel probe_mask=1
    options snd-hda-intel model=basic
  SND
  modprobe -r snd_hda_intel
  modprobe    snd_hda_intel
fi

self_dir=$(dirname "$0")
cp -a "$self_dir/apt_cache/." /var/cache/apt
cp -a "$self_dir/apt_state/." /var/\lib\/apt
apt-get install -y espeakup alsa-utils
systemctl enable --now espeakup
systemd-run -u deferred --no-block -p After=grml-boot.target bash -c 'amixer set Master 100% unmute; amixer set Speaker 100% unmute'
EOF
chmod +x isofiles/scripts/grml.sh

unsquashfs -d sqfs isofiles/live/grml*/grml*.squashfs
mount -B sqfs sqfs
arch-chroot sqfs /bin/bash -c 'apt-get update; apt-get install -yd espeakup alsa-utils'
cp -a sqfs/var/cache/apt/. isofiles/scripts/apt_cache
cp -a sqfs/var/\lib\/apt/. isofiles/scripts/apt_state
umount sqfs

head -c 432 "$ISO" > isohdpfx.bin
xorriso -as mkisofs -V GRMLCFG -publisher 'grml-live | grml.org' -l -r -J -no-emul-boot -boot-load-size 4 \
  -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
  -boot-info-table -eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-mbr isohdpfx.bin \
  -eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat -no-pad -o espeakup.iso isofiles

rm -r isohdpfx.bin sqfs isofiles &> /dev/null
