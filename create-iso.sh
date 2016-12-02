#!/bin/bash
if [ "$EUID" -ne 0 ]
 then echo "Please run as root"
 exit
fi

pushd `dirname $0` > /dev/null
BASE=$(pwd -P)
popd > /dev/null

ISO=/path/to/rhel-server-7.3-x86_64-boot.iso
OUT_ISO=${BASE}/rhel-7-rescue.iso

RHEL7RESCUE="${BASE}/build/rhel-7-rescue"
initrd="${BASE}/build/initrd"
mnt="${BASE}/build/mnt"

mkdir -p ${RHEL7RESCUE}
mkdir -p ${initrd}
mkdir -p ${mnt}

mount -t iso9660 -o ro ${ISO} ${mnt}

# copy files from boot-iso
shopt -s dotglob
cp -avRf ${mnt}/* ${RHEL7RESCUE}

#unmount dvd iso
umount ${mnt}

#replace isolinux.cfg 
cp -af ${BASE}/isolinux.cfg ${RHEL7RESCUE}/isolinux/isolinux.cfg

# extract initrd files
cd ${initrd}
xz -dc < ${RHEL7RESCUE}/isolinux/initrd.img | cpio --quiet -i --make-directories
cd -

# add coreutils to initrd
for file in $(rpm -ql coreutils); do mkdir -p ${initrd}$(dirname ${file}); cp -af $file ${initrd}${file}; done

# add xfs-check script to initrd
cp -a ${BASE}/scripts/* ${initrd}
# add systemd-unit file for running xfs-chk on startup
# replace dracut-emergency
cp -a ${BASE}/dracut-emergency ${initrd}/bin/dracut-emergency

# rebuild initrd
cd ${initrd}
find . 2>/dev/null | cpio --quiet -c -o | xz -9 --format=lzma >"${RHEL7RESCUE}/isolinux/initrd.img"
cd -

# create rescue-iso
cd ${rhel-7-rescue}
mkisofs -J -T -o ${OUT_ISO} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -graft-points -V "RHEL-7.3 x86_64" ${RHEL7RESCUE}
cd -

# cleanup
sudo rm -rf $BASE/build
