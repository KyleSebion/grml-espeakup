#!/bin/bash -e
# .iso files that have been tested:
iso=grml64-full_2024.02.iso      # wget https://download.grml.org/grml64-full_2024.02.iso
iso=grml64-small_2024.02.iso     # wget https://download.grml.org/grml64-small_2024.02.iso
iso=grml-full-2024.12-amd64.iso  # wget https://download.grml.org/grml-full-2024.12-amd64.iso
iso=grml-small-2024.12-amd64.iso # wget https://download.grml.org/grml-small-2024.12-amd64.iso
iso=grml-full-2025.05-amd64.iso  # wget https://download.grml.org/grml-full-2025.05-amd64.iso
iso=grml-small-2025.05-amd64.iso # wget https://download.grml.org/grml-small-2025.05-amd64.iso

# handle arguments
test -n "$1" && iso=$1
if test ! -r "$iso"; then echo "'$iso' is not readable or doesn't exist"; exit 1; fi
case "$2" in
  ltlk) synth_type=ltlk;;
  *)    synth_type=espeakup;;
esac

apt -y install xorriso arch-install-scripts squashfs-tools # install dependencies
xorriso -osirrox on -indev "$iso" -extract / isofiles      # extract files from .iso
unsquashfs -d sqfs isofiles/live/grml*/grml*.squashfs      # extract root files system from file from .iso
mount -B sqfs sqfs                                         # bind mount to appease arch-chroot

# modifications for testing (enable ssh server and set ip)
test -n "$grml_espeakup_test" && sed -i -re '/boot=live/s/$/ ssh=live ip=10.10.10.2::10.10.10.1:255.255.255.0::::1.1.1.1:8.8.8.8: /' -e '1i\set timeout=1' isofiles/boot/grub/grml*_default.cfg

# create script that is automatically launched on grml startup
mkdir isofiles/scripts
echo '#!/bin/bash' > isofiles/scripts/grml.sh
chmod +x isofiles/scripts/grml.sh

# changes for espeakup
if test "$synth_type" = espeakup; then
  cat << '  EOF' | sed -re 's/^    //' >> isofiles/scripts/grml.sh
    # check for hardware that needs settings in asound.conf
    case $(dmidecode -t 1) in
      *'IdeaPad Gaming 3 15ACH6'*);&
      *'some other model xxxxxx'*)
        printf 'defaults.%s.card 1\n' pcm ctl > /etc/asound.conf
      ;;
    esac

    # add module args needed for grml amd64 2024.12 and reload module
    if grep -Pq 'grml-(small|full)-amd64 2024.12' /etc/issue; then
      cat << '  SND' | sed -re 's/^    //' > /etc/modprobe.d/snd-hd-intel.conf
        options snd-hda-intel single_cmd=1
        options snd-hda-intel probe_mask=1
        options snd-hda-intel model=basic
      SND
      modprobe -r snd_hda_intel
      modprobe    snd_hda_intel
    fi

    # restore apt files that were collected during chroot
    self_dir=$(dirname "$0")
    cp -a "$self_dir/apt_cache/." /var/cache/apt
    cp -a "$self_dir/apt_state/." /var/\lib\/apt

    # install/setup espeakup and volume
    apt-get install -y espeakup alsa-utils
    systemctl enable --now espeakup
    systemd-run -u deferred --no-block -p After=grml-boot.target bash -c 'amixer set Master 100% unmute; amixer set Speaker 100% unmute'
  EOF

  # collect apt files to be used in grml.sh during grml startup
  arch-chroot sqfs /bin/bash -c 'apt-get update; apt-get install -yd espeakup alsa-utils'
  cp -a sqfs/var/cache/apt/. isofiles/scripts/apt_cache
  cp -a sqfs/var/\lib\/apt/. isofiles/scripts/apt_state
fi

# changes for speakup_ltlk
if test "$synth_type" = ltlk; then
  # add speakup_ltlk module dependency to initramfs, generate new initramfs, then overwrite old initramfs with new
  arch-chroot sqfs /bin/bash -c 'echo speakup_ltlk >> /etc/initramfs-tools/modules; update-initramfs -u -k all'
  cp sqfs/boot/initrd.img* isofiles/boot/grml*/initrd.img
  #maybe unneeded: sed -i -re '/boot=live/s/$/ speakup_ltlk.start=1 /' isofiles/boot/grub/*.cfg isofiles/boot/isolinux/*.cfg
fi

head -c 432 "$iso" > isohdpfx.bin # extract isohdpfx.bin to use in new .iso; based on https://wiki.debian.org/RepackBootableISO

# create new .iso; based on "mkisofs_cmdline" in isofiles\conf\buildinfo.json
xorriso -as mkisofs -V GRMLCFG -publisher 'grml-live | grml.org' -l -r -J -no-emul-boot -boot-load-size 4 \
  -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
  -boot-info-table -eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-mbr isohdpfx.bin \
  -eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat -no-pad -o espeakup.iso isofiles

# cleanup
umount sqfs
rm -r isohdpfx.bin sqfs isofiles
