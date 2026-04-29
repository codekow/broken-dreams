# Upgrade Devo M4R to Openwrt

- https://forum.openwrt.org/t/openwrt-support-for-tp-link-deco-m4r/68940/144

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

## Download files for tftp

1. Download [Exploit](https://github.com/naf419/tplink_deco_exploits/raw/refs/heads/main/uboot/deco_all_webfailsafe_faux_fw_tftp_v2.bin)
1. Set the IP address of the wired interface of your computer to "192.168.0.2" and directly connect said interface to one of the RJ45 ports of the Deco M4R.
1. Use a SIM tray tool or anything else thin like a paperclip to press down the reset button that is at the bottom of the M4R and keep it pressed. Now power on the M4R or power cycle it to hard-reboot it. Don't let go of the reset button until the LED turns off.
1. Open http://192.168.0.1 on your computer.
1. On that page choose the exploit file and then press "Upgrade". If you monitor your network traffic with task-manager you should see a blip from the exploit uploading and then a short burst of 2-3 seconds while the exploit pulls the initramfs file from the TFTP server. Meanwhile the webpage will tell you that the upgrade failed, but only because the M4R is now booting the initramfs firmware and isn't responding to the webpage anymore.
1. The M4R should now be blinking while the initramfs firmware is booting up.

```sh
curl https://downloads.openwrt.org/releases/24.10.6/targets/ath79/generic/openwrt-24.10.6-ath79-generic-tplink_deco-m4r-v1-initramfs-kernel.bin > /tmp/initramfs-kernel.bin
```
