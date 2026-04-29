# Upgrade Devo M4R to Openwrt

- https://forum.openwrt.org/t/openwrt-support-for-tp-link-deco-m4r/68940/144

## Download files for tftp

1. Download [Exploit](https://github.com/naf419/tplink_deco_exploits/raw/refs/heads/main/uboot/deco_all_webfailsafe_faux_fw_tftp_v2.bin)
1. Set the IP address of the wired interface of your computer to "192.168.0.2" and directly connect said interface to one of the RJ45 ports of the Deco M4R.

## Run TFTP only dnsmasq

```sh
mkdir /tmp/tftp

cat << EOF > /tmp/dnsmasq.conf
# Disable DNS
port=0

# Bind Address
listen-address=192.168.0.2

# Enable the TFTP server
enable-tftp
tftp-root=/tmp/tftp
EOF

sudo dnsmasq -d -C /tmp/dnsmasq.conf
```

```sh
curl https://downloads.openwrt.org/releases/24.10.6/targets/ath79/generic/openwrt-24.10.6-ath79-generic-tplink_deco-m4r-v1-initramfs-kernel.bin > /tmp/tftp/initramfs-kernel.bin
```

1. Use a SIM tray tool or anything else thin like a paperclip to press down the reset button that is at the bottom of the M4R and keep it pressed. Now power on the M4R or power cycle it to hard-reboot it. Don't let go of the reset button until the LED turns off.
1. Open http://192.168.0.1 on your computer.
1. On that page choose the exploit file and then press `Upgrade`. If you monitor your network traffic with task-manager you should see a blip from the exploit uploading and then a short burst of 2-3 seconds while the exploit pulls the initramfs file from the TFTP server. Meanwhile the webpage will tell you that the upgrade failed, but only because the M4R is now booting the initramfs firmware and isn't responding to the webpage anymore.
1. The M4R should now be blinking while the initramfs firmware is booting up.

## Install OpenWrt Firmware

1. Set your wired network interface to "auto" or "dhcp" or whatever it's called and wait for it to automatically get assigned an IP from the M4R. You might have to pull and replug the network cable for that to work.
1. Go to http://192.168.1.1 and simply log in without any password.
1. On that status page go to `System->Backup/Flash Firmware` at the top.
1. Click on `Flash image...`, select the `sysupgrade` file and flash it.
1. Wait for the M4R to flash the `sysupgrade` and reboot and then you should have a Deco M4R with a working OpenWrt firmware flashed to it.
