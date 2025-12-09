#!/bin/bash

CHROOT_DIR=./chroot

chroot_create(){

    mkdir -p ${CHROOT_DIR}/{home,bin,etc/dropbear,dev,tmp,lib,lib64}

    # add std lib
    cp /lib64/ld-linux-x86-64.so.2 "${CHROOT_DIR}/lib64/"

    # add: std dev
    mknod -m 666 ${CHROOT_DIR}/dev/null c 1 3
    mknod -m 666 ${CHROOT_DIR}/dev/tty c 5 0
    mknod -m 666 ${CHROOT_DIR}/dev/zero c 1 5
    mknod -m 666 ${CHROOT_DIR}/dev/random c 1 8

    chroot_file /usr/bin/busybox
    chroot_file dropbear
    chroot_file git
    chroot_file chpasswd

echo "creating: user"

cat > ${CHROOT_DIR}/etc/passwd << EOF
root:x:0:0:root:/root:/bin/sh
user:x:1000:1000:user:/:/bin/sh
EOF
}

chroot_file(){
  FILE=${1:-busybox}
  FILE_PATH=$(which ${FILE} 2>/dev/null)

  [ -z ${FILE_PATH} ] && return 1

  # FILE_DIR=$(dirname ${FILE_PATH})
  FILE_DIR=/bin
  
  [ -d "${CHROOT_DIR}/${FILE_DIR}" ] || mkdir -p "${CHROOT_DIR}/${FILE_DIR}"
  cp -n "${FILE_PATH}" "${CHROOT_DIR}/${FILE_DIR}"

  ldd ${FILE_PATH} | awk '/lib/{print $3}' | \
    while read file
    do
      [ -z $file ] && continue
      echo "copy lib: $file"
      mkdir -p "${CHROOT_DIR}/$(dirname $file)"
      cp -n $file "${CHROOT_DIR}/$file"
    done
}

chroot_mount(){
    # mount -t devtmpfs udev ${CHROOT_DIR}/dev
    # mkdir ${CHROOT_DIR}/dev/pts
    mount -t devpts devpts ${CHROOT_DIR}/dev/pts
}

chroot_unmount(){
  umount ${CHROOT_DIR}/dev/pts
  # umount ${CHROOT_DIR}/dev
}

chroot_sshd(){
echo "Starting dropbear inside chroot..."
(
        chroot ${CHROOT_DIR} /bin/busybox --install -s /bin
        echo "Changing password of user to foobar"
        echo "user:foobar" | chroot ${CHROOT_DIR} chpasswd
        chroot ${CHROOT_DIR} dropbear -F -E -B -R -g -m -p 5022
        echo "dropbear exited.. cleaning up!"
)
}

main(){
  chroot_mount
  chroot_sshd
  chroot_unmount
}
