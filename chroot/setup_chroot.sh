#!/bin/sh

CHROOT_DIR=./chroot

chroot_file(){
  FILE=${1:-bash}
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

chroot_create(){

    mkdir -p ${CHROOT_DIR}/{home,bin,etc,dev,tmp,lib,lib64}

    # add std lib
    cp /lib64/ld-linux-x86-64.so.2 "${CHROOT_DIR}/lib64/"

    # add: std dev
    mknod -m 666 ${CHROOT_DIR}/dev/null c 1 3
    mknod -m 666 ${CHROOT_DIR}/dev/tty c 5 0
    mknod -m 666 ${CHROOT_DIR}/dev/zero c 1 5
    mknod -m 666 ${CHROOT_DIR}/dev/random c 1 8

    chroot_file /usr/bin/busybox
    chroot_file git
    
    chroot ${CHROOT_DIR} /bin/busybox --install -s /bin
    cp /etc/{passwd,group} ${CHROOT_DIR}/etc/

    mkdir -p ${CHROOT_DIR}/usr/lib/openssh/
    cp /usr/lib/openssh/sftp-server ${CHROOT_DIR}/usr/lib/openssh/

}

chroot_users(){
  SSH_GROUP=chroot
  awk -F':' '/'$SSH_GROUP'/{print $4}' /etc/group
}
